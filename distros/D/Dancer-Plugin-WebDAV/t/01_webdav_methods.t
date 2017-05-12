use Dancer ':tests', ':syntax';
use Dancer::Plugin::WebDAV;
use Dancer::Test;
use Test::More;

my @methods = qw(
    propfind
    proppatch
    mkcol
    copy
    move
    lock
    unlock
);

propfind    "/" => sub { "propfind" };
proppatch   "/" => sub { "proppatch" };
mkcol       "/" => sub { "mkcol" };
copy        "/" => sub { "copy" };
move        "/" => sub { "move" };
lock        "/" => sub { "lock" };
unlock      "/" => sub { "unlock" };

for my $m (@methods) {
    route_exists          [ $m => "/" ], "route handler found for method $m";
    response_status_is    [ $m => "/" ], 200, "response status is 200 for $m";
    response_content_like [ $m => "/" ], qr{$m}, "response content is OK for $m";
}

done_testing;
