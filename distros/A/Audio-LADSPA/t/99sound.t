#!/usr/bin/perl -w
use strict;

use Test::More tests => 13;
require "t/util.pl";


SKIP: {
    skip("No Audio::Play installed", 13) unless eval { require Audio::Play; 1; };

    use_ok('Audio::LADSPA::Network');
    use_ok('Audio::LADSPA::Plugin::Play');
    use_ok('Audio::LADSPA::Plugin::Sequencer4');

    my $net = Audio::LADSPA::Network->new(buffer_size => 100);
    ok($net, "instantiation");
    my $seq = $net->add_plugin('Audio::LADSPA::Plugin::Sequencer4');
    ok($seq, "adding sequencer");

SKIP: {
        skip("No SDK installed", 8) unless sdk_installed();
        my $sine = $net->add_plugin(id => 1047);
        ok($sine, "add sine plugin");

        my $delay = $net->add_plugin(id => 1043);
        ok($delay, "add delay plugin");

        my $play = $net->add_plugin('Audio::LADSPA::Plugin::Play');
        ok($play, "add player");

        ok(
            $net->connect(
                $seq,  'Frequency',
                $sine, 'Frequency (Hz)',
                "connect sequencer"
            )
        );

        ok($net->connect($sine, 'Output', $delay, 'Input'), "connection ok");

        ok($net->connect($delay, 'Output', $play, 'Input'), "connection ok2");

        is(
            $delay->get_buffer('Output'),
            $play->get_buffer('Input'),
            "really connected"
        );

        $sine->set(Amplitude => 1);    # set amp

        $delay->set('Delay (Seconds)' => 0.5);
        $delay->set('Dry/Wet Balance' => 0.3);

        $seq->set('Step 1',   70);
        $seq->set('Step 2',   82);
        $seq->set('Step 3',   96);
        $seq->set('Step 4',   108);
        $seq->set('Run/Step', 50);

        ok(1, "set smoke");

        for (0 .. 500) {
            $net->run(100);
        }
        $sine->set(Amplitude => 0);    # silence sine wave

        for (0 .. 800) {
            $net->run(100);
        }

    }
}

