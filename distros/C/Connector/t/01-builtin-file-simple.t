# Tests for Connector::Builtin::File::Simple
#

use strict;
use warnings;
use English;

use Test::More tests => 7;

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Builtin::File::Simple' );
}

require_ok( 'Connector::Builtin::File::Simple' );


# diag "Connector::Proxy::File::Simple tests\n";
###########################################################################
my $conn = Connector::Builtin::File::Simple->new(
    {
	LOCATION  => 't/config/file',
    });

is($conn->get(), 'test');
is($conn->get('foo'), 'test');
is($conn->get('bar'), 'test');

ok ($conn->exists(''), 'Always exists');
ok ($conn->exists( [ ] ), 'Leaf Exists Array');