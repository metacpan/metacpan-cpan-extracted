package DBIx::QuickORM::Row::Async;
use strict;
use warnings;

use Carp();
use Scalar::Util();

use overload (
    'bool' => sub { $_[0]->{invalid} ? 0 : 1 },
);

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

sub can {
    my ($this, $check) = @_;

    if (my $class = Scalar::Util::blessed($this)) {
        if ($this->ready) {
            $_[0] = $this->swapout;
            return $_[0]->isa($check);
        }

        return $this->{row_class}->can($check) if $this->{row_class};
    }

    $this->SUPER::can($check);
}

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

sub async { $_[0]->{async} }
sub auto_refresh { $_[0]->{auto_refresh} }

sub is_invalid { $_[0]->swapout(@_)->{invalid} ? 1 : 0 }
sub is_valid   { $_[0]->swapout(@_)->{invalid} ? 0 : 1 }

sub ready {
    my ($self) = @_;

    return 1 if $self->{invalid};

    return undef unless $self->{async}->ready();

    return $self->row;
}

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

sub swapout {
    my ($self) = @_;

    return $self if $self->{invalid};
    my $row = $self->row or return $self;
    return $_[0] = $row;
}

sub cancel {
    my $self = shift;

    return if $self->{invalid};

    $self->{async}->cancel();

    $self->{invalid} = 1;
}

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
