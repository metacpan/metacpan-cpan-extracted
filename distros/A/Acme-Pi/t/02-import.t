use strict;
use warnings;

use Test::More 0.88;
use utf8;
use Acme::Pi;

binmode $_, ':encoding(UTF-8)' foreach map { Test::Builder->new->$_ } qw(output failure_output todo_output);
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

ok(defined($π), 'we have a defined $π');
ok(defined($𝝿), 'we have a defined $𝝿');
ok(defined(π), 'we have a defined π sub');
ok(defined(𝝿), 'we have a defined 𝝿 sub');

ok((3.14 < $π) && ($π < 3.15), '$π is between 3.14 and 3.15');
ok((3.14 < $𝝿) && ($𝝿 < 3.15), '$𝝿 is between 3.14 and 3.15');
ok((3.14 < π) && (π < 3.15), 'π is between 3.14 and 3.15');
ok((3.14 < 𝝿) && (𝝿 < 3.15), '𝝿 is between 3.14 and 3.15');

done_testing;
