package Test::Apache2::API::Request;
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
    use Apache::TestConfig;
    use APR::URI ();
    use Apache2::API;
    use Scalar::Util;
    # 2021-11-1T17:12:10+0900
    use Test::Time time => 1635754330;
    use constant HAS_SSL => ( $ENV{HTTPS} || ( defined( $ENV{SCRIPT_URI} ) && substr( lc( $ENV{SCRIPT_URI} ), 0, 5 ) eq 'https' ) ) ? 1 : 0;
};

use strict;
use warnings;
our $config = Apache::TestConfig->thaw->httpd_config;
our $port = $config->{vars}->{port} || 0;

sub aborted { return( shift->_test({ method => 'aborted', expect => 0, type => 'boolean' }) ); }

# text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
# application/json; version=1.0; charset=utf-8, text/javascript, */*
sub accept { return( shift->_test({ method => 'accept', expect => 'application/json; version=1.0; charset=utf-8, text/javascript, */*' }) ); }

# application/json; version=1.0; charset=utf-8
sub accept_charset { return( shift->_test({ method => 'accept_charset', expect => 'utf-8' }) ); }

# gzip, deflate;q=1.0, *;q=0.5
# gzip, deflate, br
sub accept_encoding { return( shift->_test({ method => 'accept_encoding', expect => 'gzip, deflate, br' }) ); }

sub accept_language { return( shift->_test({ method => 'accept_language', expect => 'en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2' }) ); }

# application/json
sub accept_type { return( shift->_test({ method => 'accept_type', expect => 'application/json' }) ); }

# application/json; version=1.0; charset=utf-8
# sub accept_version { return( shift->_test({ method => 'accept_version', expect => '1.0' }) ); }
sub accept_version { return( shift->_test({ method => 'accept_version', expect => '1.0' }) ); }

