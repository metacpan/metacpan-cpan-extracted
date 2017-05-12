#!/usr/bin/env perl

use Test::More tests => 14;

BEGIN {
    require_ok('Carp');
    use_ok('CGI');
    require_ok('CGI::Carp');
    use_ok('File::Spec');
    use_ok('File::Find');
    use_ok('HTML::Template');
    use_ok('Getopt::Long');
    use_ok('File::Path');
    use_ok('File::Copy');
    use_ok( 'App::ZofCMS' );
    use_ok( 'App::ZofCMS::Config' );
    use_ok( 'App::ZofCMS::Template' );
    use_ok( 'App::ZofCMS::Output' );
    use_ok( 'App::ZofCMS::Plugin' );
}

diag( "Testing App::ZofCMS $App::ZofCMS::VERSION, Perl $], $^X" );
