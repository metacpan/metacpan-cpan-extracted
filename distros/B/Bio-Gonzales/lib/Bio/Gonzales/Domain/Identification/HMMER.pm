#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Domain::Identification::HMMER;

use Mouse;
use File::stat;

use warnings;
use strict;
use Carp;
use Bio::Gonzales::SearchIO::HMMResult;
use File::Spec;
use Path::Class;
use Data::Dumper;
use List::MoreUtils qw/uniq any/;
use Bio::Gonzales::Domain::Identification::HMMER::SeqMarks;
use Bio::SeqIO;
use Bio::Gonzales::PrimarySeqIX;

use 5.010;
our $VERSION = '0.0546'; # VERSION

has 'profile_db' => ( is => 'rw', required => 1 );
has 'result_dir' => ( is => 'rw', required => 1 );
has 'options'    => ( is => 'rw', default  => sub { [] } );

has '_intermediate_result_files' => ( is => 'rw', default => sub { {} } );
has '_intermediate_result_id' => ( is => 'bare', default => 0 );

has 'domain_spanning_region_file'        => ( is => 'rw' );
has 'domain_spanning_region_masked_file' => ( is => 'rw' );
has 'domains_masked_inverted_file'       => ( is => 'rw' );
has 'domains_masked_file'                => ( is => 'rw' );
has 'whole_sequence_file'                => ( is => 'rw' );
has 'domains_notfound_file'              => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->_catmyfile('not_found_domains.txt') }
);
has 'discovered_cache_file' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $_[0]->_catmyfile('discovered.cache') }
);

has 'from_cache' => ( is => 'rw', default => 0 );

has 'domain_groups' => ( is => 'rw', default => sub { [] } );

=head1 NAME

Bio::Gonzales::Util::FunCon::Domains::Identification::HMMER - Identify Protein Domains with HMMER

=head1 SYNOPSIS

    use Bio::Gonzales::Util::FunCon::Domains::Identification::HMMER;
    my $idfy =Bio::Gonzales::Util::FunCon::Domains::Identification::HMMER->new({ domain_ids => [ 'id1', .., 'idn'], hmm_query_file => 'path/to/hmm/db'});

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 BUILD

standard constructor addition

=cut

#sub BUILD {
#}

=head2 $i->identify

Starts up hmmsearch and identifies putative domains.

Returns an array of hashes of the structure:

    [
        {
            file_name => 'file_name',
            domain_id => 'id',
            protein_id => 'id',
            from => x,
            to => y
        },
        ..
    ]

=cut

sub _run_hmmsearch {
    my ( $self, $sequence_file ) = @_;

    my $im_file
        = $self->_gen_intermediate_result_name( 'hmmsearch_' . _basename_no_suffix($sequence_file) . '.result' );
    open my $hmmsearch, '-|', 'hmmsearch', '--noali', @{ $self->options },
        '-o', $im_file, $self->profile_db, $sequence_file
        or croak "Can't open filehandle: $!";
    return $im_file;
}

sub _basename_no_suffix {
    my ($file) = @_;
    ( my $basename_no_suffix = file($file)->basename ) =~ s/\.\w+?$//;
    return $basename_no_suffix;
}

sub _gen_intermediate_result_name {
    my ( $self, $suffix ) = @_;

    return File::Spec->catfile( $self->result_dir, $self->{_intermediate_result_id}++ . "_" . $suffix );
}

sub _catmyfile {
    my ( $self, $filename ) = @_;

    return File::Spec->catfile( $self->result_dir, $filename );
}

=head2 $i->unlink_destination_files

