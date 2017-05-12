#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use Bio::Gonzales::Feat::IO::GFF3;
use Bio::Gonzales::Feat;
use Data::Printer;

use Bio::SearchIO;
use Getopt::Long::Descriptive;

my ( $opt, $usage ) = describe_options(
    '%c %o <blast_result_file>',
    [],
    [ 'output_file|o=s',     "output file name. If not set, stdout is used" ],
    [ 'inv_query_subject|i', 'invert query and subject' ],
    [ 'description|d',       'include the hit description as Note attribute' ],
    [ 'help',                "print usage message and exit" ],
    [ 'best_hsp',            'one hit represents all hsps' ],
    [ 'blast_format=s' , 'set the blast parser for Bio::SearchIO', {default => 'blast'}],
);

print( $usage->text ), exit if $opt->help;

my $infile = shift;

die "could not open input file" unless ( $infile && -f $infile );
my $blastin = Bio::SearchIO->new(
    -format => $opt->blast_format,
    -file   => $infile,
);

my $gffout
    = Bio::Gonzales::Feat::IO::GFF3->new(
    ( $opt->output_file ? ( file => $opt->output_file ) : ( fh => \*STDOUT ) ),
    mode => '>' );

my %match_ids;
while ( my $result = $blastin->next_result() ) {
    # Bio::Search::Result::ResultI
    $gffout->write_comment( "\n# " . $result->query_name );
    while ( my $hit = $result->next_hit ) {
        # process the Bio::Search::Hit::HitI object

        while ( my $hsp = $hit->next_hsp ) {
            write_hsp( $gffout, $opt, $hit, $hsp, $result );
            last if ( $opt->best_hsp );
        }
    }
}

sub write_hsp {
    my ( $gffout, $opt, $hit, $hsp, $result ) = @_;

    ( my $hit_name = $hit->name ) =~ s/\|$//;

    my %query_data = (
        name   => $hsp->query->seq_id,
        start  => $hsp->start('query'),
        end    => $hsp->end('query'),
        strand => $hsp->strand('query'),
        length => $result->query_length,
    );
    my %subject_data = (
        name   => $hit_name,                 #$hit->name,
        start  => $hsp->start('subject'),
        end    => $hsp->end('subject'),
        strand => $hsp->strand('subject'),
        length => $hit->length,
    );

    if ( $opt->inv_query_subject ) {
        my %tmp = %query_data;
        %query_data   = %subject_data;
        %subject_data = %tmp;
    }

    #die Dumper $hsp->query;
    # process the Bio::Search::HSP::HSPI object
    my $sfeat = Bio::Gonzales::Feat->new(
        seq_id     => $query_data{name},
        source     => lc( $hit->algorithm ),
        type       => 'match',
        start      => $query_data{start},
        end        => $query_data{end},
        strand     => $query_data{strand},
        score      => $hsp->significance,
        attributes => {
            Target => [
                join( " ",
                    @subject_data{qw/name start end/},
                    Bio::Gonzales::Feat::Convert_strand( $subject_data{strand} ) )
            ],
            ID => [ $subject_data{name} . "|hit_" . ++$match_ids{ $subject_data{name} } ],
            QueryLength => [ $query_data{length} ],
            SubjectLength => [ $subject_data{length} ],

        },
    );
    $sfeat->add_attr( Note => $hit->description ) if ( $opt->description );
    $gffout->write_feat($sfeat);

}
