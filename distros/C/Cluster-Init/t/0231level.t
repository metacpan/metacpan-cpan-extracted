#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
our $cltab;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 13 }

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

### wait
$data={level=>1};
$dfa->event(TELL,$data);
ok(go($dfa,STARTING));
ok(go($dfa,CHECKING,6));
ok(go($dfa,DONE,6));
ok(tags(Cluster::Init::Kernel::db,qw(test1 test2)));

# level change...
$data->{level}=2;
$dfa->event(TELL,$data);
ok(go($dfa,STARTING));
ok(go($dfa,CHECKING,6));
ok(go($dfa,DONE,6));
ok(tags(Cluster::Init::Kernel::db,qw(test3 test4)));
# ...and back...
$data->{level}=1;
$dfa->event(TELL,$data);
ok(go($dfa,STARTING));
ok(go($dfa,CHECKING,6));
ok(go($dfa,DONE,6));
ok(tags(Cluster::Init::Kernel::db,qw(test1 test2)));

$dfa->destruct;

### once

### respawn

### stop fg


1;
