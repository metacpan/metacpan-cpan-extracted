# Tests for Connector::Builtin::File::Simple
#

use strict;
use warnings;
use English;
use Log::Log4perl qw(:easy);

use Test::More tests => 3;

Log::Log4perl->easy_init($ERROR);

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::HTTP' );
}

require_ok( 'Connector::Proxy::HTTP' );


# diag "Connector::Proxy::File::Simple tests\n";
###########################################################################
my $conn = Connector::Proxy::HTTP->new({
	LOCATION  => 'https://raw.githubusercontent.com/mrscotty/connector/master/t/config/file',
});

is($conn->get(), 'test');

# TODO - Tests need for SSL stuff