use strict;

use Test::More tests => 3;

use_ok( 'Apache::Quota' );

foreach my $c ( qw ( DB_File::Lock BerkeleyDB ) )
{
    eval "require $c";

 SKIP:
    {
        skip "Cannot load Apache::Quota::$c unless $c is installed", 1
            if $@;

        use_ok( "Apache::Quota::$c" );
    }
}

