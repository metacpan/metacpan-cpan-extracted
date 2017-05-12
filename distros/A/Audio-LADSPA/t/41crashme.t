#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;
require "t/util.pl";
BEGIN {
    use_ok('Audio::LADSPA::Network');
}
SKIP: {
    skip("No SDK installed",3) unless sdk_installed();
my $net = Audio::LADSPA::Network->new( buffer_size => 1024 );
my $sine = $net->add_plugin( id => 1047);
my $delay = $net->add_plugin( id => 1043);

eval {
    $sine->run(100000); # out of buffer range
};
ok ($@ =~ /^Cannot run for more than 1024 samples/,"Range checking");
eval {
    $sine->run(1024);
};
ok (!$@,"Range edge");

eval {
    $sine->run(0); # bwahaha!
};
ok(!$@,"Null run");


my %plugins = ( $sine => $sine );

delete $plugins{$sine};

my $buff = $sine->get_buffer(0);

my %buffer = ( $buff => $buff);

$sine->disconnect_all();

{
    my $net = Audio::LADSPA::Network->new();
}
}

END {
    ok(1,"End phase");
}



