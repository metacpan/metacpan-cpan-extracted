use strict;
use warnings;

use Test::More tests => 2;

use lib 'lib';
use App::ExtractLinks;

my $stdout;

$stdout = `echo '<a href="example.com">a link</a>' | ./bin/extract-links`;
is $stdout, "example.com\n";

$stdout = `echo '<div><b><a class="xyz" href="https://example.org">a link</a></b></div>' | ./bin/extract-links`;
is $stdout, "https://example.org\n";
