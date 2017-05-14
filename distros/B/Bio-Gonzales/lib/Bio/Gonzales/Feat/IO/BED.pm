package Bio::Gonzales::Feat::IO::BED;

use Mouse;

use warnings;
use strict;
use Data::Dumper;
use Carp;

use 5.010;

our $VERSION = '0.0546'; # VERSION

extends 'Bio::Gonzales::Feat::IO::Base';

has 'parent_handler'  => ( is => 'rw' );
has 'track_name'      => ( is => 'rw', default => 'unknown' );
has _wrote_sth_before => ( is => 'rw' );

sub write_feat {
    my ( $self, @feats ) = @_;
    my $fh = $self->fh;

    $self->_write_header
        unless ( $self->_wrote_sth_before );

    for my $f (@feats) {
        $self->_collect_feat($f);
    }

    return;
}

sub _write_header {
    my ($self) = @_;

    my $fh = $self->fh;
    #get track name right
    my $track_name = $self->track_name;
    say $fh "track name=$track_name";

    $self->_wrote_sth_before(1);
}

sub write_collected_feats {
    confess 'this function is deprecated';
}

override 'close' => sub {
    my ($self) = @_;
    my $fh = $self->fh;

    $self->_connect_feats;
    my $parents = $self->_find_parent_feats;

    for my $p (@$parents) {
        $self->parent_handler->($p) if ( $self->parent_handler );
        print $fh _to_bed($p);
    }

    super;

    return;
};

sub _to_bed {
    my ($f) = @_;

    my $strand;
    given ( $f->strand ) {
        when ( $_ < 0 ) { $strand = '-'; }
        when ( $_ > 0 ) { $strand = '+'; }
        default {
            $strand = '+';
        }
    }

    #chr_id
    #scf_id
    #start
    #end
    #name
    #score // 0
    #strand +-
    #start (thick) == start
    #end (thick) == end
    #rgb == 0
    #block count
    #block sizes
    #block starts

    my @line
        = ( $f->scf_id, $f->start - 1, $f->end, $f->id, $f->score // 0, $strand, ( $f->start - 1 ), $f->end,
        0 );

    my @sf = $f->recurse_subfeats;
    if ( @sf > 0 ) {

        #my %sf = (map { $_->start . '_' . $_->end => $_ } @sf);

        @sf = sort { ( $a->start <=> $b->start ) || ( $b->end <=> $a->end ) } @sf;
        push @line, scalar @sf;

        push @line, join( ',', map { $_->end - $_->start + 1 } @sf );
        push @line, join( ',', map { ( $_->start - $f->start ) } @sf );
    }

    return join( "\t", @line ), "\n";
}

__PACKAGE__->meta->make_immutable;

1;
