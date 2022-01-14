use strict;
use Test::More tests => 2;
use Test::Exception;
use CGI::Simple;

my $cgi = CGI::Simple->new;

my $CRLF = $cgi->crlf;

is( $cgi->header( '-Test' => "test$CRLF part" ),
    "Test: test part"
        . $CRLF
        . 'Content-Type: text/html; charset=ISO-8859-1'
        . $CRLF
        . $CRLF
);

throws_ok { $cgi->header( '-Test' => "test$CRLF$CRLF part" ) }
qr/Invalid header value contains a newline not followed by whitespace: test="test/,
    'invalid CRLF caught';
