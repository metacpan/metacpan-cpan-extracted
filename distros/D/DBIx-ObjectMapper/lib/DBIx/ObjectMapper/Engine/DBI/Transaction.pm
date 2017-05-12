package DBIx::ObjectMapper::Engine::DBI::Transaction;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;

sub new {
    my ( $class, $engine ) = @_;

    my $self = bless {
        engine   => $engine,
        complete => 0,
    }, $class;

    $self->begin;
    return $self;
}

sub engine   { $_[0]->{engine} }
sub complete { $_[0]->{complete} }

sub begin {
    my $self = shift;
    $self->engine->txn_begin;
    return $self;
}

sub commit {
    my $self = shift;
    $self->_txn_end( 'commit', @_ );
}

sub rollback {
    my $self = shift;
    $self->_txn_end( 'rollback', @_ );
}

sub _txn_end {
    my $self = shift;
    my $meth = shift;
    $self->engine->_txn_end($meth);
    return $self->{complete} = 1;
}

sub DESTROY {
    my $self = shift;
    return if $self->{complete};
    $self->rollback;
}

1;

