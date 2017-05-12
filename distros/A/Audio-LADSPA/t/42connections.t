#!/usr/bin/perl -w
use strict;

use Test::More tests => 18;
require "t/util.pl";
BEGIN {
    use_ok('Audio::LADSPA::Network');
}
SKIP: {
    skip("No SDK installed",17) unless sdk_installed();

my $dump;
{
    my $net = Audio::LADSPA::Network->new( buffer_size => 100 );
    ok($net,"instantiation");
    my $delay1 = $net->add_plugin( id => 1043);
    ok($delay1,"add delay plugin 2");

    my $delay2 = $net->add_plugin( id => 1043);
    ok($delay2,"add delay plugin 2");

    ok($net->connect($delay1,'Output',$delay2,'Input'),"normal connect");

    my @dest = $net->connections($delay1,'Output');
    is (scalar @dest, 2,"1 connection");
    is ($dest[0],$delay2,"connections: plugin");
    is ($dest[1],"Input","connections: port");


    @dest = $net->connections($delay2,'Input');
    is (scalar @dest, 2,"1 connection");
    is ($dest[0],$delay1,"connections: plugin");
    is ($dest[1],"Output","connections: port");


    $delay1->set('Delay (Seconds)',0.1);
    $delay2->set('Delay (Seconds)',0.8);
    
    ok($dump = $net->dump,"Dumping net");
}

ok(my$net = Audio::LADSPA::Network->from_dump($dump),"Restore from dump");
ok((my @plugins = $net->plugins) == 2,"2 plugins restored");
is(sprintf("%0.4f",$plugins[0]->get('Delay (Seconds)')),"0.1000","Plugin1 port value restored");
is(sprintf("%0.4f",$plugins[1]->get('Delay (Seconds)')),"0.8000","Plugin2 port value restored");

my ($plug2,$port2) = $net->connections($plugins[0],'Output');
is ($plug2,$plugins[1],"Connected to right plugin");
is ($port2,"Input","Connected to right port");

}
