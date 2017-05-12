#!/usr/bin/perl -w
use strict;

use Test::More tests => 12;
require "t/util.pl";
BEGIN {
    use_ok('Audio::LADSPA::Network');
}
SKIP: {
    skip("No SDK installed",11) unless sdk_installed();

    my $net = Audio::LADSPA::Network->new( buffer_size => 100 );
    ok($net,"instantiation");
   
    my @o_args;
    my $subscriber = sub { @o_args = @_; };
    Audio::LADSPA::Network->add_subscriber( undef, $subscriber );

    
    my $delay1 = $net->add_plugin( id => 1043);
    ok($delay1,"plugin added");

    is($o_args[1],"add_plugin","add_plugin notify");
    is($o_args[2],$delay1,"add_plugin notify2");
    

    my $delay2 = $net->add_plugin( id => 1043);
    ok($delay2,"add delay plugin 2");

    ok($net->connect($delay1,'Output',$delay2,'Input'),"normal connect");

    is($o_args[1],"connect","connect notify");
    is($o_args[2],$delay1);
    is($o_args[3],'Output');
    is($o_args[4],$delay2);
    is($o_args[5],'Input');

    Audio::LADSPA::Network->delete_subscriber(undef, $subscriber);
    
}
