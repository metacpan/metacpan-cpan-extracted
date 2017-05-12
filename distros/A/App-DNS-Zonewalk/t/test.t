use strict;
use warnings;
use Test::More;

# inject method raxfr() into Net::DNS::Resolver
use_ok('App::DNS::Zonewalk');

# method raxfr() now supported by Net::DNS::Resolver
can_ok('App::DNS::Zonewalk', 'raxfr');

my $r = new_ok('App::DNS::Zonewalk');
$r->raxfr('example.org');
#diag $r->errorstring;
like($r->errorstring, qr/nonauth/, 'check nonauth for example.org');

done_testing(4);
