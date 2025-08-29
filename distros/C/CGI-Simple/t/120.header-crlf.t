use strict;
use Test::More tests => 9;
use Test::Exception;
use CGI::Simple;

my $cgi = CGI::Simple->new;

my $CRLF = $cgi->crlf;

my %possible_crlf = (
    '\n'       => "\n",
    '\r\n'     => "\r\n",
    '\015\012' => "\015\012",
);
for my $k (sort keys %possible_crlf) {
    is(
        $cgi->header( '-Test' => "test$possible_crlf{$k} part" ),
        "Test: test part"
        . $CRLF
        . 'Content-Type: text/html; charset=ISO-8859-1'
        . $CRLF
        . $CRLF,
        "header value with $k + space drops the $k and is valid"
    );

    throws_ok { $cgi->header( '-Test' => "test$possible_crlf{$k}$possible_crlf{$k} part" ) }
    qr/Invalid header value contains a newline not followed by whitespace: test="test/,
        'invalid CRLF caught for double ' . $k;
        throws_ok { $cgi->header( '-Test' => "test$possible_crlf{$k}part" ) }
        qr/Invalid header value contains a newline not followed by whitespace: test="test/,
        "invalid $k caught not followed by whitespace";
}
