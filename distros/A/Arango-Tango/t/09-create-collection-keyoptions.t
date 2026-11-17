# -*- cperl -*-
use Arango::Tango;
use Arango::Tango::Database;
use JSON;
use Test2::V0;

# Offline test: no ArangoDB server required.
# Regression test for #19: the keyOptions sub-schema was declared with
# 'params' instead of 'properties', so every keyOptions sub-field was lost.
package FakeHTTP {
    sub new { bless { requests => [] }, shift }
    sub request {
        my ($self, $method, $url, $opts) = @_;
        push @{ $self->{requests} }, [ $method, $url, $opts ];
        return { success => 1, status => 200, content => '{"error":false}' };
    }
}

my $http   = FakeHTTP->new;
my $arango = Arango::Tango->new( host => 'h', port => 1, username => 'u', password => 'p' );
$arango->{http} = $http;
my $db = Arango::Tango::Database->_new( arango => $arango, name => 'db' );

sub sent_body { return decode_json( $http->{requests}[-1][2]{content} ) }

$db->create_collection('col', keyOptions => {
    type          => 'autoincrement',
    increment     => 5,
    offset        => 2,
    allowUserKeys => JSON::true,
});
is sent_body()->{keyOptions},
    { type => 'autoincrement', increment => 5, offset => 2, allowUserKeys => T() },
    "keyOptions sub-fields are sent";

$db->create_collection('col', keyOptions => { type => 'uuid', bogus => 1 });
is sent_body()->{keyOptions}, { type => 'uuid' },
    "unknown keyOptions sub-fields are removed";

$db->create_collection('col', keyOptions => { type => 'nonsense' });
is sent_body()->{keyOptions}, { type => 'traditional' },
    "invalid keyOptions values are replaced by their default";

done_testing;
