use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('Cookie::XS'); }

# http://rt.cpan.org/Public/Bug/Display.html?id=34238
my $res = Cookie::XS->parse("foo=ba=r");
ok $res, 'res is true';
ok $res->{foo}, 'variable foo found';
is $res->{foo}->[0], 'ba=r', 'the value of foo is okay';

