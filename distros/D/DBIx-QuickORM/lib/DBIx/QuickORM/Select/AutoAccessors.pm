package DBIx::QuickORM::Select::AutoAccessors;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Sub::Util qw/set_subname/;

use parent 'DBIx::QuickORM::Select';
use DBIx::QuickORM::Util::HashBase;

sub import {}
sub unimport {}
sub DESTROY {}

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self) = @_;

    my $meth = $AUTOLOAD;
    $meth =~ s/^.*:://g;

    my $class = blessed($self) // $self;

    croak qq{Can't locate object method "$meth" via package "$self"}
        unless blessed($self);

    my $sub = $self->can($meth) or croak qq{Can't locate object method "$meth" via package "$class"};

    goto &$sub;
}

sub can {
    my $self = shift;

    return $self->UNIVERSAL::can(@_) unless blessed($self);

    if (my $sub = $self->UNIVERSAL::can(@_)) {
        return $sub;
    }

    my ($name) = @_;

    if (my $rel = $self->table->relation($name)) {
        return set_subname $name => sub { my $self = shift; $self->relations($name) };
    }

    return undef;
}

1;
