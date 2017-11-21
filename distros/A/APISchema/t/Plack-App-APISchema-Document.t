package t::Plack::App::APISchema::Document;
use lib '.';
use t::test;
use t::test::fixtures;
use t::test::InheritedDocument;
use Plack::Test;
use HTTP::Request::Common;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'Plack::App::APISchema::Document';
}

sub instantiate : Tests {
    my $schema = APISchema::Schema->new;
    my $app = Plack::App::APISchema::Document->new(schema => $schema);

    isa_ok $app, 'Plack::App::APISchema::Document';
    is $app->schema, $schema;
}

sub serve_document : Tests {
     my $schema = t::test::fixtures::prepare_bmi;
     my $app = Plack::App::APISchema::Document->new(schema => $schema)->to_app;

     subtest 'when valid request' => sub {
         test_psgi $app => sub {
             my $server = shift;
             my $res = $server->(GET '/');
             is $res->code, 200;
             is $res->header('content-type'), 'text/html; charset=utf-8';
             like $res->content, qr{<h3 id="toc_8"><a name="resource-figure"></a> <code>figure</code> : <code>object</code></h3>};
             done_testing;
         }
     };
}

sub mojibake : Tests {
    my $schema = t::test::fixtures::prepare_author;
    my $app = Plack::App::APISchema::Document->new(schema => $schema)->to_app;

     subtest 'when valid request' => sub {
         test_psgi $app => sub {
             my $server = shift;
             my $res = $server->(GET '/');
             is $res->code, 200;
             is $res->header('content-type'), 'text/html; charset=utf-8';
             like $res->content, qr{td>著者</td>};
             done_testing;
         }
     };
}

sub inheritable : Tests {
    my $schema = t::test::fixtures::prepare_bmi;
    my $app = t::test::InheritedDocument->new(schema => $schema)->to_app;

    subtest 'Document is inheritable' => sub {
        test_psgi $app => sub {
            my $server = shift;
            my $res = $server->(GET '/');
            is $res->code, 200;
            is $res->header('content-type'), 'text/html; charset=utf-8';
            like $res->content, qr{pink};
            done_testing;
        };
    };
}
