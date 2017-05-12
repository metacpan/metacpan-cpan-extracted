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
   biosequence=>[
                 [residues=>'atgtaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'],
                 [range=>[
                          [seq_start=>10000],
                          [seq_end=>20000],
                          [seq_strand=>+1],
                         ],
                 ],
                 [featureset=>[
                               [feature=>[
                                          [feature_type=>'transcript'],
                                          [seq_start=>0],
                                          [seq_end=>30],
                                          [seq_strand=>+1],
                                          [gene_ref=>'xyz'],
                                         ],
                               ],
                               [feature=>[
                                          [feature_type=>'exon'],
                                          [seq_start=>0],
                                          [seq_end=>10],
                                          [seq_strand=>+1],
                                         ],
                               ],
                               [feature=>[
                                          [feature_type=>'exon'],
                                          [seq_start=>20],
                                          [seq_end=>30],
                                          [seq_strand=>+1],
                                         ],
                               ],
                              ]
                 ],
                ]
  ];
my $tree = Node(@$tree1);

#XML::NestArray::DEBUG(1);
#print $tree / 'residues';
print "R=" . ($tree-'residues'), "\n";
#print tree2xml(findSubTree($tree, 'residues'));
#print tree2xml($tree);
my ($st) = $tree+'residues';
print tree2xml([all=>$tree*'residues']);
my $f = $tree*'feature';
my @ok = grep { [seq_start=>20] < $_ } @$f;
map { print tree2xml($_) } @ok;
my @ok = grep { [feature=>[[seq_start=>20],[seq_end=>31]]] < $_ } @$f;
map { print tree2xml($_) } @ok;
#print tree2xml($tree);

sub minus {
    my ($h, @t) = @_;
    if (@t) {
        $h - minus(@t);
    }
    else {
        $h;
    }
}

sub fLen {
    my $f = shift;
    minus(
          findSubTreeVal($f, "seq_end"),
          findSubTreeVal($f, "seq_start"),
         )
}
sub mk_subSeq {
    my $tree = shift;
    return sub {
        my $f = shift;
        substr(
               findSubTreeVal($tree, "residues"),
               findSubTreeVal($f, "seq_start"),
               fLen($f)
              )
    }
}
sub translate {
    my $seq = shift;
    my %table = @_;
    $seq =~ s/(.{3})/$1 /g;
    my @codons = split(' ',$seq);
    join('',
         map {$table{$_} || '?'} @codons);
}
sub mk_translate {
    my %table = @_;
    return sub {
        my $seq = shift;
        return translate($seq, %table);
    }
}

my $subSeq = mk_subSeq($tree);
my ($f) = findSubTree($tree, 'feature');
print $subSeq->($f);

my $translate = mk_translate(atg=>'M');
print $translate->($subSeq->($f));

sub intersects {
    my ($f1, $f2) = @_;
    printf "\nc1=%s %s\n", ($f1.'seq_start'), ($f1.'seq_end');
    printf "\nc2=%s %s\n", ($f2.'seq_start'), ($f2.'seq_end');
    ($f1 . 'seq_start') <= ($f2 . 'seq_end') &&
      ($f2 . 'seq_start') <= ($f1 . 'seq_end');
}

sub mk_intersects {
    my $f = shift;
    return sub {
        my $f2 = shift;
        intersects($f, $f2);
    }
}

sub project {
    my ($f1, $f2) = @_;
}

sub composite {
    my $fset = shift;
    return
      Node(gene=>[
                  [transcript=>[
                               ]
                  ],
                  [funcdata=>[
                              [function=>'tm receptor'],
                             ],
                  ],
                 ]
          );
}

my $intersects_f1 = mk_intersects($f);
print 111 if $intersects_f1->($f);
print 222 if $intersects_f1->(Node(feature=>[
                                             [seq_start=>122],
                                             [seq_end=>222]
                                            ]
                                  ));
my $tree1 =
  [
   biosequence=>[
                 [residues=>'atgtaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'],
                 [range=>[
                          [seq_start=>10000],
                          [seq_end=>20000],
                          [seq_strand=>+1],
                         ],
                 ],
                 [featureset=>[
                               [feature=>[
                                          [feature_type=>'transcript'],
                                          [gene_ref=>'xyz'],
                                          [location=>[
                                                      [seq_start=>0],
                                                      [seq_end=>10],
                                                      [seq_strand=>+1],
                                                     ],
                                          ],
                                          [location=>[
                                                      [seq_start=>20],
                                                      [seq_end=>30],
                                                      [seq_strand=>+1],
                                                     ],
                                          ],
                                          [location=>[
                                                      [seq_start=>40],
                                                      [seq_end=>50],
                                                      [seq_strand=>+1],
                                                     ],
                                          ],
                                         ],
                               ],
                               [feature=>[
                                          [feature_type=>'cds'],
                                          [gene_ref=>'xyz'],
                                          [location=>[
                                                      [seq_start=>5],
                                                      [seq_end=>10],
                                                      [seq_strand=>+1],
                                                     ],
                                          ],
                                          [location=>[
                                                      [seq_start=>20],
                                                      [seq_end=>30],
                                                      [seq_strand=>+1],
                                                     ],
                                          ],
                                          [location=>[
                                                      [seq_start=>40],
                                                      [seq_end=>46],
                                                      [seq_strand=>+1],
                                                     ],
                                          ],
                                         ],
                               ],
                              ]
                 ],
                ]
  ];
my $tree = Node(@$tree1);

sub lSubtract {
    my $loc1 = shift;
    my $loc2 = shift;
}

sub fPoints {
    my $f = shift;
    my $locs = $f * 'location';
    my @ss = map { ($_.'seq_start'), ($_.'seq_end') } @$locs;
    @ss;
}

sub spliceLocs {
    my $f = shift;
    my @ss = fPoints($f);
    pop @ss;
    shift @ss;
    @ss;
}

sub fSubtract {
    my $f1 = shift;
    my $f2 = shift;
    my $locs1 = $f1 * 'location';
    my $locs2 = $f2 * 'location';
    my $locs3 = cloneNode($f1)*'location';
    foreach my $loc3 (@$locs3) {
        my $iloc3 = mk_intersects($loc3);
        foreach my $loc2 (@$locs2) {
            if ($iloc3->($loc2)) {
                lSubtract($loc3, $loc2);
            }
        }
    }
}
