#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
our $cltab;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 5 }

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

### test pass
$data={level=>3};
$dfa->event(TELL,$data);
ok(go($dfa,STARTING));
ok(go($dfa,CHECKING,6));
ok(go($dfa,PASSED,4));
# system("cat $cltab");
### test fail
`echo test:test7:3:test:false >> $cltab`;
$dfa->event(TELL,$data);
ok(go($dfa,FAILED,4));

$dfa->destruct;

### once

### respawn

### stop fg

1;
