use strict;
use warnings;

use Test::More tests => 4;

{
    package MyTest::Process;
    use base qw/CouchDB::ExternalProcess/;

    sub foo :Action {
        return {
            json => {
                foo => "bar"
            }
        };
    }

    sub bar :Action {
        my ($self, $req) = @_;
        return {
            body => "name is [".$req->{query}->{name}."]"
        };
    }

    1;
}

my $testProcess = MyTest::Process->new;

isa_ok($testProcess,'MyTest::Process');

my $badRequestJson = '{"path":["pants"]}';
my $badResponseJson = $testProcess->_process($badRequestJson);
my $badResponse = $testProcess->jsonParser->jsonToObj($badResponseJson);
like($badResponse->{json}->{error}, qr|not defined|, "Bad Response Error Message");

my $goodRequestJson = '{"path":["database","process","foo"]}';
my $goodResponseJson = $testProcess->_process($goodRequestJson);
my $goodResponse = $testProcess->jsonParser->jsonToObj($goodResponseJson);
is($goodResponse->{json}->{foo}, "bar","Good Response Data");

my $queryRequestJson = '{"path":["database","process","bar"],"query":{"name":"frank"}}';
my $queryResponseJson = $testProcess->_process($queryRequestJson);
my $queryResponse = $testProcess->jsonParser->jsonToObj($queryResponseJson);
is($queryResponse->{body}, "name is [frank]","Query Response With Name");
