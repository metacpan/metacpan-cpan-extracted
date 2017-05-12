#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok('App::PS1');
    use_ok('App::PS1::Daemon');
    use_ok('App::PS1::Plugin::Branch');
    use_ok('App::PS1::Plugin::Date');
    use_ok('App::PS1::Plugin::Directory');
    use_ok('App::PS1::Plugin::Env');
    use_ok('App::PS1::Plugin::Face');
    use_ok('App::PS1::Plugin::Node');
    use_ok('App::PS1::Plugin::Perl');
    use_ok('App::PS1::Plugin::Processes');
    use_ok('App::PS1::Plugin::Ruby');
    use_ok('App::PS1::Plugin::Uptime');
}

diag( "Testing App::PS1 $App::PS1::VERSION, Perl $], $^X" );
done_testing();
