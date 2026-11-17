# -*- cperl -*-
use Arango::Tango;
use Arango::Tango::Collection;
use Test2::V0;

# Offline test: no ArangoDB server required.
package FakeHTTP {
    sub new { bless { requests => [] }, shift }
    sub request {
        my ($self, $method, $url) = @_;
        push @{ $self->{requests} }, [ $method, $url ];
        return { success => 1, status => 200, content => '{"error":false}' };
    }
}

my $http   = FakeHTTP->new;
my $arango = Arango::Tango->new( host => 'h', port => 1, username => 'u', password => 'p' );
$arango->{http} = $http;

sub last_request { return $http->{requests}[-1] }

$arango->delete_user('a/b?c d');
is last_request(), [ DELETE => 'http://h:1/_api/user/a%2Fb%3Fc%20d' ],
    "user name is escaped in the path";

$arango->delete_database('..');
is last_request(), [ DELETE => 'http://h:1/_api/database/..' ],
    "plain dots are unreserved";

my $col = Arango::Tango::Collection->_new( arango => $arango, database => 'my db', name => 'col' );
$col->document('x/../y?z=1#f');
is last_request(), [ GET => 'http://h:1/_db/my%20db/_api/document/col/x%2F..%2Fy%3Fz%3D1%23f' ],
    "database and document key are escaped";

$col->delete_document('k');
is last_request(), [ DELETE => 'http://h:1/_db/my%20db/_api/document/col/k' ],
    "ordinary keys are unchanged";

$arango->delete_user("caf\x{e9}");
is last_request(), [ DELETE => 'http://h:1/_api/user/caf%C3%A9' ],
    "non-ASCII is UTF-8 percent-encoded";

$arango->delete_user('{username}');
is last_request(), [ DELETE => 'http://h:1/_api/user/%7Busername%7D' ],
    "braces in a value are escaped, not re-expanded as placeholders";

$arango->__api(
    { rest => [ get => '_api/x' ], schema => { q => { type => 'string' } } },
    { q => 'a&b=c+d e' },
);
is last_request(), [ GET => 'http://h:1/_api/x?q=a%26b%3Dc%2Bd%20e' ],
    "GET query values have reserved characters escaped";

done_testing;
