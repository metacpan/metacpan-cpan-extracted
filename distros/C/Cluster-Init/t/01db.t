#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 18 }

use Cluster::Init::DB;
# use Data::Dump qw(dump);

package test;
use strict;
sub new
{
  my $class=shift;
  my $self={@_};
  bless $self,$class;
}

package main;

my @itemrefs;
my $db = new Cluster::Init::DB;
ok($db);
my $hello = test->new (group=>'foo',tag=>'hello',level=>2);
@itemrefs = $db->ins($hello);
ok(@itemrefs,1);
@itemrefs = $db->ins(bless {group=>'foo',tag=>'hello4',level=>42}, "test");
ok(@itemrefs,1);
@itemrefs = $db->upd("test",{group=>'foo',tag=>'hello'},{level=>3});
ok(@itemrefs,1);
@itemrefs = $db->upd($hello,{level=>4});
ok(@itemrefs,1);
@itemrefs = $db->upd("test",{group=>'foo',tag=>'hello4'},{level=>5});
ok(@itemrefs,1);
@itemrefs = $db->get("test",{group=>'foo'});
ok(@itemrefs,2);
# warn dump(@itemrefs);
# warn dump ($db);
@itemrefs = $db->get("test",{tag=>'hello4'});
ok(@itemrefs,1);
ok($itemrefs[0]->{level},5);
@itemrefs = $db->del($hello);
ok(@itemrefs,1);
@itemrefs = $db->del($hello);
ok(@itemrefs,0);
@itemrefs = $db->ins($hello);
ok(@itemrefs,1);
@itemrefs = $db->del("test",{tag=>'hello'});
ok(@itemrefs,1);
my ($item) = $db->get("test",{tag=>'hello4'});
ok($item->{group},'foo');
@itemrefs = $db->ins(bless
  {group=>'foo',tag=>'hello4',level=>42,version=>999}, "test");
ok(@itemrefs,1);
@itemrefs = $db->allclass("test");
ok(@itemrefs,2);
($item) = $db->get("test",{tag=>qr/.*/});
ok(@itemrefs,2);
($item) = $db->get("test",{version=>qr/.*/});
ok($item);


# warn dump ($db);