Deletes all destination files (the ones required in the constructor, except the cache file

=cut

=head2 _transform_hmm_hits

Transforms the best hits result from
Bio::Gonzales::Util::SearchIO::HMMResult->get_best_hits to a more accessible structure
and determines the maximum possible spanning region. This function also builds
up a cache of sequence-id_size, found-domain and position cache for faster access
later on

=cut

sub _transform_hmm_hits {
    my ( $self, $best_hits, $sequence_file ) = @_;

    open my $cache, '>>', $self->discovered_cache_file
        or croak "Can't open filehandle: $!";

    my %result_for_sequence;
    for my $k ( @{$best_hits} ) {

        #write to cache
        say $cache $self->_create_cache_string( $sequence_file, $k )
            unless ( $self->from_cache );

        #find maximum possible spanning region of a group in one sequence
        $result_for_sequence{ $k->{seq_id} } //= Bio::Gonzales::Util::FunCon::Domains::Identification::HMMER::SeqMarks->new(
            num_marks => scalar @{ $self->domain_groups } );
        $self->_update_sequence_mark( $result_for_sequence{ $k->{seq_id} }, $k );
    }
    $cache->close;

    return \%result_for_sequence;
}

sub _create_cache_string {
    my ( $self, $sequence_file, $k ) = @_;

    return join "\t",
        (
        _basename_no_suffix($sequence_file) . "_" . stat($sequence_file)->size,
        $k->{seq_id}, $k->{hmm_acc}, $k->{hmm_score}, $k->{from}, $k->{to}
        );
}

sub _update_sequence_mark {
    my ( $self, $seq_result, $best_hit ) = @_;

    my @domain_groups = @{ $self->domain_groups };

    for ( my $i = 0; $i < @domain_groups; $i++ ) {
        $seq_result->update_mark( $i, $best_hit->{from}, $best_hit->{to} )
            if (
            any { $best_hit->{hmm_acc} eq $_ }
            keys %{ $domain_groups[$i] }
            );
    }
}

sub _get_cached_hits {
    my ( $self, $sequence_file ) = @_;

    my @best_hits;

    my $seq_file_id = _basename_no_suffix($sequence_file) . "_" . stat($sequence_file)->size;

    open my $cache, '<', $self->discovered_cache_file
        or croak "Can't open filehandle: $!";
    while ( my $l = <$cache> ) {
        my @rows = split /\t/, $l;
        push @best_hits,
            {
            seq_id    => $rows[1],
            hmm_acc   => $rows[2],
            hmm_score => $rows[3],
            from      => $rows[4],
            to        => $rows[5]
            }
            if ( $rows[0] eq $seq_file_id );
    }
    return \@best_hits;
}

