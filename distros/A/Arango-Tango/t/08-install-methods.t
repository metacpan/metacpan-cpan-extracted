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

# set_access_level has signature [ username, grant, database, ?collection ]
subtest "missing argument names the first missing required argument" => sub {
    my @cases = (
        [ [],             'username' ],
        [ ['u'],          'grant'    ],
        [ ['u', 'rw'],    'database' ],
    );
    for my $case (@cases) {
        my ($args, $missing) = @$case;
        is dies { $arango->set_access_level(@$args) }, "-1\n",
            "dies with " . scalar(@$args) . " argument(s)";
        is $arango->error, "Arango::Tango | set_access_level | Missing $missing",
            "reports '$missing' as missing";
    }
};

subtest "the optional argument is optional" => sub {
    is dies { $arango->set_access_level('u', 'rw', 'db') }, undef, "no error without it";
    is last_request(), [ PUT => 'http://h:1/_api/user/u/database/db/' ],
        "omitted optional argument is left out of the path";

    is dies { $arango->set_access_level('u', 'rw', 'db', 'col') }, undef, "no error with it";
    is last_request(), [ PUT => 'http://h:1/_api/user/u/database/db/col' ],
        "given optional argument is used";
};

subtest "no package global is clobbered" => sub {
    local $Arango::Tango::API::a = 'sentinel';
    $arango->set_access_level('u', 'rw', 'db', 'col');
    is $Arango::Tango::API::a, 'sentinel', 'optional-argument parsing leaves $a alone';
};

subtest "error is visible through the documented accessor of sub-objects" => sub {
    my $col = Arango::Tango::Collection->_new( arango => $arango, database => 'db', name => 'col' );
    is dies { $col->document() }, "-1\n", "dies without the key";
    is $col->error, "Arango::Tango | document | Missing key",
        "error can be read with \$collection->error";
};

done_testing;
