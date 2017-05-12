use Test::More tests => 8;
use Test::Exception;
use strict;
use warnings;
use lib 't/lib';
use AccessorGroupsComp;

is(AccessorGroupsComp->result_class, undef);

## croak on set where class can't be loaded and it's a physical class
my $dying = AccessorGroupsComp->new;
throws_ok {
  $dying->result_class('NotReallyAClass');
} qr/Could not load result_class 'NotReallyAClass'/;
is($dying->result_class, undef);


## don't croak when the class isn't available but not loaded for people
## who create class/packages on the fly
$dying->result_class('JunkiesNeverInstalled');
is($dying->result_class, 'JunkiesNeverInstalled');

ok(! $INC{'BaseInheritedGroups.pm'});
AccessorGroupsComp->result_class('BaseInheritedGroups');
ok($INC{'BaseInheritedGroups.pm'});
is(AccessorGroupsComp->result_class, 'BaseInheritedGroups');

## unset it
AccessorGroupsComp->result_class(undef);
is(AccessorGroupsComp->result_class, undef);
