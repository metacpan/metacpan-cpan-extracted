# Tests for Connector::Proxy::Config::Std
#

use strict;
use warnings;
use English;
use Path::Class;

use Data::Dumper;
use Log::Log4perl qw(:easy);

use Test::More tests => 11;

Log::Log4perl->easy_init($ERROR);

BEGIN {
    use_ok( 'Connector::Builtin::Memory' );
    use_ok( 'Connector::Proxy::YAML' );
    use_ok( 'Connector::Multi' );
}

require_ok( 'Connector::Builtin::Memory' );
require_ok( 'Connector::Proxy::YAML' );
require_ok( 'Connector::Multi' );

my $base = Connector::Builtin::Memory->new({
});

$base->set('this.path', "bar");
is($base->get('this.path'), 'bar', 'Base Works');

my $sub = Connector::Proxy::YAML->new({
    LOCATION  => 't/config/config.yaml',
});

$base->set('that.path', $sub);
is($sub->get('test.entry.foo'), '1234', 'Sub Works');

# Load Multi
my $conn = Connector::Multi->new( {
        BASECONNECTOR => $base,
});

is($conn->get('this.path'), 'bar', 'Base vie Multi Works');
is($conn->get('that.path.test.entry.foo'), '1234', 'Sub via Multi Works');
is($conn->get('that.path.test.entry.bar'), '5678', 'Sub via Multi Works');
