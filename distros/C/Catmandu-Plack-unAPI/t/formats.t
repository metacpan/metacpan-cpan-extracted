use strict;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Catmandu::Plack::unAPI;

{
    package Catmandu::Exporter::PlainText;
    use Moo;
    with 'Catmandu::Exporter';
    sub add {
        my ($self, $data) = @_;
        print {$self->fh} join('=', %$data) if $data;
    }
}

my $app = Catmandu::Plack::unAPI->new(
    query => sub { $_[0] > 0 ? { answer => $_[0] } : 'id must be positive' },
    formats => {
        plain => {
            type     => 'text/plain',
            exporter => [ 'PlainText', fix => 'reject all_match(answer,23)' ]
        }
    }
)->to_app;

test_psgi $app, sub {
    my $cb  = shift;

    my $res = $cb->(GET "/");
    is_deeply [ my @f = $res->content =~ /<format\s+name=["']([^"']+)/gm ], 
              ['plain'], 'custom format';

    $res = $cb->(GET "?id=42&format=plain");
    is $res->code, 200, '200 Ok';
    is $res->content, "answer=42", 'content';
    is $res->header('content-type'), 'text/plain', 'type';

    $res = $cb->(GET "?id=23&format=plain");
    is $res->code, 200, '200 Ok'; # FIXME? Item was rejected!
    is $res->content, '';

    $res = $cb->(GET "?id=-23&format=plain");
    is $res->code, 400, '400 Bad Request';
    is $res->content, 'id must be positive';
};   


$app = Catmandu::Plack::unAPI->new(
    query => sub { { foo => 'bar' } },
    formats => {
        plain => {
            type => 'text/plain',
            exporter => 'PlainText' # plain string
        }
    }
);
test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "?id=foo&format=plain");
    is $res->code, 200;
    is $res->content, "foo=bar", 'content';
};

done_testing;
