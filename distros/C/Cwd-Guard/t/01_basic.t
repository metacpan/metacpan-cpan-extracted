use strict;
use Test::More;

use Cwd::Guard qw/cwd_guard/;
use Cwd qw/getcwd/;
use File::Basename;


my $dir = getcwd();
{
    my $guard = cwd_guard( dirname(__FILE__) );
    ok($guard);
    isnt( $dir, getcwd() );
}

is($dir, getcwd() );

{
    my $guard = cwd_guard( __FILE__ ); # fail
    ok(!$guard);
    ok($Cwd::Guard::Error);
}

done_testing();

