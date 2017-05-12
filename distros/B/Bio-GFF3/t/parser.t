use strict;
use warnings;

use Test::More 0.88;
use File::Temp;
use File::Spec::Functions 'catfile';

use Bio::GFF3::LowLevel::Parser;

my $p = Bio::GFF3::LowLevel::Parser->open( catfile(qw( t data gff3_with_syncs.gff3 )));
$p->max_lookback( 1 );

# {
#     my $m = $p->_merge_features(
#                { locations => [1], attributes => { Foo => ['baz'], zaz => ['zoz']} },
#                { locations => [2], attributes => { Foo => ['bar'], zee => ['ziz']} }
#             );
#     is_deeply( $m,
#                { locations => [1,2], attributes => { Foo => ['baz','bar'], zaz => ['zoz'], zee => ['ziz'}},
#              ) or diag explain $m;
# }

my %stuff;
while( my $i = $p->next_item ) {
    if( ref $i eq 'ARRAY' ) {
        push @{$stuff{features}}, $i;
        for (@$i) {
            is( $_->{type}, 'gene' );
        }
    }
    elsif( $i->{directive} ) {
        push @{$stuff{directives}}, $i;
    }
    elsif( $i->{FASTA_fh} ) {
        push @{$stuff{fasta}}, $i;
    }
    else {
        die 'this should never happen!';
    }
}

my $right_stuff = do ''.catfile(qw(t data gff3_with_syncs.dumped_result));
is_deeply( \%stuff,
           $right_stuff,
           'parsed the right stuff' )
    or diag explain \%stuff;

# just do some cursory parsing of other files
for (
      [ 1010, 'messy_protein_domains.gff3'],
      [ 4, 'gff3_with_syncs.gff3' ],
      [ 51, 'au9_scaffold_subset.gff3' ],
      [ 14, 'tomato_chr4_head.gff3' ],
      [ 6, 'directives.gff3' ],
      [ 3, 'hybrid1.gff3' ],
      [ 3, 'hybrid2.gff3' ],
      [ 6, 'knownGene.gff3' ],
      [ 6, 'knownGene2.gff3' ],
      [ 16, 'tomato_test.gff3' ],
      [ 3, 'spec_eden.gff3' ],
      [ 1, 'spec_match.gff3' ],
      [ 8, 'quantitative.gff3' ],
    ) {
    my ( $count, $f ) = @$_;
    my $p = Bio::GFF3::LowLevel::Parser->open( catfile(qw( t data ), $f ));
    $p->max_lookback(10);
    my @things;
    while( my $thing = $p->next_item ) {
        push @things, $thing;
    }
    is( scalar @things, $count, "parsed $count things from $f" ) or diag explain \@things;
    is( scalar ( grep {ref $_ eq 'HASH' && exists $_->{phase}} @things), 0, "no bare-hashref features in $f" );
}

# check the fasta at the end of the hybrid files
for my $f ( 'hybrid1.gff3', 'hybrid2.gff3' ) {
    my $p = Bio::GFF3::LowLevel::Parser->open( catfile(qw( t data ), $f ));
    $p->max_lookback(3);
    my @items;
    while( my $item = $p->next_item ) {
        push @items, $item;
    }
    is( scalar @items, 3, 'got 3 items' );
    is( $items[-1]->{directive}, 'FASTA', 'last one is a FASTA directive' )
        or diag explain \@items;
    is( slurp_fh($items[-1]->{filehandle}), <<EOF, 'got the right stuff in the filehandle' ) or diag explain $items[-1];
>A00469
GATTACA
GATTACA
EOF
}


{ # try parsing from a string ref
    my $gff3 = <<EOG;
SL2.40ch01	ITAG_eugene	gene	80999140	81004317	.	+	.	Alias=Solyc01g098840;ID=gene:Solyc01g098840.2;Name=Solyc01g098840.2;from_BOGAS=1;length=5178
EOG
    my $i = Bio::GFF3::LowLevel::Parser->open( \$gff3 )->next_item;
    is( $i->[0]{source}, 'ITAG_eugene', 'parsed from a string ref OK' ) or diag explain $i;
    my $tempfile = File::Temp->new;
    $tempfile->print( $gff3 );
    $tempfile->close;
    open my $fh, '<', "$tempfile" or die "$! reading $tempfile";
    $i = Bio::GFF3::LowLevel::Parser->open( $fh  )->next_item;
    is( $i->[0]{source}, 'ITAG_eugene', 'parsed from a filehandle OK' ) or diag explain $i;

}

