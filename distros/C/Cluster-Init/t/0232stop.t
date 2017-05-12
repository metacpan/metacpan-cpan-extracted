#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use warnings;
use Test;
our $cltab;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 16 }

use Cluster::Init::Conf;
use Cluster::Init::Group;
use Cluster::Init::Kernel;
use Cluster::Init::Process;
use Cluster::Init::DFA::Group qw(:constants);
use Data::Dump qw(dump);

my $conf = Cluster::Init::Conf->new(cltab=>$cltab,context=>'server');
my $data;

# create dfa
my $dfa=Cluster::Init::Group->new ( group=>'test', conf=>$conf );
ok(go($dfa,CONFIGURED));
my $db=$dfa->{db};
ok $db;

# abort in STARTING...
# $data={level=>2};
# $ENV{DEBUG}=1;
$data->{level}=2;
$dfa->event(TELL,$data);
ok(go($dfa,STARTING,4));
my ($test3) = $db->get('Cluster::Init::Process', {tag=>'test3'});
ok $test3;
run(4);
my ($test4) = $db->get('Cluster::Init::Process', {tag=>'test4'});
ok $test4;
$data->{level}=1;
$dfa->event(TELL,$data);
ok(go($dfa,STOPPING));
# following tests fail intermittently
ok(go($dfa,DUMPING));
ok(go($dfa,STARTING,7));
my ($test1) = $db->get('Cluster::Init::Process', {tag=>'test1'});
ok $test1;
ok(go($dfa,CHECKING,7));
my ($test2) = $db->get('Cluster::Init::Process', {tag=>'test2'});
ok $test2;
# ...and in CHECKING...
$data->{level}=2;
$dfa->event(TELL,$data);
ok(go($dfa,STOPPING));
# ...and in STOPPING
$data->{level}=3;
$dfa->event(TELL,$data);
ok(go($dfa,STOPPING));
ok(go($dfa,DUMPING,2));
ok(go($dfa,STARTING,2));
ok(go($dfa,CHECKING,5));

# $dfa->destruct;
# $DB::single=1;

### once

### respawn

### stop fg


1;
