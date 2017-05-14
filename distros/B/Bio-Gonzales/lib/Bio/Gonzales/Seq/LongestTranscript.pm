package Bio::Gonzales::Seq::LongestTranscript;

use Mouse;

use warnings;
use strict;
use Carp;

use 5.010;

use Bio::Gonzales::Util::YAML qw/freeze_file/;
use Bio::Gonzales::Seq::IO qw/faiterate faspew/;
use Bio::Gonzales::Feat::IO::GFF3;
use List::MoreUtils qw/all any none/;

our $VERSION = '0.0546'; # VERSION

has gff_file         => ( is => 'rw', required => 1 );
has seq_files        => ( is => 'rw', default  => sub { [] } );
has _cached_feats    => ( is => 'rw', default  => sub { {} } );
has _cached_lengths  => ( is => 'rw', default  => sub { {} } );
has _cached_lt_feats => ( is => 'rw', default  => sub { [] } );
has _ran         => ( is => 'rw' );
has feat_type    => ( is => 'rw', default => sub {qr/mRNA/} );
has feat_element => ( is => 'rw', default => sub {qr/exon/} );
has feat_source  => ( is => 'rw' );

sub BUILD {
    my $self = shift;
    my $args = shift;

    push @{ $self->seq_files }, $args->{seq_file}
        if ( exists( $args->{seq_file} ) );

    confess "one or more supplied sequence files do not exist.\n" . join( "\n", @{ $self->seq_files } )
        unless ( all { -f $_ } @{ $self->seq_files } );
}

sub run {
    my ($self) = @_;

    say STDERR  "Using anntotation from " . $self->gff_file ;

    #cache type for frequent usage
    my $type    = $self->feat_type;
    my $src     = $self->feat_source;
    my $element = $self->feat_element;

    my $gz = () = $self->gff_file =~ /\.gz$/;
    my $gffio = Bio::Gonzales::Feat::IO::GFF3->new(
        file          => $self->gff_file,
        gz            => $gz,
        record_filter => sub {
            my $l = shift;
            return if ( $src && $l !~ /\t$src\t/ );
            return unless ( $l =~ /\t$type\t/ || $l =~ /\t$element\t/ );
            return 1;
        }
    );

    #gene_id/parent_id => [ list of feats ]
    my %splice_variants;
    my %lengths;

    #iterate over the features and sort them into bins according to their parent id
    while ( my $f = $gffio->next_feat ) {
        next if ( $src && $f->source !~ /^$src$/ );

        # two steps:
        # a. collect exonlengths for every mrna
        # b. collect the parent gene id for every mrna

        #collect exons to determine the correct length w/o introns
        if ( $f->type =~ /^$element$/ ) {
            #add up exon lengths
            $lengths{ $f->parent_id } += $f->length;
        } elsif ( $f->type eq 'mRNA' ) {
            $splice_variants{ $f->parent_id } //= [];
            push @{ $splice_variants{ $f->parent_id } }, $f;
        } else {
            confess "Error, found: " . $f->type;
        }
    }

    $gffio->close;

    #build cache
    $self->_cached_feats( \%splice_variants );
    $self->_cached_lengths( \%lengths );
    $self->_cached_lt_feats( [] );
    $self->_ran(1);
    say STDERR "Finished feat filtering";
}

sub feats {
    my ($self) = @_;

    #run if not run before
    $self->run unless ( $self->_ran );

    #take advantage of the cache, if possible
    return @{ $self->_cached_lt_feats }
        if ( @{ $self->_cached_lt_feats } > 0 );

    my @lt_list;
    my $feats   = $self->_cached_feats;
    my $lengths = $self->_cached_lengths;

    for my $flist ( values %$feats ) {

        #find the longest feature
        my $longest_feat;

        for my $f (@$flist) {
            confess "could not find length for " . $f->id unless ( exists( $lengths->{ $f->id } ) );
            $longest_feat = $f
                if ( !$longest_feat || $lengths->{ $f->id } > $lengths->{ $longest_feat->id } );
        }

        # Bio::Gonzales::Feat
        $longest_feat->add_attr( spliced_length => $lengths->{ $longest_feat->id } );
        push @lt_list, $longest_feat;
    }

    #cache the longest feats
    $self->_cached_lt_feats( \@lt_list );

    return @lt_list;
}

sub freeze_feats {
    my ( $self, $file ) = @_;

    my $gffout = Bio::Gonzales::Feat::IO::GFF3->new( file => $file, mode => '>' );

    #write the features
    map { $gffout->write_feat($_) } $self->feats;

    $gffout->close;

    return;
}

sub freeze_ids {
    my ( $self, $file ) = @_;

    freeze_file( $file, [ map { $_->id } $self->feats ] );
}

sub freeze_seqs {
    my ( $self, $file, $map ) = @_;

    #check if sequence file exists
    croak "no sequence file supplied"
        unless ( @{ $self->seq_files } > 0 && all { -f $_ } @{ $self->seq_files } );
    say STDERR "Using sequences in: " . join( ", ", @{ $self->seq_files } ) . " out: $file";

    #a map with id => 1 for sequence filtering
    my %lt_feats_ids;

    if ($map) {
        #incorporate supplied feat_id - seq_id map
        for my $f ( $self->feats ) {
            croak "the supplied map doesn't cover all features: " . $f->id
                unless ( exists( $map->{ $f->id } ) );

            $lt_feats_ids{ $map->{ $f->id } } = 1;
        }
    } else {
        %lt_feats_ids = map { $_->id => 1 } $self->feats;
    }

    my $fai = faiterate( $self->seq_files );
    open my $faout_fh, '>', $file or confess "Can't open filehandle: $!";

    #write all seqs that are in the map
    while ( my $s = $fai->() ) {
        if ( exists( $lt_feats_ids{ $s->id } ) ) {
            faspew( $faout_fh, $s );
        }
    }

    #close filehandle
    $faout_fh->close;
}

1;
