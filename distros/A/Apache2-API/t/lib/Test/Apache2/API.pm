package Test::Apache2::API;
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use parent qw( Test::Apache2::Common );
    use Apache2::Connection ();
    use Apache2::Const -compile => qw( :common :http OK DECLINED );
    use Apache2::RequestIO ();
    use Apache2::RequestRec ();
    # so we can get the request as a string
    use Apache2::RequestUtil ();
    use APR::URI ();
    use Apache2::API;
    use Scalar::Util;
    # 2021-11-1T17:12:10+0900
    use Test::Time time => 1635754330;
    use constant HAS_SSL => ( $ENV{HTTPS} || ( defined( $ENV{SCRIPT_URI} ) && substr( lc( $ENV{SCRIPT_URI} ), 0, 5 ) eq 'https' ) ) ? 1 : 0;
};

use strict;
use warnings;

sub compression_threshold { return( shift->_test({ method => 'compression_threshold', expect => 102400 }) ); }

my $json = <<EOT;
{
    "debug": "true",
    "client_id": "d7024a37-f8d8-4d37-bbc4-5bd19429df8c",
    "total": 10.20,
}
EOT

sub decode_json { return( shift->_test({ method => 'compression_threshold', expect => sub
{
    my $ref = shift( @_ );
    return(0) if( ref( $ref ) ne 'HASH' );
    return( $ref->{debug} && $ref->{client_id} eq 'd7024a37-f8d8-4d37-bbc4-5bd19429df8c' && $ref->{total} == 10.20 );
}, args => [$json] }) ); }

sub encode_decode_url
{
    my $self = shift( @_ );
    my $class = ref( $self );
    my $api = $self->api;
    my $r = $self->request;
    my $debug = $self->debug;
    # Borrowed from URL::Encode
    my $UNRESERVED = "0123456789"
    . "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    . "abcdefghijklmnopqrstuvwxyz"
    . "_.~-";
    
    my @tests = (
        [ "",         "",     "empty string" ],
        [ "\x{00E5}", "%E5",  "U+00E5 in native encoding" ],
        [ $UNRESERVED, $UNRESERVED, "unreserved characters" ],
        [ " ", "+", "U+0020 SPACE" ]
    );
    
    for my $ord ( 0x00..0x1F, 0x21..0xFF )
    {
        my $chr = pack( 'C', $ord );
        next unless( index( $UNRESERVED, $chr ) < 0 );
        my $enc = sprintf( '%%%.2X', $ord );
        push @tests, [ $chr, $enc, sprintf( "ordinal %d", $ord ) ];
    }

    my $cnt = 0;
    foreach my $test ( @tests )
    {
        my( $expected, $encoded, $name ) = @$test;
        my $rv = $api->decode_url( $encoded ) eq $expected ? 1 : 0;
        $r->log_error( "$[class}: decode_url(): $name -> ", ( $rv ? 'ok' : 'not ok' ) ) if( $debug );
        $cnt++ if( $rv );
    }

    foreach my $test ( @tests )
    {
        my( $octets, $expected, $name ) = @$test;
        my $rv = $api->encode_url( $octets ) eq $expected ? 1 : 0;
        $r->log_error( "$[class}: encode_url(): $name -> ", ( $rv ? 'ok' : 'not ok' ) ) if( $debug );
        $cnt++ if( $rv );
    }
    return( $self->ok( $cnt == scalar( @tests ) ) );
}

my $jwt = q{eyJleHAiOjE2MzYwNzEwMzksImFsZyI6IkhTMjU2In0.eyJqdGkiOiJkMDg2Zjk0OS1mYWJmLTRiMzgtOTE1ZC1hMDJkNzM0Y2ZmNzAiLCJmaXJzdF9uYW1lIjoiSm9obiIsImlhdCI6MTYzNTk4NDYzOSwiYXpwIjoiNGQ0YWFiYWQtYmJiMy00ODgwLThlM2ItNTA0OWMwZTczNjBlIiwiaXNzIjoiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20iLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwibGFzdF9uYW1lIjoiRG9lIiwic3ViIjoiYXV0aHxlNzg5OTgyMi0wYzlkLTQyODctYjc4Ni02NTE3MjkyYTVlODIiLCJjbGllbnRfaWQiOiJiZTI3N2VkYi01MDgzLTRjMWEtYTM4MC03Y2ZhMTc5YzA2ZWQiLCJleHAiOjE2MzYwNzEwMzksImF1ZCI6IjRkNGFhYmFkLWJiYjMtNDg4MC04ZTNiLTUwNDljMGU3MzYwZSJ9.VSiSkGIh41xXIVKn9B6qGjfzcLlnJAZ9jGOPVgXASp0};
# Need to set the Authorization header in the test unit
# $r->authorization( "Bearer ${jwt}" );
sub auth { return( shift->_test({ method => 'get_auth_bearer', expect => $jwt }) ); }