sub identify {
    my ( $self, $sequence_file, $tag ) = @_;

    #run hmmsearch and get the best hits for each domain and seq_id

    my $best_hits;
    unless ( $self->from_cache ) {
        $best_hits
            = Bio::Gonzales::Util::SearchIO::HMMResult->new( file => $self->_run_hmmsearch($sequence_file) )->get_best_hits();

    } elsif ( -f $self->discovered_cache_file ) {
        $best_hits = $self->_get_cached_hits($sequence_file);
    } else {
        croak "Cache file " . $self->discovered_cache_file . " not found";
    }

    #use standard groups if attribute not set, one group with all domains
    unless ( @{ $self->domain_groups } > 0 ) {
        $self->_create_standard_domain_groups($best_hits);
    }

    my $result_for_sequence = $self->_transform_hmm_hits( $best_hits, $sequence_file );

    #open input sequence file
    my $snf2 = Bio::SeqIO->new(
        -format => 'fasta',
        -file   => $sequence_file,
    );

    #open file for spanning domains, if set
    my $domain_spanning_region;
    $domain_spanning_region = Bio::SeqIO->new(
        -format => 'fasta',
        -file   => ">>" . $self->domain_spanning_region_file,
    ) if ( $self->domain_spanning_region_file );

    my $domain_spanning_region_masked;
    $domain_spanning_region_masked = Bio::SeqIO->new(
        -format => 'fasta',
        -file   => ">>" . $self->domain_spanning_region_masked_file,
    ) if ( $self->domain_spanning_region_masked_file );

    #open file for masked spanning domains, if set
    my $domains_masked_inverted;
    $domains_masked_inverted = Bio::SeqIO->new(
        -format => 'fasta',
        -file   => ">>" . $self->domains_masked_inverted_file,
    ) if ( $self->domains_masked_inverted_file );

    #open file for masked spanning domains, if set
    my $domains_masked;
    $domains_masked = Bio::SeqIO->new(
        -format => 'fasta',
        -file   => ">>" . $self->domains_masked_file,
    ) if ( $self->domains_masked_file );

    #open file for complete sequence, if set
    my $whole_sequence;
    $whole_sequence = Bio::SeqIO->new(
        -format => 'fasta',
        -file   => ">>" . $self->whole_sequence_file,
    ) if ( $self->whole_sequence_file );

    #store some kind of found/notfound/how many not found
    #information in a file
    open my $not_found, '>>', $self->domains_notfound_file
        or croak "Can't open filehandle: $!";

    open my $seq_ids_fh, '>>', $self->_catmyfile('hmmmer_result_seqids.tsv');
    #run through sequences file to extract sequences with hits
    while ( my $so = $snf2->next_seq ) {

        $so->desc( "(" . $tag . ") " . $so->desc ) if ($tag);
        #has the sequence has at least in every group/mark
        if ( exists $result_for_sequence->{ $so->display_id() }
            && $result_for_sequence->{ $so->display_id() }->hit_in_every_mark )
        {
            my $r = $result_for_sequence->{ $so->display_id() };
            $r->extend(50);
            $r->boundaries( [ 1, $so->length ] );

            say $seq_ids_fh join("\t", $so->display_id,  @{ $r->spanning_region }{ 'from', 'to' } );
            #write, if set
            if ($whole_sequence) {
                $whole_sequence->write_seq($so);
            }

            if ($domain_spanning_region) {
                #do we have an ambigous id?
                #FIXME
                #say "Non-Unique ID: ", $so->display_id(), "  ",  $so->length
                #if ( $so->length < $r->[1] );
                $domain_spanning_region->write_seq( $so->trunc( @{ $r->spanning_region }{ 'from', 'to' } ) );
            }
            $r->clear_extend;
            if ($domain_spanning_region_masked) {
                #take care, mask changes the $so object
                $domain_spanning_region_masked->write_seq(
                    $so->clone->mask( @{ $r->spanning_region }{ 'from', 'to' } )->trunc_masked_ends );
            }
            if ($domains_masked) {
                #take care, mask changes the $so object

                my $tmp_so = $so->clone;
                for my $m ( @{ $r->marks } ) {
                    $tmp_so->mask( $m->{from}, $m->{to} );
                }
                $domains_masked->write_seq( $tmp_so->trunc_masked_ends );
            }
            if ($domains_masked_inverted) {
                #take care, mask changes the $so object

                for my $m ( @{ $r->inverted_marks } ) {
                    $so->mask( $m->{from}, $m->{to} );
                }
                $domains_masked_inverted->write_seq( $so->trunc_masked_ends );
            }
            #no domains found in sequence
        } elsif ( exists $result_for_sequence->{ $so->display_id() }
            && $result_for_sequence->{ $so->display_id() }->num_marks_hit > 0 )
        {
            #print number of found domains to notfound,
            #if not all domains occurr in sequence
            say {$not_found} $so->display_id()
                . "\tfound in "
                . $result_for_sequence->{ $so->display_id }->num_marks_hit . '/'
                . scalar( @{ $self->domain_groups } )
                . ' groups';
        } else {
            say {$not_found} $so->display_id() . "\treally nothing found";

        }
    }
    $seq_ids_fh->close;
    $not_found->close;
}

# for every group in array, grep for accession
sub _is_in_all_domain_groups {
    my ( $self, $hmm_hits_acc ) = @_;

    #find the group
    my $count_groups = 0;
    for my $g ( @{ $self->domain_groups } ) {
        $count_groups++
            if ( any { $g->{$_} } @{$hmm_hits_acc} );

    }
    return @{ $self->domain_groups } == $count_groups;
}

sub _save_to_cache {
    my ( $self, $cache_fh, $d ) = @_;

}

sub _create_standard_domain_groups {
    my ( $self, $best_hits ) = @_;

    my %domains = map { $_->{hmm_acc} => 1 } @{$best_hits};

    $self->domain_groups(
        [
            map {
                { $_ => 1 }
                } keys %domains
        ]
    );
}

1;

__END__

=head1 SEE ALSO
=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
