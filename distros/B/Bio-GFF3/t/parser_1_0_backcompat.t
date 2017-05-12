use strict;
use warnings;

use Test::More 0.88;
use File::Temp;
use File::Spec::Functions 'catfile';

use Bio::GFF3::LowLevel::Parser;

my $p = Bio::GFF3::LowLevel::Parser->new( catfile(qw( t data gff3_with_syncs.gff3 )));

my %stuff;
while( my $i = $p->next_item ) {
    if( exists $i->{seq_id} ) {
        push @{$stuff{features}}, $i;
        is( $i->{type}, 'gene' );
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

my %right_stuff =
(
  'directives' => [
    {
      'directive' => 'gff-version',
      'value' => '3'
    },
    {
      'directive' => 'feature-ontology',
      'value' => 'http://song.cvs.sourceforge.net/*checkout*/song/ontology/sofa.obo?revision=1.93'
    }
  ],
  'features' => [
    {
      'attributes' => {
        'Alias' => [
          'Solyc00g005000'
        ],
        'ID' => [
          'gene:Solyc00g005000.2'
        ],
        'Name' => [
          'Solyc00g005000.2'
        ],
        'from_BOGAS' => [
          '1'
        ],
        'length' => [
          '1753'
        ]
      },
      derived_features => [],
      'child_features' => [
        {
          'attributes' => {
            'ID' => [
              'mRNA:Solyc00g005000.2.1'
            ],
            'Name' => [
              'Solyc00g005000.2.1'
            ],
            'Parent' => [
              'gene:Solyc00g005000.2'
            ],
            'from_BOGAS' => [
              '1'
            ],
            'length' => [
              '1753'
            ],
            'nb_exon' => [
              '2'
            ]
          },
          derived_features => [],
          'child_features' => [
            {
              'attributes' => {
                'ID' => [
                  'exon:Solyc00g005000.2.1.1'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005000.2.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '17275',
              'phase' => undef,
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '16437',
              'strand' => '+',
              'type' => 'exon'
            },
            {
              'attributes' => {
                'ID' => [
                  'five_prime_UTR:Solyc00g005000.2.1.0'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005000.2.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '16479',
              'phase' => undef,
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '16437',
              'strand' => '+',
              'type' => 'five_prime_UTR'
            },
            {
              'attributes' => {
                'ID' => [
                  'CDS:Solyc00g005000.2.1.1'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005000.2.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '17275',
              'phase' => '0',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '16480',
              'strand' => '+',
              'type' => 'CDS'
            },
            {
              'attributes' => {
                'ID' => [
                  'intron:Solyc00g005000.2.1.1'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005000.2.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '17335',
              'phase' => undef,
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '17276',
              'strand' => '+',
              'type' => 'intron'
            },
            {
              'attributes' => {
                'ID' => [
                  'exon:Solyc00g005000.2.1.2'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005000.2.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '18189',
              'phase' => '0',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '17336',
              'strand' => '+',
              'type' => 'exon'
            },
            {
              'attributes' => {
                'ID' => [
                  'CDS:Solyc00g005000.2.1.2'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005000.2.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '17940',
              'phase' => '2',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '17336',
              'strand' => '+',
              'type' => 'CDS'
            },
            {
              'attributes' => {
                'ID' => [
                  'three_prime_UTR:Solyc00g005000.2.1.0'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005000.2.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '18189',
              'phase' => undef,
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '17941',
              'strand' => '+',
              'type' => 'three_prime_UTR'
            }
          ],
          'end' => '18189',
          'phase' => undef,
          'score' => undef,
          'seq_id' => 'SL2.40ch00',
          'source' => 'ITAG_eugene',
          'start' => '16437',
          'strand' => '+',
          'type' => 'mRNA'
        }
      ],
      'end' => '18189',
      'phase' => undef,
      'score' => undef,
      'seq_id' => 'SL2.40ch00',
      'source' => 'ITAG_eugene',
      'start' => '16437',
      'strand' => '+',
      'type' => 'gene'
    },
    {
      'attributes' => {
        'Alias' => [
          'Solyc00g005020'
        ],
        'ID' => [
          'gene:Solyc00g005020.1'
        ],
        'Name' => [
          'Solyc00g005020.1'
        ],
        'from_BOGAS' => [
          '1'
        ],
        'length' => [
          '703'
        ]
      },
      derived_features => [],
      'child_features' => [
        {
          'attributes' => {
            'ID' => [
              'mRNA:Solyc00g005020.1.1'
            ],
            'Name' => [
              'Solyc00g005020.1.1'
            ],
            'Parent' => [
              'gene:Solyc00g005020.1'
            ],
            'from_BOGAS' => [
              '1'
            ],
            'length' => [
              '703'
            ],
            'nb_exon' => [
              '3'
            ]
          },
          derived_features => [],
          'child_features' => [
            {
              'attributes' => {
                'ID' => [
                  'exon:Solyc00g005020.1.1.1'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005020.1.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '68211',
              'phase' => '0',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '68062',
              'strand' => '+',
              'type' => 'exon'
            },
            {
              'attributes' => {
                'ID' => [
                  'CDS:Solyc00g005020.1.1.1'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005020.1.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '68211',
              'phase' => '0',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '68062',
              'strand' => '+',
              'type' => 'CDS'
            },
            {
              'attributes' => {
                'ID' => [
                  'intron:Solyc00g005020.1.1.1'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005020.1.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '68343',
              'phase' => undef,
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '68212',
              'strand' => '+',
              'type' => 'intron'
            },
            {
              'attributes' => {
                'ID' => [
                  'exon:Solyc00g005020.1.1.2'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005020.1.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '68568',
              'phase' => '0',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '68344',
              'strand' => '+',
              'type' => 'exon'
            },
            {
              'attributes' => {
                'ID' => [
                  'CDS:Solyc00g005020.1.1.2'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005020.1.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '68568',
              'phase' => '0',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '68344',
              'strand' => '+',
              'type' => 'CDS'
            },
            {
              'attributes' => {
                'ID' => [
                  'intron:Solyc00g005020.1.1.2'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005020.1.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '68653',
              'phase' => undef,
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '68569',
              'strand' => '+',
              'type' => 'intron'
            },
            {
              'attributes' => {
                'ID' => [
                  'exon:Solyc00g005020.1.1.3'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005020.1.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '68764',
              'phase' => '0',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '68654',
              'strand' => '+',
              'type' => 'exon'
            },
            {
              'attributes' => {
                'ID' => [
                  'CDS:Solyc00g005020.1.1.3'
                ],
                'Parent' => [
                  'mRNA:Solyc00g005020.1.1'
                ],
                'from_BOGAS' => [
                  '1'
                ]
              },
              derived_features => [],
              'child_features' => [],
              'end' => '68764',
              'phase' => '0',
              'score' => undef,
              'seq_id' => 'SL2.40ch00',
              'source' => 'ITAG_eugene',
              'start' => '68654',
              'strand' => '+',
              'type' => 'CDS'
            }
          ],
          'end' => '68764',
          'phase' => undef,
          'score' => undef,
          'seq_id' => 'SL2.40ch00',
          'source' => 'ITAG_eugene',
          'start' => '68062',
          'strand' => '+',
          'type' => 'mRNA'
        }
      ],
      'end' => '68764',
      'phase' => undef,
      'score' => undef,
      'seq_id' => 'SL2.40ch00',
      'source' => 'ITAG_eugene',
      'start' => '68062',
      'strand' => '+',
      'type' => 'gene'
    }
  ]


);

is_deeply( \%stuff,
           \%right_stuff,
           'parsed the right stuff' )
    or diag explain \%stuff;


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
    ) {
    my ( $count, $f ) = @$_;
    my $p = Bio::GFF3::LowLevel::Parser->new( catfile(qw( t data ), $f ));
    my @things;
    while( my $thing = $p->next_item ) {
        push @things, $thing;
    }
    is( scalar @things, $count, "parsed $count things from $f" ) or diag explain \@things;
}

# check the fasta at the end of the hybrid files
for my $f ( 'hybrid1.gff3', 'hybrid2.gff3' ) {
    my $p = Bio::GFF3::LowLevel::Parser->new( catfile(qw( t data ), $f ));
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
    my $i = Bio::GFF3::LowLevel::Parser->new( \$gff3 )->next_item;
    is( $i->{source}, 'ITAG_eugene', 'parsed from a string ref OK' ) or diag explain $i;
    my $tempfile = File::Temp->new;
    $tempfile->print( $gff3 );
    $tempfile->close;
    open my $fh, '<', "$tempfile" or die "$! reading $tempfile";
    $i = Bio::GFF3::LowLevel::Parser->new( $fh  )->next_item;
    is( $i->{source}, 'ITAG_eugene', 'parsed from a filehandle OK' ) or diag explain $i;

}

{ # parse a refGene excerpt with backcompat
    my $p = Bio::GFF3::LowLevel::Parser->new( catfile(qw( t data ), 'refGene_excerpt.gff3' ));
    while( my $i = $p->next_item ) {
        1;
        #diag explain $i;
    }
    ok(1);
}

done_testing;

sub slurp_fh {
    my ( $fh ) = @_;
    local $/;
    return <$fh>;
}
