use strict;
use warnings;

package Unit::Test::App::PM::Website::Command::Build;

use base 'Test::Class';
use Test::More;

sub load_test : Test(1)
{
    use_ok( 'App::PM::Website::Command::Build' );
}


1;
