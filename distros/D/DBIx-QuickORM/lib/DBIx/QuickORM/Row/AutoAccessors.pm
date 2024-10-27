package DBIx::QuickORM::Row::AutoAccessors;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Sub::Util qw/set_subname/;

use parent 'DBIx::QuickORM::Row';
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

    my ($prefix, $col);
    my ($it) = @_;
    if ($it =~ m/^(inflated|dirty|stored|raw)_(\S+)$/) {
        ($prefix, $col) = ($1, $2);

        if ($self->has_column($col)) {
            my $meth = "${prefix}_column";
            return set_subname $it => sub { my $self = shift; $self->$meth($col => @_) };
        }
    }

    return set_subname $it => sub { my $self = shift; $self->column($it => @_) }
        if $self->has_column($it);

    if (my $rel = $self->relation_def($it)) {
        return set_subname $it => sub { my $self = shift; $self->relation($it => @_) }
            if $rel->gets_one;

        return set_subname $it => sub { my $self = shift; $self->relations($it => @_) }
            if $rel->gets_many;

        die "Internal Error: Relation '$it' does not appear to return anything";
    }

    return undef;
}

1;
