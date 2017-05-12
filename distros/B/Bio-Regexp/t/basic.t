use strict;

use Test::More;
use Data::Dumper;

use Bio::Regexp;


verify(Bio::Regexp->new->add('')->single_stranded,
       'AAA',
       'empty regexp finds all interbase coords',
       matches => [[0,0,''],[1,1],[2,2],[3,3]]);


verify(Bio::Regexp->new->add('AA')->single_stranded,
       'AAA',
       'basic overlap',
       matches => [[0,2],[1,3]]);


verify(Bio::Regexp->new->add('GATA')->single_stranded,
       'GATTGATC',
       'basic no match',
       matches => []);


verify(Bio::Regexp->new->add('GAT{2,3}C[AT]')->single_stranded,
       'GGGATTCAAGATTTCTA',
       'simple regexp operations',
       matches => [[2,8],[9,16]]);


verify(Bio::Regexp->new->add('AA')->add('AC')->single_stranded,
       'AAC',
       'basic multi-regexp',
       matches => [[0,2],[1,3]]);


verify(Bio::Regexp->new->add('ATG'),
       'AAAGACATCC',
       'basic reverse complement',
       matches => [[8,5,'CAT']]);


verify(Bio::Regexp->new->rna->add('AUG'),
       'GGCCGGCATAA',
       'RNA pattern, DNA string',
       matches => [[9,6]]);


verify(Bio::Regexp->new->add('TAT'),
       'AUGUAUAA',
       'DNA pattern, RNA string',
       matches => [[3,6],[7,4]]);


verify(Bio::Regexp->new->add('GAATTC'),
       'AGACTGAGAATTCGGG',
       'palindrome matches twice same place',
       matches => [[7,13],[13,7]]);


verify(Bio::Regexp->new->add('AGGT')->circular,
       'GTCGCGAG',
       'basic circular',
       matches => [[6,10]]);


verify(Bio::Regexp->new->add('AA')->circular,
       'AAGCGA',
       'circular no dup',
       matches => [[0,2],[5,7]]);


verify(Bio::Regexp->new->add('GAAC')->circular,
       'TCAGT',
       'circular and reverse complement',
       matches => [[7,3,'GTTC']]);


verify(Bio::Regexp->new->add('HYNV'),
       'ACTG',
       'basic IUPAC',
       matches => [[0,4]]);

verify(Bio::Regexp->new->add('[^H]{2}'),
       'GG',
       'negated IUPAC',
       matches => [[0,2]]);

verify(Bio::Regexp->new->add('DWW[^MG][^V][^D]'),
       'GAATTC',
       'combine base and IUPAC',
       matches => [[0,6],[6,0]]);


verify(Bio::Regexp->new->add('AUG')->no_substr,
       'GCGAUGGCG',
       'no substr',
       matches => [[3,6,undef]]);



done_testing();



sub verify {
  my ($obj, $input, $desc, %checks) = @_;

  my @matches = $obj->match($input);

  print Dumper(\@matches) if $checks{dumper};

  if (exists $checks{matches}) {
    is(scalar @matches, scalar @{ $checks{matches}}, "$desc: length check");

    foreach my $i (0 .. $#matches) {
      is($matches[$i]->{start}, $checks{matches}->[$i]->[0], "$desc: $i start");
      is($matches[$i]->{end}, $checks{matches}->[$i]->[1], "$desc: $i end");

      if (exists $checks{matches}->[$i]->[2]) {
        is($matches[$i]->{match}, $checks{matches}->[$i]->[2], "$desc: $i match string");
      }

    }
  }

}
