#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok('App::VTide');
    use_ok('App::VTide::Command');
    use_ok('App::VTide::Command::Conf');
    use_ok('App::VTide::Command::Edit');
    use_ok('App::VTide::Command::Grep');
    use_ok('App::VTide::Command::Help');
    use_ok('App::VTide::Command::History');
    use_ok('App::VTide::Command::Init');
    use_ok('App::VTide::Command::List');
    use_ok('App::VTide::Command::NewWindow');
    use_ok('App::VTide::Command::Recent');
    use_ok('App::VTide::Command::Refresh');
    use_ok('App::VTide::Command::Run');
    use_ok('App::VTide::Command::Save');
    use_ok('App::VTide::Command::Sessions');
    use_ok('App::VTide::Command::Split');
    use_ok('App::VTide::Command::Start');
    use_ok('App::VTide::Command::Who');
    use_ok('App::VTide::Config');
    use_ok('App::VTide::Hooks');
    use_ok('App::VTide::Sessions');
}

diag("Testing App::VTide $App::VTide::VERSION, Perl $], $^X");
done_testing();
