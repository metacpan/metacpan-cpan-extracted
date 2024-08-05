# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG @modules );
    use Test::More qw( no_plan );
    use File::Find;
    our @modules;
    File::Find::find(sub
    {
        return(1) unless( /\.pm$/ );
        # print( "Checking file '$_' ($File::Find::name)\n" );
        $_ = $File::Find::name;
        s,^./lib/,,;
        s,\.pm$,,;
        s,/,::,g;
        push( @modules, $_ );
    }, qw( ./lib ) );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    for( sort( @modules ) )
    {
        diag( "Checking module $_" ) if( $DEBUG );
        use_ok( $_ );
    }
};

done_testing();

# To generate the list of modules:
# for m in `find ./lib -type f -name "*.pm"`; do echo $m | perl -pe 's,./lib/,,; s,\.pm$,,; s/\//::/g; s,^(.*?)$,use_ok\( "$1" \)\;,'; done
