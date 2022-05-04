
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use_ok 'SugarApp';
my $app = SugarApp->new;
is $app->sweet, "sweet cookie!";
like $app->run, qr/hier/;

done_testing;


