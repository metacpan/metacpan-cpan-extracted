#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

our %default = (
    chef => "swedish",
);

{
    package MyApp;
    our @ISA = qw/Catalyst::Plugin::Session::Defaults Ancestor/;
    use NEXT;

    sub config { return { session => { defaults => \%::default } } };

    package Ancestor;
    sub initialize_session_data {
        return { moose => [ "elk" ] }
    }
}

use ok "Catalyst::Plugin::Session::Defaults";

can_ok("Catalyst::Plugin::Session::Defaults", "initialize_session_data");
can_ok("Catalyst::Plugin::Session::Defaults", "default_session_data");

is_deeply( MyApp->default_session_data, \%default, "default comes from config" );

is( MyApp->initialize_session_data->{chef}, "swedish", "default values" );
is( (my $prev = MyApp->initialize_session_data)->{moose}[0], "elk", "merged with existing ones" );

$default{moose}[0] = "cute";

is( MyApp->initialize_session_data->{moose}[0], "cute", "overrides work" );
is( $prev->{moose}[0], "elk", "The data is cloned, not shared" );

