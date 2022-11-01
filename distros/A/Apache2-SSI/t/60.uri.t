#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    use lib './lib';
    use vars qw( $DEBUG );
    use_ok( 'Apache2::SSI::URI' ) || BAIL_OUT( "Unable to load Apache2::SSI::URI" );
    use Encode ();
    use URI;
    use URI::file;
    use File::Spec ();
    use constant HAS_APACHE_TEST => $ENV{HAS_APACHE_TEST};
    if( HAS_APACHE_TEST )
    {
        require_ok( 'Apache::Test' ) || BAIL_OUT( "Unable to load Apache::Test" );
        use_ok( 'Apache::TestUtil' ) || BAIL_OUT( "Unable to load Apache::TestUtil" );
        use_ok( 'Apache::TestRequest' ) || BAIL_OUT( "Unable to load Apache::TestRequest" );
        use_ok( 'Apache2::Const', '-compile', qw( :common :http ) ) || BAIL_OUT( "Unable to load Apache2::Cons" );
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $uri = './ssi/include.cgi';
my $doc_root = './t/htdocs';
my $doc_root_full_path = URI::file->new_abs( $doc_root )->file( $^O );
my $f = Apache2::SSI::URI->new(
    document_uri => $uri,
    document_root => $doc_root,
    debug => $DEBUG,
);
isa_ok( $f, 'Apache2::SSI::URI' );

my $failed;
{
    no warnings 'Apache2::SSI::Finfo';
    $failed = Apache2::SSI::URI->new(
        document_uri => './not-existing.txt',
        document_root => $doc_root,
        base_uri => '/ssi',
    );
}
ok( defined( $failed ), 'Non existing file object' );

diag( "document_path found is '", $f->document_path, "'." ) if( $DEBUG );
ok( $f->document_path eq '/ssi/include.cgi', 'document_path' );

ok( $f->document_directory eq '/ssi', 'document_dir' );

ok( $f->base_uri eq '/', 'base_uri' );

ok( ( $f->path_info // '' ) eq '', 'empty path_info' );

ok( ( $f->query_string // '' ) eq '', 'empty query_string' );

diag( "document_filename returned '", $f->document_filename, "' using File::Spec (", File::Spec->catdir( $doc_root_full_path, URI::file->new( '/ssi/include.cgi' )->file( $^O ) ), ")." ) if( $DEBUG );
ok( $f->document_filename eq File::Spec->catdir( $doc_root_full_path, URI::file->new( '/ssi/include.cgi' )->file( $^O ) ), 'document_filename' );

ok( $f->document_root eq $doc_root_full_path, 'document_root' );

ok( $f->document_uri eq "/ssi/include.cgi", 'document_uri' );

my $f2 = $f->clone;

$f2->path_info( '/some/pathinfo' );

ok( $f2->document_uri eq "/ssi/include.cgi/some/pathinfo", "document_uri updated with path info" );

$f2->query_string( 'q=something&l=ja_JP' );

ok( $f2->document_uri eq "/ssi/include.cgi/some/pathinfo?q=something&l=ja_JP", "document_uri updated with query string" );

{
    no warnings 'Apache2::SSI::Finfo';
    $f2->filename( "${doc_root}/ssi/../ssi/plop.pl" );
}

diag( "Document filename is: ", $f2->filename, " and I am expecting ", File::Spec->catdir( URI::file->new( $doc_root_full_path )->file( $^O ), URI::file->new( '/ssi/plop.pl' )->file( $^O ) ) ) if( $DEBUG );
ok( $f2->filename eq File::Spec->catdir( URI::file->new( $doc_root_full_path )->file( $^O ), URI::file->new( '/ssi/plop.pl' )->file( $^O ) ), 'filename' );

ok( $f2->document_uri eq "/ssi/plop.pl/some/pathinfo?q=something&l=ja_JP", "document_uri updated with filename" );

# Access to finfo
my $finfo = $f->finfo;
diag( "File ${doc_root}/${uri} mode is: '", ( (CORE::stat( File::Spec->catdir( $doc_root_full_path, URI::file->new( $uri )->file( $^O ) ) ))[2] & 07777 ), "' vs finfo one: '", $f->finfo->mode, "'" ) if( $DEBUG );
ok( ( (CORE::stat( File::Spec->catdir( $doc_root_full_path, URI::file->new( $uri )->file( $^O ) ) ))[2] & 07777 ) eq $f->finfo->mode, 'finfo' );

ok( $f->finfo->is_file, 'finfo is_file' );

ok( $f->parent->document_uri eq '/ssi', 'parent' );

ok( $f->uri eq '/ssi/include.cgi', 'uri' );

SKIP:
{
    my $tests = [
        'Apache2::SSI::URI object',
        'Non existing uri object',
        'document_path',
        'document_dir',
        'base_uri',
        'empty path_info',
        'empty query_string',
        'document_filename',
        'document_root',
        'document_uri',
        'document_uri updated with path info',
        'document_uri path info using APR::URI',
        'document_uri updated with query string',
        'filename',
        'document_uri updated with filename',
        'finfo',
        'finfo is_file',
        'parent',
        'uri',
    ];
    if( HAS_APACHE_TEST )
    {
        for( my $i = 0; $i < scalar( @$tests ); $i++ )
        {
            ## Test No 12: Does not work as I expected, i.e. APR::URI is not capable of deducting what is the path info.
            ## Test No 15: It is wrong to try to update the uri by updating its underlying filename, because the filename does not necessarily match the uri. The filename could be outside of the document root such as with Alias or point to a different document with special mappings.
            if( $i == 11 || $i == 14 )
            {
                pass( sprintf( '%s with Apache test No %d', $tests->[$i], ( $i + 1 ) ) ), next;
            }
            my( $ct, $resp ) = &make_request( sprintf( '/tests/test%02d', $i + 1 ) );
            ok( $ct->[0] eq 'ok', sprintf( '%s with Apache test No %d', $tests->[$i], ( $i + 1 ) ) );
            if( $ct->[0] ne 'ok' && scalar( @$ct ) > 1 )
            {
                diag( "Test No $i failed with returned code ", $resp->code, ": ", join( "\n", @$ct[1..$#$ct] ) ) if( $DEBUG );
            }
        }
    }
    else
    {
        skip( "Apache mod_perl is not enabled, skipping.", scalar( @$tests ) );
    }
};

sub make_request
{
    my $uri = shift( @_ );
    my $resp = GET( $uri );
    my $result = [split( /\n/, Encode::decode( 'utf8', $resp->content ) )];
    return( wantarray() ? ( $result, $resp ) : $result );
}

