use strict;
use warnings;

use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use Test::More 0.88;
use utf8;
use Acme::Pi;

ok(defined($π), 'we have a defined $π');
ok(defined($𝝿), 'we have a defined $𝝿');
ok(defined(π), 'we have a defined π sub');
ok(defined(𝝿), 'we have a defined 𝝿 sub');

ok((3.14 < $π) && ($π < 3.15), '$π is between 3.14 and 3.15');
ok((3.14 < $𝝿) && ($𝝿 < 3.15), '$𝝿 is between 3.14 and 3.15');
ok((3.14 < π) && (π < 3.15), 'π is between 3.14 and 3.15');
ok((3.14 < 𝝿) && (𝝿 < 3.15), '𝝿 is between 3.14 and 3.15');

done_testing;
