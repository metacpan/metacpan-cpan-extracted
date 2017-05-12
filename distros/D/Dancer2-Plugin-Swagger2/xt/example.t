#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use HTTP::Request::Common;
use Plack::Test;
use Test::More;

# XS module load failure fatal in eval block -> eval string
eval "use YAML::XS; 1" or plan skip_all => "YAML::XS needed for this test";

plan tests => 3;

$ENV{DANCER_APPHANDLER} = 'PSGI';
ok( my $app = require "$FindBin::Bin/../example/my_app.pl" );

my $test = Plack::Test->create($app);

my $res = $test->request( GET '/api/welcome' );
like $res->content => qr/hello.+world/i;
is $res->code      => 200;

