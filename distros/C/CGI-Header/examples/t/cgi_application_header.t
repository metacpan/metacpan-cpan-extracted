use strict;
use warnings;
use Test::More tests => 3;
use Test::Output;

BEGIN {
    use_ok 'CGI::Application::Header';
}

my $header = CGI::Application::Header->new;

stdout_like { $header->finalize } qr{^Content-Type: };
stdout_like { $header->handler('redirect')->finalize } qr{^Status: 302 Found};
