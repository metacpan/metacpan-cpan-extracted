use strict;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;

use_ok 'Catmandu::Plack::unAPI';
new_ok 'Catmandu::Plack::unAPI';

my $app = Catmandu::Plack::unAPI->new(
    query => sub { $_[0] =~ /\d+/ ? { hello => 'world' } : undef }
);

test_psgi $app, sub {
    my $cb  = shift;
    
    my $res = $cb->(GET "/");
    is scalar (my @f = $res->content =~ /<format\s+name=["'](json|yaml)/gm), 
       2, 'default formats';
    
    $res = $cb->(GET "?id=123");
    like $res->content, qr{<formats\s+id=["']123["']>}m, "no format";
    is $res->code, 300, 'HTTP 300';

    $res = $cb->(GET "?id=0&format=yaml");
    is $res->content, "---\nhello: world\n", 'content';
    is $res->code, 200, 'HTTP 200';
    is $res->header('content-type'), 'text/yaml', 'YAML';

    $res = $cb->(GET "?id=abc&format=yaml");
    is $res->code, 404, 'HTTP 404';
};

done_testing;
