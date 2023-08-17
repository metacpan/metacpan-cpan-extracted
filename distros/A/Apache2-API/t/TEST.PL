#!perl
# See <http://perl.apache.org/docs/general/testing/testing.html>
use strict;
# use warnings FATAL => 'all';
use warnings;
use lib qw( lib );
use Apache::TestRunPerl ();

foreach my $k ( %Apache::TestConfig::Argv )
{
    if( substr( $k, 0, 1 ) eq '_' )
    {
        # print( STDERR "Setting environment variable \"", substr( $k, 1 ), "\"\n" );
        $ENV{ substr( $k, 1 ) } = $Apache::TestConfig::Argv{ $k };
    }
}

Apache::TestRunPerl->new->run( @ARGV );

package Apache::TestRun;
