use Bubblegum::Singleton;
use Test::More;
use Scalar::Util qw (refaddr);

can_ok 'main', 'has';
can_ok 'main', 'with';

my $obj1 = main->new;
my $oid1 = refaddr($obj1);

isa_ok $obj1, 'main', 'obj1 isa main';
ok $oid1, "oid1 has id $oid1";
is $oid1, refaddr(main->new),  "return obj1 on new() attempt #1";
is $oid1, refaddr(main->new),  "return obj1 on new() attempt #2";
is $oid1, refaddr(main->new),  "return obj1 on new() attempt #3";
is $oid1, refaddr($obj1->new), "return obj1 on new() from obj1";

my $obj2 = main->renew;
my $oid2 = refaddr($obj2);

isa_ok $obj2, 'main', 'obj2 isa main';
ok $oid2, "oid2 has id $oid2";
isnt $oid1, $oid2, 'call to renew() created a new object in obj2';
is $oid2, refaddr(main->new),  "return obj2 on new() attempt #1";
is $oid2, refaddr(main->new),  "return obj2 on new() attempt #2";
is $oid2, refaddr(main->new),  "return obj2 on new() attempt #3";
is $oid2, refaddr($obj2->new), "return obj2 on new() from obj2";

done_testing;
