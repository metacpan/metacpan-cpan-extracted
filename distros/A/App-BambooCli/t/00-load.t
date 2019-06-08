#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok('App::BambooCli');
    use_ok('App::BambooCli::Config');
    use_ok('App::BambooCli::Command');
    use_ok('App::BambooCli::Command::Projects');
    use_ok('App::BambooCli::Command::Project');
    use_ok('App::BambooCli::Command::Plans');
}

diag( "Testing App::BambooCli $App::BambooCli::VERSION, Perl $], $^X" );
done_testing();