# Check array reference of acceptable types:
# application/json; version=1.0; charset=utf-8, text/javascript, */*
sub acceptable { return( shift->_test({ method => 'acceptable', expect => sub
{
    my $acceptable = shift( @_ );
    my $opts = shift( @_ );
    my $cnt = 0;
    $opts->{log}->( "\$acceptable is '", ( $acceptable // 'undef' ), "' and contains: ", ( Scalar::Util::reftype( $acceptable ) eq 'ARRAY' ? join( ', ', @$acceptable ) : 'not an array' ) );
    $cnt++ if( Scalar::Util::reftype( $acceptable // '' ) eq 'ARRAY' );
    $cnt++ if( scalar( @$acceptable ) == 3 );
    $cnt++ if( $acceptable->[0] eq 'application/json' && $acceptable->[1] eq 'text/javascript' && $acceptable->[2] eq '*/*' );
    return( $cnt == 3 );
} }) ); }

# application/json; charset=utf-8; version=2, text/javascript, */*
sub acceptables { return( shift->_test({ method => 'acceptables', expect => sub
{
    my $ref = shift( @_ );
    my $opts = shift( @_ );
    my $cnt = 0;
    if( Scalar::Util::blessed( $ref // '' ) &&
        $ref->isa( 'Module::Generic::Array' ) )
    {
        $cnt++ if( scalar( @$ref ) == 3 );
        my $def = $ref->[0];
        if( Scalar::Util::blessed( $def // '' ) && $def->isa( 'Module::Generic::HeaderValue' ) )
        {
            $opts->{log}->( "\$ref->[0] value is '", $def->value->first, "' and charset is '", $def->param( 'charset' ), "' and version is '", $def->param( 'version' ), "'" );
            if( $def->value->first eq 'application/json' && 
                $def->param( 'charset' ) eq 'utf-8' &&
                $def->param( 'version' ) == 2 )
            {
                $cnt++;
            }
        }
        else
        {
            $opts->{log}->( "\$ref->[0] is not an Module::Generic::HeaderValue object." );
        }
        $cnt++ if( Scalar::Util::blessed( $ref->[1] ) && $ref->[1]->isa( 'Module::Generic::HeaderValue' ) && $ref->[1]->value->first eq 'text/javascript' );
    }
} }) ); }

# The allowed methods, GET, POST, PUT, OPTIONS, HEAD, etc
sub allowed { return( shift->_test({ method => 'allowed', expect => sub
{
    my $bitmask = shift( @_ );
    my $opts = shift( @_ );
    my $self = $opts->{object};
    my $req = $self->api->request;
    my $r = $self->_request;
    my $cnt = 0;
    $opts->{log}->( "\$bitmask is '$bitmask'" );
    $opts->{log}->( "\$req->method_number = '" . $req->method_number . "'" );
    $cnt++ if( !$bitmask || ( $bitmask & Apache2::Const::M_POST ) );
    $cnt++ if( !$bitmask || ( $bitmask & $req->method_number ) );
    return( $cnt == 2 );
} }) ); }

# NOTE: special processing
sub args { return( shift->_test({ method => 'args', expect => sub
{
    my $ref = shift( @_ );
    my $opts = shift( @_ );
    my @vals = Scalar::Util::blessed( $ref ) ? $ref->get( 'foo' ) : ();
    $opts->{log}->( "\@vals is '@vals', and foo = '$ref->{foo}', bar = '$ref->{bar}' and lang is '$ref->{lang}'" );
    return( $ref->{foo} == 1 && $ref->{bar} == 3 && $ref->{lang} eq 'ja_JP' && "@vals" eq '1 2' );
} }) ); }

# my $as_string_request = <<EOT;
# GET /tests/request/as_string HTTP/1.1
# TE: deflate,gzip;q=0.3
# Connection: TE
# Accept: application/json; version=1.0; charset=utf-8, text/javascript, */*
# Accept-Encoding: gzip, deflate, br
# Accept-Language: en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2
# Host: www.example.org:${port}
# User-Agent: Test-Apache2-API/v0.1.0
# 
# HTTP/1.1 (null)
# Test-No: as_string
# EOT
sub as_string { return( shift->_test({ method => 'as_string', expect => sub
{
    my $str = shift( @_ );
    my $opts = shift( @_ );
    my $self = $opts->{object};
    my $r = $self->request;
    $opts->{log}->( "request as a string is: $str" );
    # return( $str eq $as_string_request );
    return( $str =~ m,^GET[[:blank:]]+/tests/request/as_string[[:blank:]]+HTTP/\d.\d, );
} }) ); }

sub auth { return( shift->_test({ method => 'auth', expect => q{Bearer: eyJleHAiOjE2MzYwNzEwMzksImFsZyI6IkhTMjU2In0.eyJqdGkiOiJkMDg2Zjk0OS1mYWJmLTRiMzgtOTE1ZC1hMDJkNzM0Y2ZmNzAiLCJmaXJzdF9uYW1lIjoiSm9obiIsImlhdCI6MTYzNTk4NDYzOSwiYXpwIjoiNGQ0YWFiYWQtYmJiMy00ODgwLThlM2ItNTA0OWMwZTczNjBlIiwiaXNzIjoiaHR0cHM6Ly9hcGkuZXhhbXBsZS5jb20iLCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwibGFzdF9uYW1lIjoiRG9lIiwic3ViIjoiYXV0aHxlNzg5OTgyMi0wYzlkLTQyODctYjc4Ni02NTE3MjkyYTVlODIiLCJjbGllbnRfaWQiOiJiZTI3N2VkYi01MDgzLTRjMWEtYTM4MC03Y2ZhMTc5YzA2ZWQiLCJleHAiOjE2MzYwNzEwMzksImF1ZCI6IjRkNGFhYmFkLWJiYjMtNDg4MC04ZTNiLTUwNDljMGU3MzYwZSJ9.VSiSkGIh41xXIVKn9B6qGjfzcLlnJAZ9jGOPVgXASp0} }) ); }

sub auto_header { return( shift->_test({ method => 'auto_header', expect => 0, type => 'boolean' }) ); }

sub body { return( shift->_test({ method => 'body', expect => 'APR::Request::Param::Table', type => 'isa' }) ); }

sub charset { return( shift->_test({ method => 'charset', expect => 'utf-8' }) ); }

sub client_api_version { return( shift->_test({ method => 'client_api_version', expect => '1.0' }) ); }

sub connection { return( shift->_test({ method => 'connection', expect => 'Apache2::Connection', type => 'isa' }) ); }

sub cookie { return( shift->_test({ method => 'cookie', expect => 'Cookie', type => 'isa', args => ['my_session'] }) ); }

my $sample_data = <<EOT;
{
    "id": 123,
    "client_id": "37c58138-e259-44aa-9eee-baf3cbecca75"
}
EOT
sub data { return( shift->_test({ method => 'data', expect => $sample_data }) ); }

sub decode { return( shift->_test({ method => 'decode', expect => q{var=$ & < > ? ; # : = , " ' ~ + %}, args => ['var%3D%24+%26+%3C+%3E+%3F+%3B+%23+%3A+%3D+%2C+%22+%27+~+%2B+%25'] }) ); }

sub encode { return( shift->_test({ method => 'encode', expect => q{var%3D%24+%26+%3C+%3E+%3F+%3B+%23+%3A+%3D+%2C+%22+%27+~+%2B+%25}, args => [q{var=$ & < > ? ; # : = , " ' ~ + %}] }) ); }

sub document_root { return( shift->_test({ method => 'document_root', expect => $config->{vars}->{documentroot} }) ); }

sub document_uri { return( shift->_test({ method => 'document_uri', expect => undef }) ); }

sub env { return( shift->_test({ method => 'env', expect => 'APR::Table', type => 'isa' }) ); }

sub finfo { return( shift->_test({ method => 'finfo', expect => 'APR::Finfo', type => 'isa' }) ); }

sub gateway_interface { return( shift->_test({ method => 'gateway_interface', expect => 'CGI/1.1' }) ); }

sub global_request { return( shift->_test({ method => 'global_request', expect => 'Apache2::RequestRec', type => 'isa' }) ); }

sub has_auth { return( shift->_test({ method => 'has_auth', expect => 0, type => 'boolean' }) ); }

sub header_only { return( shift->_test({ method => 'header_only', expect => 0, type => 'boolean' }) ); }

sub headers { return( shift->_test({ method => 'headers', expect => 'APR::Table', type => 'isa' }) ); }

sub headers_as_hashref { return( shift->_test({ method => 'headers_as_hashref', expect => sub
{
    my $ref = shift( @_ );
    return( ref( $ref // '' ) eq 'HASH' );
} }) ); }

sub headers_as_json { return( shift->_test({ method => 'headers_as_json', expect => sub
{
    my $json = shift( @_ );
    return( substr( $json, 0, 1 ) eq '{' );
} }) ); }

sub headers_in { return( shift->_test({ method => 'headers_in', expect => 'APR::Table', type => 'isa' }) ); }

# if_modified_since
# if_none_match

sub is_secure { return( shift->_test({ method => 'is_secure', expect => HAS_SSL, type => 'boolean' }) ); }

sub json { return( shift->_test({ method => 'json', expect => 'JSON', type => 'isa' }) ); }

sub local_addr { return( shift->_test({ method => 'local_addr', expect => 'APR::SockAddr', type => 'isa' }) ); }

sub method { return( shift->_test({ method => 'method', expect => 'GET' }) ); }

sub mod_perl_version { return( shift->_test({ method => 'mod_perl_version', expect => sub
{
    my $vers = shift( @_ );
    my $opts = shift( @_ );
    $opts->{log}->( "mod_perl version is '", ( $vers // 'undef' ), "'" );
    if( substr( "$vers", 0, 1 ) != 2 )
    {
        eval( "require Data::Dump;" );
        unless( $@ )
        {
            $opts->{log}->( "\%ENV is -> ", Data::Dump::dump( \%ENV ) );
        }
    }
    return( substr( "$vers", 0, 1 ) == 2 );
} }) ); }

sub no_cache { return( shift->_test({ method => 'no_cache', expect => 0, type => 'boolean' }) ); }

sub notes { return( shift->_test({ method => 'notes', expect => 'APR::Table', type => 'isa' }) ); }

# NOTE: special processing
# foo=bar&lang=ja_JP
sub param { return( shift->_test({ method => 'param', expect => 'bar', args => ['foo'] }) ); }

# NOTE: special processing
# foo=bar&lang=ja_JP
sub params { return( shift->_test({ method => 'params', expect => sub
{
    my $ref = shift( @_ );
    return( ref( $ref ) eq 'HASH' && $ref->{foo} eq 'bar' );
} }) ); }

# path

sub path_info { return( shift->_test({ method => 'path_info', expect => '/request/path_info' }) ); }

sub payload { return( shift->_test({ method => 'payload', expect => sub
{
    my $ref = shift( @_ );
    my $opts = shift( @_ );
    if( eval( 'require Data::Dump;' ) )
    {
        $opts->{log}->( "\$ref is (", ( $ref // 'undef' ), ") -> ", Data::Dump::dump( $ref ) );
    }
    return( ref( $ref ) eq 'HASH' && ( exists( $ref->{client_id} ) && $ref->{client_id} eq '37c58138-e259-44aa-9eee-baf3cbecca75' ) );
} }) ); }

# NOTE: en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2 -> en-GB
sub preferred_language { return( shift->_test({ method => 'preferred_language', expect => 'en-GB', args => [[qw(fr-FR ja-JP en-GB en)]] }) ); }

sub protocol { return( shift->_test({ method => 'protocol', expect => 'HTTP/1.1' }) ); }

# NOTE: special processing
sub query { return( shift->_test({ method => 'query', expect => sub
{
    my $ref = shift( @_ );
    my $opts = shift( @_ );
    if( eval( 'require Data::Dump;' ) )
    {
        $opts->{log}->( "\$ref is: ", Data::Dump::dump( $ref ) );
    }
    return(
        ( exists( $ref->{foo} ) && $ref->{foo} == 1 ) && 
        ( exists( $ref->{bar} ) && $ref->{bar} == 3 ) && 
        ( exists( $ref->{lang} ) && $ref->{lang} eq 'ja_JP' )
    );
} }) ); }

# NOTE: special processing
sub query_string { return( shift->_test({ method => 'query_string', expect => 'foo=bar&lang=ja-JP&q=%E6%9C%80%E9%AB%98%E3%81%A0%EF%BC%81' }) ); }

sub referer { return( shift->_test({ method => 'referer', expect => 'https://example.org/some/where.html' }) ); }

sub remote_addr { return( shift->_test({ method => 'remote_addr', expect => 'APR::SockAddr', type => 'isa' }) ); }

sub request_time { return( shift->_test({ method => 'request_time', expect => 'DateTime', type => 'isa' }) ); }

# requires
# satisfies
# script_filename
# script_name
# script_uri
# script_url

# Apache2::ServerUtil->server
sub server { return( shift->_test({ method => 'server', expect => 'Apache2::ServerRec', type => 'isa' }) ); }

# server_addr
# server_admin
# server_hostname
# server_name
# server_port
# server_protocol
# server_signature
# server_software
# server_version
# set_basic_credentials
# set_handlers
# slurp_filename

sub socket { return( shift->_test({ method => 'socket', expect => 'APR::Socket', type => 'isa' }) ); }

# status
# status_line
# str2datetime
# str2time
# subnet_of

sub subprocess_env { return( shift->_test({ method => 'subprocess_env', expect => 'APR::Table', type => 'isa' }) ); }

sub the_request { return( shift->_test({ method => 'the_request', expect => 'GET /tests/request/the_request HTTP/1.1' }) ); }

# time2datetime

# 2021-11-1T167:12:10+0900
sub time2str { return( shift->_test({ method => 'time2str', expect => 'Mon, 01 Nov 2021 08:12:10 GMT', args => [1635754330] }) ); }

sub type { return( shift->_test({ method => 'type', expect => 'text/plain' }) ); }

# unparsed_uri
# uploads

sub uri { return( shift->_test({ method => 'uri', expect => 'URI', type => 'isa' }) ); }

# url_decode
# url_encode
# user

sub user_agent { return( shift->_test({ method => 'user_agent', expect => 'Test-Apache2-API/v0.1.0' }) ); }

sub _target { return( shift->api->request ); }

1;
# NOTE: POD
# Use this to generate the tests list:
# egrep -E '^sub ' ./t/lib/Test/Apache2/API/Request.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "=head2 $m\n"'
__END__

=encoding utf8

=head1 NAME

Test::Apache2::API::Request - Apache2::API::Request Testing Class

=head1 SYNOPSIS

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
    my $req = HTTP::Request->new( 'GET' => "${proto}://${hostport}/tests/request/some_method" );
    my $resp = $ua->request( $req );
    is( $resp->code, Apache2::Const::HTTP_OK, 'some test name' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a package for testing the L<Apache2::API> module under Apache2/modperl2 and inherits from C<Test::Apache::Common>

=head1 TESTS

=head2 aborted

=head2 accept

=head2 accept_charset

=head2 accept_encoding

=head2 accept_language

=head2 accept_type

=head2 accept_version

=head2 acceptable

=head2 acceptables

=head2 allowed

=head2 args

=head2 as_string

=head2 auth

=head2 auto_header

=head2 body

=head2 charset

=head2 client_api_version

=head2 connection

=head2 cookie

=head2 data

=head2 decode

=head2 encode

=head2 document_root

=head2 document_uri

=head2 env

=head2 finfo

=head2 gateway_interface

=head2 global_request

=head2 has_auth

=head2 header_only

=head2 headers

=head2 headers_as_hashref

=head2 headers_as_json

=head2 headers_in

=head2 is_secure

=head2 json

=head2 local_addr

=head2 method

=head2 mod_perl_version

=head2 no_cache

=head2 notes

=head2 param

=head2 params

=head2 path_info

=head2 payload

=head2 preferred_language

=head2 protocol

=head2 query

=head2 query_string

=head2 referer

=head2 remote_addr

=head2 request_time

=head2 server

=head2 socket

=head2 subprocess_env

=head2 the_request

=head2 time2str

=head2 type

=head2 uri

=head2 user_agent

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API>, L<Apache::Test>, L<Apache::TestUtil>, L<Apache::TestRequest>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
