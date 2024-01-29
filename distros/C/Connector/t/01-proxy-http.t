# Tests for Connector::Builtin::File::Simple
#

use strict;
use warnings;
use English;
use Log::Log4perl qw(:easy);

use Test::More tests => 7;

Log::Log4perl->easy_init($ERROR);

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::HTTP' );
}

require_ok( 'Connector::Proxy::HTTP' );


# diag "Connector::Proxy::File::Simple tests\n";
###########################################################################
my $conn = Connector::Proxy::HTTP->new({
	LOCATION  => 'https://raw.githubusercontent.com/whiterabbitsecurity/connector/master/t/config/file',
});

is($conn->get(), 'test');

$conn = Connector::Proxy::HTTP->new({
	LOCATION  => 'https://raw.githubusercontent.com/whiterabbitsecurity/connector/master/t/config/',
});

is($conn->get('file'), 'test');

$conn = Connector::Proxy::HTTP->new({
	LOCATION  => 'https://raw.githubusercontent.com/whiterabbitsecurity/connector/',
    path => '[% ARGS.0 %]/t/config/[% ARGS.1 %]'
});

is($conn->get('master.file'), 'test');

$conn = Connector::Proxy::HTTP->new({
	LOCATION  => 'https://raw.githubusercontent.com/whiterabbitsecurity/connector/master/t/config/',
    file => '[% ARGS.0 %]'
});

is($conn->get('file'), 'test');

$conn->query_param({
    param1 => 'foo/bar',
    param2 => undef,
});
is($conn->get('file'), 'test');