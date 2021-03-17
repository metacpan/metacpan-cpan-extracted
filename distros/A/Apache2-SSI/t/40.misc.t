#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use lib './lib';
    use_ok( 'Apache2::SSI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    use constant HAS_APACHE_TEST => $ENV{HAS_APACHE_TEST};
    use URI::file;
    our $DEBUG = 0;
};

use utf8;
my $doc_root = URI::file->new_abs( './t/htdocs' )->file;
my $ssi = Apache2::SSI->new(
    debug => $DEBUG,
    document_uri => '../index.html?q=something&l=en_GB',
    document_root => $doc_root,
) || BAIL_OUT( Apache2::SSI->error );
$ssi->document_root( $doc_root );
my $doc_root2 = $ssi->document_root;
ok( $doc_root2 eq $doc_root, 'document root' );
my $phrase = 'Tous les êtres humains naissent libres et égaux en dignité et en droits.';
my $enc_url = $ssi->encode_url( $phrase );
# diag( "URL-encoded string is '$enc_url'" );
ok( $enc_url eq 'Tous+les+%C3%AAtres+humains+naissent+libres+et+%C3%A9gaux+en+dignit%C3%A9+et+en+droits.', '%-url encode' );
my $enc_ent = $ssi->encode_entities( $phrase );
# diag( "HTML entities encoded string is '$enc_ent'" );
ok( $enc_ent eq 'Tous les &ecirc;tres humains naissent libres et &eacute;gaux en dignit&eacute; et en droits.', 'HTML Entities encode' );
my $enc_b64 = $ssi->encode_base64( $phrase );
ok( $enc_b64 eq 'VG91cyBsZXMgw6p0cmVzIGh1bWFpbnMgbmFpc3NlbnQgbGlicmVzIGV0IMOpZ2F1eCBlbiBkaWduaXTDqSBldCBlbiBkcm9pdHMu', 'Base64 encode' );
my $enc_uri = $ssi->encode_uri( 'https://www.example.com/' );
# diag( "Encoded uri is '$enc_uri'" );
ok( $enc_uri eq 'https%3A%2F%2Fwww.example.com%2F', 'URI encode' );
if( $ssi->mod_perl )
{
    my $version = $ssi->server_version;
    ok( $version =~ /[\d\.]+/, 'server version' );
}
$ssi->remote_ip( '192.168.1.10' ) if( !$ssi->mod_perl );
my $remote_ip = $ssi->remote_ip;
ok( $remote_ip =~ /^(\d{1,3}\.){3}\d{1,3}$/, 'remote ip' );

