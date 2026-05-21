use strict;
use warnings;
use Test::More;

my $perlglue = "$^X -Ilib bin/perlglue";

my $upper = `$^X -e "print qq(perl\n)" | $perlglue upper`;
is($upper, "PERL\n", 'upper command works');

my $lower = `$^X -e "print qq(PERL\n)" | $perlglue lower`;
is($lower, "perl\n", 'lower command works');

done_testing;
