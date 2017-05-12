#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Getopt::Alt;

my $module = 'App::VTide';
use_ok( $module );

my $opt = Getopt::Alt->new;

new();
sub_commands();

done_testing();

sub new {
    my $conf = $module->new();
    ok $conf, 'Create new object';
}

sub sub_commands {
    my $conf = $module->new();
    my $run = $conf->load_subcommand('run', $opt);
    ok $run, 'Get sub command object';
    isa_ok $run, 'App::VTide::Command::Run';

}
