use strict;
use warnings;

use Test::More tests => 2;

{
    package MyTest::Process;
    use base qw/CouchDB::ExternalProcess/;

    sub _before {
        my ($self, $req) = @_;
        $req->{from_before} = 17;
        return $req;
    }

    sub foo :Action {
        my ($self, $req) = @_;
        return {
            json => {
                answer => $req->{from_before} + 12
            }
        };
    }

    1;
}

my $testProcess = MyTest::Process->new;

isa_ok($testProcess,'MyTest::Process');

my $requestJson = '{"path":["database","process","foo"]}';
my $responseJson = $testProcess->_process($requestJson);
my $response = $testProcess->jsonParser->jsonToObj($responseJson);

is($response->{json}->{answer},29, 'action using data from _before');
