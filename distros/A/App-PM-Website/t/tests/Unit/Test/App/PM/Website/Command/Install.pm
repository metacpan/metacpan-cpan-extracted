use strict;
use warnings;

package Unit::Test::App::PM::Website::Command::Install;

use base 'Test::Class';
use Test::More;

sub load_test : Test(1)
{
    use_ok( 'App::PM::Website::Command::Install' );
}


1;
