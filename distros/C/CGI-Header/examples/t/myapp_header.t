use strict;
use warnings;
use Test::More tests => 3;
use Test::Output;

BEGIN {
    use_ok 'MyApp::Header';
}

my $header = MyApp::Header->new;

is $header->cookies( ID => 123456 ), $header;
stdout_like { $header->finalize } qr{Set-Cookie: ID=123456};
