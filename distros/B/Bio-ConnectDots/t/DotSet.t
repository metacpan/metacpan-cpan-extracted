#!/usr/bin/perl
use lib qw(./t blib/lib);
use strict;
no warnings;
use Test::More qw(no_plan);

use Bio::ConnectDots::DotSet;
use Bio::ConnectDots::Dot;
use Bio::ConnectDots::Connector;
use Bio::ConnectDots::ConnectorSet;

# test constructor
my $dot_set = new Bio::ConnectDots::DotSet;
is(ref($dot_set), 'Bio::ConnectDots::DotSet', 'calling DotSet constructor');

# test id2dot()
my $id_ret = $dot_set->id2dot();
isnt($id_ret, undef, 'check that id2dot() returns something');
is(ref($id_ret), 'HASH', 'check that id2dot returns hash of translations');

my $dot = new Bio::ConnectDots::Dot;
$dot->{id} = 'test01'; $dot->{dot_set} = 'LL';
my $add_ret = $dot_set->id2dot('test01', $dot);
is(ref($add_ret), 'Bio::ConnectDots::Dot', 'check that id2dot(id, Dot) returns a Dot object on insertion');

my $check_val = $dot_set->id2dot('test01');
is($check_val->{id} eq 'test01' && $check_val->{dot_set} eq 'LL', 1, 'check id2dot(id) for proper return');

# test instances()
my $instances = $dot_set->instances();
is(@$instances[0]->{id}, 'test01', 'checking instances()');

# test lookup()
my $lookup_ret = $dot_set->lookup('test01');
is($lookup_ret->{id} eq 'test01' && $lookup_ret->{dot_set} eq 'LL', 1, 'check lookup(id) for proper return');

# test lookup_connect()
my $dot2 = new Bio::ConnectDots::Dot;
$dot2->{id} = 'test02'; $dot2->{dot_set} = 'UG';
$dot_set->id2dot('test02',$dot2);
my $connector = new Bio::ConnectDots::Connector;
$connector->{connectorset} = new Bio::ConnectDots::ConnectorSet(-name=>'testSet');
$dot_set->lookup_connect('test02', $connector);

my $ret_connector = $dot_set->lookup('test02')->connectors()->[0];
is($ret_connector->name(), $connector->name(), 'check that lookup_connect(id, Connector) adds the connector');


1;