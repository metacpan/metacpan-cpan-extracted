package Data::Pensieve::Revision;

use strict;
use warnings;

use DateTime::Format::MySQL;
use Moose;
use Storable qw(thaw);

has 'pensieve'  => ( is => 'rw' );
has 'row'       => ( is => 'rw' );
has 'data_hash' => ( is => 'rw' );

sub recorded {
    my $self = shift;
    my $date = $self->row->recorded;

    if (not ref $date) {
        $date = DateTime::Format::MySQL->parse_datetime($date);
    }

    return $date;
}

sub data {
    my $self = shift;

    return $self->data_hash
        if $self->data_hash;

    return unless $self->row;

    my $rows = $self->pensieve->revision_data_rs->search({
        revision_id => $self->row->revision_id,
    });

    my %data;
    for my $row ($rows->all) {
        $data{ $row->datum } = $row->datum_value;
    }

    $self->data_hash( \%data );
    return $self->data_hash;
}

sub metadata {
    my $self = shift;
    my $md_s = $self->row->metadata;
    if ($md_s) {
        return thaw $md_s;
    }
    return {};
}

1;

