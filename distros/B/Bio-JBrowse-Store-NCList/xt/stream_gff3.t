use strict;
use warnings;

use Test::More;

use File::Temp 'tempdir';

use lib 't/lib';
use FileSlurping 'slurp_tree';

use Bio::GFF3::LowLevel::Parser;
use Bio::JBrowse::FeatureStream::GFF3;
use Bio::JBrowse::Store::NCList;

sub open_gff3(@) {
    return map Bio::GFF3::LowLevel::Parser->open( $_ ), @_;
}


my @f = snarf_stream( Bio::JBrowse::FeatureStream::GFF3->new( open_gff3( 'xt/data/AU9/scaffold_subset_sync.gff3' )) );
is( scalar @f, 6, 'got right feature count' ) or diag explain \@f;
#diag explain \@f;
@f = snarf_stream( Bio::JBrowse::FeatureStream::GFF3->new( open_gff3( 'xt/data/AU9/scaffold_subset_sync.gff3', 'xt/data/AU9/scaffold_subset_sync.gff3') ) );
is( scalar @f, 6*2, 'got right double feature count' ) or diag explain \@f;


{
    my $tempdir = tempdir(  );
    my $store = Bio::JBrowse::Store::NCList->new({ path => $tempdir });

    my $fstream = Bio::JBrowse::FeatureStream::GFF3->new(
        Bio::GFF3::LowLevel::Parser->open( "xt/data/AU9/single_au9_gene.gff3" )
    );

    $store->insert( $fstream );

    my $data = slurp_tree( $tempdir );
    my $cds_trackdata = $data->{'Group1.33/trackData.json'};
    is( $cds_trackdata->{featureCount}, 1, 'got right feature count' ) or diag explain $data;
    is( ref $cds_trackdata->{intervals}{nclist}[0][9][0][9], 'ARRAY', 'mRNA has its subfeatures' )
       or diag explain $data;
    is( scalar @{$cds_trackdata->{intervals}{nclist}[0][9][0][9]}, 7, 'mRNA has 7 subfeatures' )
       or diag explain $data;

    is_deeply( $data, slurp_tree( 't/data/single_au9_gene_formatted' ) ) or diag explain $data;
}



done_testing;

sub snarf_stream {
    my ( $stream ) = @_;
    my @r;
    while( my $f = $stream->() ) {
        push @r, $f;
    }
    return @r;
}
