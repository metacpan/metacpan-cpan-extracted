use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('BGS::Future') };

{
my $f = BGS::Future->new(sub { "future $$\n" });
ok($f->join(), "join call");
}

{
my $f = future { "future $$\n" };
ok($f->(), "sub call");
}


{
my $z = future { sleep 10; "future $$\n" };
$z->cancel();
ok(!$z->(), "cancel");
}
