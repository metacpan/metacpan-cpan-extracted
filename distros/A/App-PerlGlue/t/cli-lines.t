use strict;
use warnings;
use Test::More;

my $perlglue = "$^X -Ilib bin/perlglue";

my $where = `$^X -e "print qq(ok\nERROR timeout\n)" | $perlglue lines --where '\$_ =~ /ERROR/'`;
is($where, "ERROR timeout\n", 'lines --where works');

done_testing;
