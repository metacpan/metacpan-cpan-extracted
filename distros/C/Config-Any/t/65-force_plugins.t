use strict;
use warnings;

use Test::More tests => 2;

use Config::Any;

{
    my $result = eval {
        Config::Any->load_files(
            { files => [ 't/conf/conf.pl' ], force_plugins => [ 'Config::Any::Perl' ] } );
    };

    ok( $result, 'config loaded' );
    ok( !$@, 'no error thrown' );
}
