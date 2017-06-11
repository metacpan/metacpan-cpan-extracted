use strict;
use warnings;

use Test::More tests => 1;

use lib 'lib';
use App::ExtractLinks;

my $stdout;

my $expected = "example.css\nexample.html\nexample.js\n";

$stdout = `cat t/test.html | ./bin/extract-links`;
is $stdout, $expected;