# check for support for children before parents, and for Derives_from
{
    my $p = Bio::GFF3::LowLevel::Parser->open( catfile(qw( t data knownGene_out_of_order.gff3 )));
    $p->max_lookback(2);

    my @stuff; push @stuff, $_ while $_ = $p->next_item;

    my $right_output = do ''.catfile(qw( t data knownGene_out_of_order.dumped_result ));
    is( scalar( @stuff ), 6, 'got 6 top-level things' );
    is_deeply( [@stuff[0..4]], $right_output, 'got the right parse results' ) or diag explain \@stuff;
    is( $stuff[5]{directive}, 'FASTA', 'and last thing is a FASTA directive' );
}


# try parsing the EDEN gene from the gff3 spec
{
    my $p = Bio::GFF3::LowLevel::Parser->open( catfile(qw( t data spec_eden.gff3 )));
    my @stuff; push @stuff, $_ while $_ = $p->next_item;
    my $eden = $stuff[2];
    is( scalar(@$eden), 1 );
    $eden = $eden->[0];
    is( scalar(@{ $eden->{child_features} }), 4, 'right number of EDEN child features' );

    is( $eden->{child_features}[0][0]{type}, 'TF_binding_site' );

    # all the rest are mRNAs
    my @mrnas = @{ $eden->{child_features} }[1..3];
    is( scalar( grep @$_ == 1, @mrnas ), 3, 'all unique-IDed' );
    @mrnas = map $_->[0], @mrnas;
    is( scalar( grep $_->{type} eq 'mRNA', @mrnas ), 3, 'all mRNAs' );
    # check that all the mRNAs share the last exon
    my $last_exon = $mrnas[2]{child_features}[3][0];
    is( $last_exon, $mrnas[0]{child_features}[3][0] );
    is( $last_exon, $mrnas[1]{child_features}[2][0] );
    is( scalar(@{ $mrnas[2]{child_features}} ), 6, 'mRNA00003 has 6 children' )
        or diag explain $mrnas[2]{child_features};
    is( scalar(@{ $mrnas[1]{child_features}} ), 4, 'mRNA00002 has 4 children' );
    is( scalar(@{ $mrnas[0]{child_features}} ), 5, 'mRNA00001 has 5 children' );
}

# try parsing an excerpt of the refGene gff3
{
    my $p = Bio::GFF3::LowLevel::Parser->open( catfile(qw( t data refGene_excerpt.gff3 )));
    my @stuff; push @stuff, $_ while $_ = $p->next_item;
    ok(1, 'parsed refGene excerpt');
    #is_deeply( \@stuff, [] ) or diag explain \@stuff;
}

# try parsing an excerpt of the TAIR10 gff3
{
    my $p = Bio::GFF3::LowLevel::Parser->open( catfile(qw( t data tair10.gff3 )));
    my @stuff; push @stuff, $_ while $_ = $p->next_item;
    ok(1, 'parsed tair10 excerpt');
    #is_deeply( \@stuff, [] ) or diag explain \@stuff;
}

for my $error_file ( 'mm9_sample_ensembl.gff3',
                     'Saccharomyces_cerevisiae_EF3_e64.gff3'
                   ) {

    # check that Saccharomyces_cerevisiae_EF3_e64.gff3 throws a parse error
    eval {
        my $p = Bio::GFF3::LowLevel::Parser->open( catfile(qw( t data ), $error_file ) );
        1 while $_ = $p->next_item;
    };
    like( $@, qr/not the same/, 'got a error about types not being the same' );
}

done_testing;

sub slurp_fh {
    my ( $fh ) = @_;
    local $/;
    return <$fh>;
}
