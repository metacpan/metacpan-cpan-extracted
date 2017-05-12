#!/usr/bin/perl -w

use strict;
use lib qw(t/lib);
use Test::More tests => 1;
use TestAppBuild;

clean_install();
set_module_dir( 't/Foo' );
run_build_pl();
run_build();
# HACK: ..../foo because install_base starts with '..'
run_build( 'install', 'destdir=../test_install/destdir/foo' );

check_tree( 't/test_install/destdir/test_install/simple',
            { 'cgi-bin/foo/foo.cgi'  => { executable => 1 },
              ( $^O eq 'MSWin32' ) ?
                  ( 'cgi-bin/foo/foo.cgi.bat' => { executable => 1 } ) :
                  ( ),
              'cgi-bin/foo/foo.conf' => {},
              'htdocs/index.html'    => {},
              'htdocs/robots.txt'    => {},
              'htdocs/.htaccess'     => {},
              'lib/MyFoo.pm'         => {},
              'lib/MyPod.pm'         => {},
              if_has_man( "man/man3/MyPod.$Config{man3ext}" => {} ),
              if_has_html( "html/site/lib/MyPod.html" => {} ),
              } );
