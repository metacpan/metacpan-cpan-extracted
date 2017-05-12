use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 14;
}
use XML::NestArray qw(:all);
use FileHandle;
use strict;
use Data::Dumper;

my $tree1 =
  [
   geneset=>[
             [gene=>[
                     [id=>"g1"],
                     [name=>"blah"],
                     [function=>"receptor"],
                    ]
             ],
             [gene=>[
                     [id=>"g2"],
                     [name=>"fred"],
                     [function=>"enzyme"],
                    ]
             ],
             [gene=>[
                     [id=>"g3"],
                     [name=>"zog"],
                     [function=>"binding"],
                     [function=>"dna repair"],
                    ]
             ],
             [gene=>[
                     [id=>"g4"],
                     [name=>"quah"],
                     [function=>"transport"],
                    ]
             ],
            ],
  ];
my $tree2 =
  [
   geneset=>[
             [gene=>[
                     [id=>"g1"],
                     [allele=>[
                               [allele_id=>'g1[a]'],
                               [phenotype=>'wing'],
                              ]
                     ],
                    ],
             ],
             [gene=>[
                     [id=>"g1"],
                     [allele=>[
                               [allele_id=>'g1[b]'],
                               [phenotype=>'lethal'],
                               [mutagen=>'X-ray'],
                              ]
                     ],
                    ]
             ],
             [gene=>[
                     [id=>"g2"],
                     [allele=>[
                               [allele_id=>'g2[a]'],
                               [phenotype=>'segment A6'],
                               [phenotype=>'segment A5'],
                              ]
                     ],
                    ]
             ],
             [gene=>[
                     [id=>"g3"],
                     [allele=>[
                               [allele_id=>'g3[a]'],
                               [phenotype=>'eye'],
                              ]
                     ],
                    ]
             ],
             [gene=>[
                     [id=>"g4"],
                     [allele=>[
                               [allele_id=>'g4[a]'],
                               [phenotype=>'antenna'],
                              ]
                     ],
                    ]
             ],
            ],
  ];

my @genes = findSubTree($tree2, "gene");
mergeElements($tree1, \@genes, "id");
print tree2xml($tree1);

ok(1);

collapseElement($tree2, "gene", "id");
print tree2xml($tree2);
