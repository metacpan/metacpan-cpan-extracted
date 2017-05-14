use warnings;
use Test::More;
use Data::Dumper;

BEGIN { use_ok("Bio::Gonzales::Seq"); }

my $seq = Bio::Gonzales::Seq->new(seq => 'aggct', id => 'test');
is($seq->revcom->seq, 'agcct');

done_testing();

