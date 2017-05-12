#!perl -T

use strict;
use warnings;
use lib ( './t' );

use Test::More qw/no_plan/;

{
    use TestApp;
    my $test = TestApp->new(
        PARAMS => {
            'config_dir'    => './t',
            'config_files'  => [ 'basic.pl' ],
            'config_params' => {
                'use_ext'   => 1,
            },
            'config_names'  => {
                'test'      => {
                    'config_dir'   => './t/named',
                    'config_files' => [ 'named.pl' ],
                }
            }
        }
    );

    ## check param()
    ok( $test->config( 'name' ) eq 'TestApp', 'config(\'name\') shall return \'TestApp\'' );
    
    ## check deep => buried => key
    ok( $test->config( 'key' ) eq 'value', 'config(\'key\') shall return \'value\'' );
    
    ## check section()
    my $section = $test->config_section('Component');

    ok( ref $section eq 'HASH', 'config_section(\'Component\') shall return a hashref' );
    
    ## check config_read()
    my $cfg = $test->config_read;
    ok( ref $cfg eq 'HASH', 'config_read() shall return a hashref' );

    ## check for attribute 'name' in return value of config_read()
    is( $cfg->{ name }, 'TestApp', 'expected key [name] was found and has the right content' );
    
    ## change config
    ok( $test->config_name( 'test' ), 'change config name to \'test\'' );
    
    ok( $test->config( 'name' ) eq 'TestAppNamed', 'config(\'name\') shall now return \'TestAppNamed\'' );
}
