# -*- cperl -*-
use Arango::Tango;
use JSON;
use Test2::V0;

# Offline test: no ArangoDB server required.
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

sub last_request { return $http->{requests}[-1] }

# The schema below deliberately *declares* the internal key, so that it is
# only the removal done by __api itself (and not the schema filtering
# unknown properties) that keeps it out of the request.
my %schema = (
    q               => { type => 'string' },
    _url_parameters => { type => 'object' },
);

$arango->__api(
    { rest => [ post => '_api/x' ], schema => \%schema },
    { q => 'v', _url_parameters => { type => 'documents' } },
);
is decode_json( last_request()->[2]{content} ), { q => 'v' },
    "_url_parameters does not leak into the JSON body";

$arango->__api(
    { rest => [ get => '_api/x' ], schema => \%schema },
    { q => 'v', _url_parameters => { type => 'documents' } },
);
is [ @{ last_request() }[0, 1] ], [ GET => 'http://h:1/_api/x?q=v' ],
    "_url_parameters does not leak into the GET query string";

# The internal keys must still do their job.
$arango->__api(
    { rest      => [ post => '_api/y' ],
      url_schema => { type => { type => 'string' } } },
    { _body => [ { a => 1 } ], _url_parameters => { type => 'documents' } },
);
is last_request(), [ POST => 'http://h:1/_api/y?type=documents', { content => '[{"a":1}]' } ],
    "_url_parameters still goes to the query string and _body to the body";

done_testing;
