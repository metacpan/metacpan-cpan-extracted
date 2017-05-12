#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul 0.007;

use Consul;

Test::Consul->skip_all_if_no_bin;

my $tc = Test::Consul->start(
  enable_acls => 1,
);

my $acl = Consul->acl(port => $tc->port);
ok $acl, "got ACL API object";

is_deeply(
  [ sort map { $_->id() } @{ $acl->list() } ],
  [ sort ('anonymous', $tc->acl_master_token()) ],
  'initial ACL list looks right',
);

my $id1 = $acl->create()->id();
$acl->update({ id=>$id1, name=>'foo' });
is( $acl->info( $id1 )->name(), 'foo', 'ACL was updated' );

is_deeply(
  [ sort map { $_->id() } @{ $acl->list() } ],
  [ sort ('anonymous', $tc->acl_master_token(), $id1) ],
  'ACL list after create looks right',
);

my $id2 = $acl->clone( $id1 )->id();
isnt( $id1, $id2, 'clone has a new ID' );

is_deeply(
  [ sort map { $_->id() } @{ $acl->list() } ],
  [ sort ('anonymous', $tc->acl_master_token(), $id1, $id2) ],
  'ACL list after clone looks right',
);

$acl->destroy($id1);

is_deeply(
  [ sort map { $_->id() } @{ $acl->list() } ],
  [ sort ('anonymous', $tc->acl_master_token(), $id2) ],
  'ACL list after delete looks right',
);

done_testing;
