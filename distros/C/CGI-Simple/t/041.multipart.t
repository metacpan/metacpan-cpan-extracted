use strict;
use warnings;
use Test::More tests => 6;
use Test::NoWarnings;
use Config;

use CGI::Simple ( -default );

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'POST';
$ENV{QUERY_STRING}    = '';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'the.good.ship.lollypop.com';
$ENV{CONTENT_TYPE}
 = q{multipart/form-data; boundary=---------------------------10263292819275730631136676268};
$ENV{REQUEST_URI}
 = "$ENV{SCRIPT_NAME}$ENV{PATH_INFO}?$ENV{QUERY_STRING}";
$ENV{HTTP_LOVE} = 'true';

my $body = <<EOF;
-----------------------------10263292819275730631136676268\r
Content-Disposition: form-data; name="action"\r
\r
reply\r
-----------------------------10263292819275730631136676268\r
Content-Disposition: form-data; name="body"\r
\r
asdfasdf\r
-----------------------------10263292819275730631136676268\r
Content-Disposition: form-data; name="send_action"\r
\r
Reply\r
-----------------------------10263292819275730631136676268--\r
EOF
$ENV{CONTENT_LENGTH} = length $body;

my $h;
if ("$]" < 5.008) {
  require File::Temp;
  $h = File::Temp->new(TEMPLATE => 'CGI-Simple-multipart-XXXXXX', TMPDIR => 1);
  $h->print($body);
  $h->seek(0, 0);
}
else {
  open $h, '<', \$body;
}
my $q = CGI::Simple->new( $h );
ok( $q, "CGI::Simple::new()" );
is_deeply(
  [ $q->param ],
  [qw(action body send_action)],
  'list of params'
);
is( $q->param( 'action' ),      'reply',    'reply param' );
is( $q->param( 'body' ),        'asdfasdf', 'body param' );
is( $q->param( 'send_action' ), 'Reply',    'send_action param' );
