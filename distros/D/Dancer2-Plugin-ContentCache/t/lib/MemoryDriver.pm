package MemoryDriver;
use v5.20;
use warnings;
use Moo;
use DateTime;

with 'Dancer2::Plugin::ContentCache::Driver';

has plugin => ( is => 'ro' );
has config => ( is => 'ro' );
has _store => ( is => 'ro', default => sub { {} } );

sub has_aging_columns  { 1 }
sub has_created_column { 1 }

sub create_entry {
    my ( $self, %entry ) = @_;
    $self->_store->{ $entry{uuid} } = {%entry};
    return $entry{uuid};
}

sub find_entry {
    my ( $self, $uuid ) = @_;
    my $row = $self->_store->{$uuid} or return undef;
    return {%$row};
}

sub delete_expired {
    my $self = shift;
    my $now  = DateTime->now;
    my $count = 0;

    for my $uuid ( keys %{ $self->_store } ) {
        my $row = $self->_store->{$uuid};
        next unless $row->{expiry_dt};
        next if DateTime->compare( $row->{expiry_dt}, $now ) > 0;
        delete $self->_store->{$uuid};
        $count++;
    }

    return $count;
}

1;
