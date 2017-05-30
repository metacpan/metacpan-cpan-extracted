use strict;
use warnings;

use Test::Cmd;
use Test::More tests => 2;

use lib 'lib';
use App::ExtractLinks;

my $test = Test::Cmd->new(
    prog    => './bin/extract-links',
    workdir => ''
);

$test->run(stdin => '<a href="example.com">some link</a>');
 
ok($test);
is($test->stdout, "example.com\n", 'output');
