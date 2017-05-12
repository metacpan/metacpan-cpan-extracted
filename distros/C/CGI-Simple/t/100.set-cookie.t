use strict;
use Test::More tests => 1;
use CGI::Simple;

my $cgi = CGI::Simple->new;

like(
  $cgi->header(
    '-content-type', 'foo/fum', '-set-cookie', [ 'a=b', 'b=c' ]
  ),
  qr/Set-cookie: a=b\s+Set-cookie: b=c/si,
  'Set-Cookie'
);
