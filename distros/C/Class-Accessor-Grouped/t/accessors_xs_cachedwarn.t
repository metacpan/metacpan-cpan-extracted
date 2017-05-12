my $has_threads;
BEGIN { eval '
  use 5.008005; # older perls get confused by $SIG fiddling under CXSA
  use threads;
  use threads::shared;
  $has_threads = 1;
' }

use strict;
use warnings;
use Test::More;
use lib 't/lib';

BEGIN {
  plan skip_all => "Sub::Name not available"
    unless eval { require Sub::Name };

  require Class::Accessor::Grouped;

  my $xsa_ver = $Class::Accessor::Grouped::__minimum_xsa_version;
  eval {
    require Class::XSAccessor;
    Class::XSAccessor->VERSION ($xsa_ver);
  };
  plan skip_all => "Class::XSAccessor >= $xsa_ver not available"
    if $@;
}

use AccessorGroupsSubclass;

my @w;
share(@w) if $has_threads;

{
  my $obj = AccessorGroupsSubclass->new;
  my $deferred_stub = AccessorGroupsSubclass->can('singlefield');
  my $obj2 = AccessorGroups->new;

  my $todo = sub {
    local $SIG{__WARN__} = sub { push @w, @_ };
    is ($obj->$deferred_stub(1), 1, 'Set');
    is ($obj->$deferred_stub, 1, 'Get');
    is ($obj->$deferred_stub(2), 2, 'ReSet');
    is ($obj->$deferred_stub, 2, 'ReGet');

    is ($obj->singlefield, 2, 'Normal get');
    is ($obj2->singlefield, undef, 'Normal get on unrelated object');

    42;
  };

  is (
    ($has_threads ? threads->create( $todo )->join : $todo->()),
    42,
    "Correct result after do-er",
  )
}

is (@w, 3, '3 warnings total');

is (
  scalar (grep { $_ =~ /^\QDeferred version of method AccessorGroupsParent::singlefield invoked more than once/ } @w),
  3,
  '3 warnings produced as expected on cached invocation during testing',
) or do {
  require Data::Dumper;
  diag "\n \$0 is: " . Data::Dumper->new([$0])->Useqq(1)->Terse(1)->Dump;
};

done_testing;
