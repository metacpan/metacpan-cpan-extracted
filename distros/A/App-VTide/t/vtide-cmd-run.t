#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use App::VTide;

my $module = 'App::VTide::Command::Run';
use_ok( $module );

my $vtide = App::VTide->new;

params();

done_testing();

sub params {
    my $cmd = $module->new(
        vtide => $vtide,
    );
    ok $cmd, 'Create new cmd';
}
