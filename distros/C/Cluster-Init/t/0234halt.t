#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
our $cltab;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 14 }

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

### halt

# from STARTING
$data={level=>1};
$dfa->event(TELL,$data);
ok(go($dfa,STARTING));
$dfa->event(HALT,$data);
ok(go($dfa,HALTING));
ok(go($dfa,CONFIGURED,3));

# from CHECKING
$data->{level}=1;
$dfa->event(TELL,$data);
ok(go($dfa,CHECKING,6));
$dfa->event(HALT,$data);
ok(go($dfa,CONFIGURED,3));

# from DONE
$data->{level}=1;
$dfa->event(TELL,$data);
ok(go($dfa,DONE,6));
$dfa->event(HALT,$data);
ok(go($dfa,CONFIGURED,3));

# from STOPPING
$data->{level}=1;
$dfa->event(TELL,$data);
ok(go($dfa,DONE,6));
$data->{level}=2;
$dfa->event(TELL,$data);
ok(go($dfa,STOPPING));
$dfa->event(HALT,$data);
ok(go($dfa,CONFIGURED,3));

# from DUMPING
$data->{level}=1;
$dfa->event(TELL,$data);
ok(go($dfa,DONE,6));
$data->{level}=2;
$dfa->event(TELL,$data);
ok(go($dfa,DUMPING));
$dfa->event(HALT,$data);
ok(go($dfa,CONFIGURED,3));

$dfa->destruct;

### once

### respawn

### stop fg

1;
