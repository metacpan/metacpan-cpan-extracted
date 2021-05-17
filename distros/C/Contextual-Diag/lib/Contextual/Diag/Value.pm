package Contextual::Diag::Value;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.04";

use Scalar::Util ();

my %DATA;
my %OVERLOAD;

sub new {
    my ($class, $value, %overload) = @_;

    # Use inside-out to prevent infinite recursion
    my $self = bless \my $scalar => $class;
    my $id = Scalar::Util::refaddr $self;
    $DATA{$id} = {
        value    => $value,
        overload => \%overload,
    };
    return $self;
}

BEGIN {
    my %CONTEXT_MAP = (
        q{""}  => 'STR',
        '0+'   => 'NUM',
        'bool' => 'BOOL',
        '${}'  => 'SCALARREF',
        '@{}'  => 'ARRAYREF',
        '&{}'  => 'CODEREF',
        '%{}'  => 'HASHREF',
        '*{}'  => 'GLOBREF',
    );

    %OVERLOAD = map {
        my $context = $CONTEXT_MAP{$_};

        $_ => sub {
            my $self = shift;

            my $id    = Scalar::Util::refaddr $self;
            my $data  = $DATA{$id};
            my $code  = $data->{overload}->{$context};
            my $value = $data->{value};
            return $code->($value);
        }
    } keys %CONTEXT_MAP,
}

use overload %OVERLOAD, fallback => 1;

sub can {
    my ($invocant) = @_;
    if (ref $invocant) {
        our $AUTOLOAD = 'can';
        goto &AUTOLOAD;
    }
    return $invocant->SUPER::can(@_[1..$#_]);
}

sub isa {
    my ($invocant) = @_;
    if (ref $invocant) {
        our $AUTOLOAD = 'isa';
        goto &AUTOLOAD;
    }
    return $invocant->SUPER::isa(@_[1..$#_]);
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    unless (ref $self) {
        die "cannot AUTOLOAD in class call"
    }

    my $obj = do {
        my $id = Scalar::Util::refaddr $self;
        my $data  = $DATA{$id};
        my $code  = $data->{overload}->{OBJREF};
        my $value = $data->{value};
        $code->($value);
    };

    my ($method) = $AUTOLOAD =~ m{ .* :: (.*) }xms ? $1 : $AUTOLOAD;
    return $obj->$method(@_);
}

sub DESTROY {
    my $self = shift;
    my $id   = Scalar::Util::refaddr $self;
    delete $DATA{$id};
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Contextual::Diag::Value - wrapping scalar value for diagnostics

=head1 SYNOPSIS

    use Contextual::Diag::Value;

    my $value = 'hello';
    my $v = Contextual::Diag::Value->new($value,
        BOOL => sub { warn 'evaluated as BOOL';  return $_[0] },
    );

    if ($v) { }
    # => warn 'evaluated as BOOL';

=head2 new($value, %overload)

Constructor for Contextual::Diag::Value:

    Contextual::Diag::Value->new($_[0],
        BOOL      => sub { $_[0] },
        NUM       => sub { $_[0] || 0   },
        STR       => sub { $_[0] || ""  },
        SCALARREF => sub { defined $_[0] ? $_[0] : \"" },
        ARRAYREF  => sub { defined $_[0] ? $_[0] : [] },
        HASHREF   => sub { defined $_[0] ? $_[0] : {} },
        CODEREF   => sub { defined $_[0] ? $_[0] : sub { } },
        GLOBREF   => sub { defined $_[0] ? $_[0] : do { no strict qw/refs/; my $package = __PACKAGE__; \*{$package} } },
        OBJREF    => sub { defined $_[0] ? $_[0] : bless {}, __PACKAGE__ },
    );

=head2 OTHER METHODS

=head3 can

Override C<can> to hook OBJREF.

=head3 isa

Override C<isa> to hook OBJREF.

=head1 SEE ALSO

L<Contextual::Return>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

