use Test::More tests => 3;
use strict;
use warnings;

use CGI::Simple;
# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'POST';
$ENV{QUERY_STRING}    = '';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'upload.info.com';
$ENV{CONTENT_TYPE}
 = q{multipart/form-data; boundary=---------------------------10263292819275730631136676268};
$ENV{REQUEST_URI}
 = "$ENV{SCRIPT_NAME}$ENV{PATH_INFO}?$ENV{QUERY_STRING}";
$ENV{HTTP_LOVE} = 'true';

my $body = <<EOF;
-----------------------------10263292819275730631136676268\r
Content-Disposition: form-data; name="rm"\r
\r
index\r
-----------------------------10263292819275730631136676268\r
Content-Disposition: form-data; name="file0"; filename="image.png"\r
Content-Type: image/png\r
\r
fake\r
-----------------------------10263292819275730631136676268\r
Content-Disposition: form-data; name="file1"; filename="image.svg"\r
Content-Type: image/svg+xml\r
\r
<svg>fake</svg>\r
-----------------------------10263292819275730631136676268\r
Content-Disposition: form-data; name="file2"; filename="spreadsheet.xls"\r 
Content-Type: application/vnd.ms-excel\r
\r
fake\r
-----------------------------10263292819275730631136676268--\r

EOF
$ENV{CONTENT_LENGTH} = length $body;

my $h;
if ("$]" < 5.008) {
  require File::Temp;
  $h = File::Temp->new(TEMPLATE => 'CGI-Simple-upload_info-XXXXXX', TMPDIR => 1);
  $h->print($body);
  $h->seek(0, 0);
}
else {
  open $h, '<', \$body;
}
my $q = CGI::Simple->new( $h );
ok( $q->upload_info( $q->param( 'file0' ), 'mime' ) eq 'image/png',
  'Guess mime for  image/png' );
ok( $q->upload_info( $q->param( 'file1' ), 'mime' ) eq 'image/svg+xml',
  'Guess mime for  image/svg+xml' );
ok(
  $q->upload_info( $q->param( 'file2' ), 'mime' ) eq
   'application/vnd.ms-excel',
  'Guess mime for  application/vnd.ms-excel'
);

#2010-03-19 by Krasimir Berov, based on 041.multipart.t

