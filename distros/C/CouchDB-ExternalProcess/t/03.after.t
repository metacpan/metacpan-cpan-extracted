use strict;
use warnings;

use Test::More tests => 2;

{
    package MyTest::Process;
    use base qw/CouchDB::ExternalProcess/;

    sub _after {
        my ($self, $resp) = @_;
        $resp->{json}->{answer} += 5;
        return $resp;
    }

    sub foo :Action {
        my ($self, $req) = @_;
        return {
            json => {
                answer => 7
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

is($response->{json}->{answer},12, 'action data modified by _after');
