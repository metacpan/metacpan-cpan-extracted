package DBIx::QuickORM::Row::Async;
use strict;
use warnings;

our $VERSION = '0.000021';

use Carp();
use Scalar::Util();

use overload (
    'bool' => sub { $_[0]->{invalid} ? 0 : 1 },
);

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Row::Async - Placeholder that swaps itself for a real row once async results arrive.

=head1 DESCRIPTION

A transparent proxy returned for an asynchronous single-row query. It holds an
async statement handle and, once results are ready, materializes the real row
and swaps itself out in place via the C<$_[0]> alias, so callers transparently
end up holding the real row object. Until then it forwards method calls,
C<isa>, C<can>, and C<DOES> to the eventual row's class. If the query returns
no data or is cancelled the proxy becomes invalid: boolean context is false
and method calls croak.

Construction requires an C<async> handle implementing
L<DBIx::QuickORM::Role::Async>. Optional C<auto_refresh> refreshes the row once
materialized; C<state_method> (default C<state_select_row>) and C<state_args>
control how the connection builds the row.

=head1 SYNOPSIS

    my $row = $async_row;       # placeholder, true while pending/valid
    print $row->column;         # swaps in the real row, then forwards

=head1 PUBLIC METHODS

=over 4

=item $bool = $row->isa($class)

True if the eventual row would satisfy the C<isa> check; swaps the proxy out
once results are ready.

=cut

sub isa {
    my ($this, $check) = @_;

    return 1 if $check eq __PACKAGE__;
    return 1 if $check eq 'DBIx::QuickORM::Row';
    return 1 if DBIx::QuickORM::Row->isa($check);

    if (my $class = Scalar::Util::blessed($this)) {

        if ($this->ready) {
            my $a = $_[0];
            $_[0] = $this->swapout;
            return $_[0]->isa($check) unless Scalar::Util::refaddr($a) eq Scalar::Util::refaddr($_[0]);
        }

        return 1 if $check eq $class;
        return 1 if $check eq $this->{row_class};
        return 1 if $this->{row_class}->isa($check);
    }

    return 0;
}

=pod

=item $code = $row->can($method)

Forward C<can> to the eventual row's class; swaps the proxy out once results
are ready.

=cut

sub can {
    my ($this, $check) = @_;

    if (my $class = Scalar::Util::blessed($this)) {
        if ($this->ready) {
            $_[0] = $this->swapout;
            return $_[0]->can($check);
        }

        return $this->{row_class}->can($check) if $this->{row_class};
    }

    $this->SUPER::can($check);
}

=pod

=item $bool = $row->DOES($role)

Forward C<DOES> to the eventual row's class; swaps the proxy out once results
are ready.

=cut

sub DOES {
    my ($this) = @_;

    my $class = Scalar::Util::blessed($this) or return undef;

    if ($this->ready) {
        $_[0] = $this->swapout;
        return $_[0]->DOES(@_);
    }

    return $this->{row_class}->DOES(@_) if $this->{row_class};
    return undef;
}

=pod

=item $row = DBIx::QuickORM::Row::Async->new(async => $async, ...)

Construct a placeholder around an async handle. Requires C<async>; accepts
C<auto_refresh>, C<state_method>, and C<state_args>.

=cut

sub new {
    my $class = shift;
    my $self = bless({@_}, $class);

    Carp::croak("You must specify an 'async'") unless $self->{async};

    Carp::croak("'$self->{async}' does not implement the 'DBIx::QuickORM::Role::Async' role")
        unless $self->{async}->DOES('DBIx::QuickORM::Role::Async');

    $self->{state_method} //= 'state_select_row';
    $self->{state_args} //= [];

    return $self;
}

=pod

=item $async = $row->async

The underlying async statement handle.

=item $bool = $row->auto_refresh

Whether the materialized row will be refreshed.

=item $bool = $row->is_invalid

=item $bool = $row->is_valid

Validity of the (materialized) row; both swap the proxy out first.

=cut

# {{{ accessors

sub async { $_[0]->{async} }
sub auto_refresh { $_[0]->{auto_refresh} }

sub is_invalid { $_[0]->swapout(@_)->{invalid} ? 1 : 0 }
sub is_valid   { $_[0]->swapout(@_)->{invalid} ? 0 : 1 }

# }}} accessors

=pod

=item $row_or_bool = $row->ready

Returns the materialized row if results are ready (or 1 when already invalid),
undef while still pending.

=cut

sub ready {
    my ($self) = @_;

    return 1 if $self->{invalid};

    return undef unless $self->{async}->ready();

    return $self->row;
}

=pod

=item $real_row = $row->row

Pull the single row from the async handle and build the real row object
(refreshing it when C<auto_refresh> is set), or undef if no data arrived.

=cut

sub row {
    my $self = shift;

    return $self->{row} if exists $self->{row};
    return $self->{row} = undef if $self->{invalid};

    my $async = $self->{async};
    my $data = $async->next();

    if ($data) {
        $async->set_done();
    }
    else {
        $self->{invalid} = 1;
        return $self->{row} = undef;
    }

    my %args = %$self;
    delete $args{async};
    my $auto_refresh = delete $args{auto_refresh};

    my $meth = $self->{state_method};
    my $row = $self->{row} = $async->connection->$meth(@{$self->{state_args}}, source => $async->source, fetched => $data);

    $row->refresh if $auto_refresh;

    return $row;
}

=pod

=item $row = $row->swapout

Materialize the real row and replace the proxy in the caller's slot via the
C<$_[0]> alias, returning the real row (or the proxy itself when still invalid
or pending).

=cut

sub swapout {
    my ($self) = @_;

    return $self if $self->{invalid};
    my $row = $self->row or return $self;
    return $_[0] = $row;
}

=pod

=item $row->cancel

Cancel the in-flight async query and mark the proxy invalid.

=back

=cut

sub cancel {
    my $self = shift;

    return if $self->{invalid};

    $self->{async}->cancel();

    $self->{invalid} = 1;
}

=pod

=head1 PRIVATE METHODS

=over 4

=item AUTOLOAD

Swap the proxy out for the real row and forward the called method to it,
croaking if the proxy is invalid.

=item DESTROY

Drop the async handle and mark the proxy invalid if it never materialized.

=back

=cut

sub AUTOLOAD {
    my ($self) = @_;

    our $AUTOLOAD;
    my $meth = $AUTOLOAD;
    $meth =~ s/^.*:://;

    $_[0] = $self->swapout;

    Carp::croak("This async row is not valid, the query probably returned no data, or the query was canceled")
        if $self->{invalid};

    my $sub = $_[0]->can($meth) or Carp::croak(qq{Can't locate object method "$meth" via package "} . ref($_[0]) . '"');

    goto &$sub;
}

sub DESTROY {
    my $self = shift;
    return if $self->{invalid};
    delete $self->{async};
    $self->{invalid} = 1;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
