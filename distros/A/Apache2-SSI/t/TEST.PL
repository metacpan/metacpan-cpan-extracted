#!perl
## See <http://perl.apache.org/docs/general/testing/testing.html>
use strict;
## use warnings FATAL => 'all';
use warnings;
use lib qw( lib );
use Apache::TestRunPerl ();

## Set the necessary environment variable we stored in Apache::TestConfig::Argv in our Makefile.PL
## We had to do a round-about way to achieve this, because there is no clean easy way with current Apache::Test version to achieve this
foreach my $k ( %Apache::TestConfig::Argv )
{
    if( substr( $k, 0, 1 ) eq '_' )
    {
        ## print( STDERR "Setting environment variable \"", substr( $k, 1 ), "\"\n" );
        $ENV{ substr( $k, 1 ) } = $Apache::TestConfig::Argv{ $k };
    }
}

Apache::TestRunPerl->new->run( @ARGV );

package Apache::TestRun;
