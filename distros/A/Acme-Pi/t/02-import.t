use strict;
use warnings;

use Test::More 0.88;
use utf8;
use Acme::Pi;

binmode $_, ':encoding(UTF-8)' foreach map { Test::Builder->new->$_ } qw(output failure_output todo_output);
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

ok(defined($π), 'we have a defined $π');

done_testing;