sub header_datetime { return( shift->_test({ method => 'header_datetime', expect => 'Mon, 01 Nov 2021 08:12:10 GMT' }) ); }

sub is_perl_option_enabled { return( shift->_test({ method => 'is_perl_option_enabled', expect => 1, type => 'boolean', args => ['GlobalRequest'] }) ); }

sub json { return( shift->_test({ method => 'json', expect => sub
{
    my $json = shift( @_ );
    return( Scalar::Util::blessed( $json ) && 
               $json->isa( 'JSON' ) && 
               $json->canonical && 
               $json->get_relaxed && 
               $json->get_utf8 && 
               $json->get_allow_nonref && 
               $json->get_allow_blessed && 
               $json->get_convert_blessed );
}, args => [pretty => 1, ordered => 1, relaxed => 1, utf8 => 1, allow_nonref => 1, allow_blessed => 1, convert_blessed => 1] }) ); }

sub reply
{
    return( shift->api->reply( Apache2::Const::HTTP_OK => {
        message => "ok",
    }) );
}

sub server { return( shift->_test({ method => 'server', expect => 'Apache2::ServerRec', type => 'isa' }) ); }

sub server_version { return( shift->_test({ method => 'server_version', expect => 'version', type => 'isa' }) ); }

sub _target { return( shift->api ); }

1;
# NOTE: POD
# Use this to generate the tests list:
# egrep -E '^sub ' ./t/lib/Test/Apache2/API.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "=head2 $m\n"'
__END__

=encoding utf8

=head1 NAME

Test::Apache2::API - Apache2::API Testing Class

=head1 SYNOPSIS

In the Apache test conf:

    PerlModule Apache2::API
    PerlOptions +GlobalRequest
    PerlSetupEnv On
    <Directory "@documentroot@">
        SetHandler modperl
        PerlResponseHandler Test::Apache2::API
        AcceptPathInfo On
    </Directory>

In the test unit:

    use Apache::Test;
    use Apache::TestRequest;
    use HTTP::Request;

    my $hostport = Apache::TestRequest::hostport( $config ) || '';
    my( $host, $port ) = split( ':', ( $hostport ) );
    my $mp_host = 'www.example.org';
    Apache::TestRequest::user_agent(reset => 1, keep_alive => 1 );
    my $ua = Apache::TestRequest->new;
    # To get the fingerprint for the certificate in ./t/server.crt, do:
    # echo "sha1\$$(openssl x509 -noout -in ./t/server.crt -fingerprint -sha1|perl -pE 's/^.*Fingerprint=|(\w{2})(?:\:?|$)/$1/g')"
    $ua->ssl_opts(
        # SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, 
        # SSL_verify_mode => 0x00
        # verify_hostname => 0,
        SSL_fingerprint => 'sha1$DEE8650E44870896E821AAE4A5A24382174D100E',
        # SSL_version     => 'SSLv3',
        # SSL_verfifycn_name => 'localhost',
    );
    my $req = HTTP::Request->new( 'GET' => "${proto}://${hostport}/tests/api/some_method" );
    my $resp = $ua->request( $req );
    is( $resp->code, Apache2::Const::HTTP_OK, 'some test name' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a package for testing the L<Apache2::API> module under Apache2/modperl2

=head1 TESTS

The following tests are performed:

=head2 compression_threshold

=head2 decode_json

=head2 encode_decode_url

=head2 auth

=head2 header_datetime

=head2 is_perl_option_enabled

=head2 json

=head2 reply

=head2 server

=head2 server_version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API>, L<Apache::Test>, L<Apache::TestUtil>, L<Apache::TestRequest>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
