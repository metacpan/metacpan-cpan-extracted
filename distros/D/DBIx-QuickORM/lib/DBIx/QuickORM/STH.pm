package DBIx::QuickORM::STH;
use strict;
use warnings;

our $VERSION = '0.000015';

use Carp qw/croak/;

use Role::Tiny::With qw/with/;

with 'DBIx::QuickORM::Role::STH';

use DBIx::QuickORM::Util::HashBase qw{
    <connection
    <dbh
    <sth
    <sql
    <source

    only_one
    no_rows

    +dialect
    +ready
    <result
    <done

    on_ready
    +fetch_cb
};

sub clear      { }
sub ready      { $_[0]->{+READY} //= 1 }
sub got_result { 1 }

sub dialect { $_[0]->{+DIALECT} //= $_[0]->{+CONNECTION}->dialect }

sub deferred_result { 0 }

sub init {
    my $self = shift;

    croak "'connection' is a required attribute" unless $self->{+CONNECTION};
    croak "'source' is a required attribute"     unless $self->{+SOURCE};
    croak "'sth' is a required attribute"        unless $self->{+STH};
    croak "'dbh' is a required attribute"        unless $self->{+DBH};
    croak "'result' is a required attribute"     unless exists($self->{+RESULT}) || $self->deferred_result;
}

sub next {
    my $self = shift;
    my $row_hr  = $self->_next;

    if ($self->{+ONLY_ONE}) {
        croak "Expected only 1 row, but got more than one" if $self->_next;
        $self->set_done;
    }

    return $row_hr;
}

sub _fetch {
    my $self = shift;
    return $self->{+FETCH_CB} if exists $self->{+FETCH_CB};

    if (my $on_ready = $self->{+ON_READY}) {
        return $self->{+FETCH_CB} = $on_ready->($self->{+DBH}, $self->{+STH}, $self->result, $self->{+SQL});
    }

    $self->result;
    $self->{+FETCH_CB} = undef;
    return;
}

sub _next {
    my $self = shift;

    return if $self->{+DONE};

    if (my $fetch = $self->_fetch) {
        my $row_hr = $fetch->();
        return $row_hr if $row_hr;
    }

    $self->set_done;

    return undef;
}

sub set_done {
    my $self = shift;

    return if $self->{+DONE};

    # Do this to make sure on_ready runs if it has not already.
    $self->_fetch;
    $self->clear;

    $self->{+DONE} = 1;
}

sub DESTROY {
    my $self = shift;
    return if $self->{+DONE};
    $self->set_done();
    return;
}

1;
