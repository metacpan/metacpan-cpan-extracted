#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use lib './lib';
    use_ok( 'Apache2::SSI::File' ) || BAIL_OUT( "Unable to load Apache2::SSI::File" );
    use_ok( 'URI::file' ) || BAIL_OUT( 'Unable to load URI::file' );
    use constant HAS_APACHE_TEST => $ENV{HAS_APACHE_TEST};
    if( HAS_APACHE_TEST )
    {
        require_ok( 'Apache::Test' ) || BAIL_OUT( "Unable to load Apache::Test" );
        use_ok( 'Apache::TestUtil' ) || BAIL_OUT( "Unable to load Apache::TestUtil" );
        use_ok( 'Apache::TestRequest' ) || BAIL_OUT( "Unable to load Apache::TestRequest" );
        use_ok( 'Apache2::Const', '-compile', qw( :common :http ) ) || BAIL_OUT( "Unable to load Apache2::Cons" );
    }
    our $DEBUG = 0;
};

my $file = './ssi/include.cgi';
my $dir  = URI::file->new_abs( './t/htdocs' )->file;
diag( "Base directory is '$dir'" ) if( $DEBUG );
my $f = Apache2::SSI::File->new( $file, base_dir => './t/htdocs', debug => 0 );

isa_ok( $f, 'Apache2::SSI::File' );

my $failed;
{
    no warnings 'Apache2::SSI::Finfo';
    $failed = Apache2::SSI::File->new( './not-existing.txt', debug => 0 );
}

ok( defined( $failed ), 'Non-existing file object' );
ok( $failed->code == 404, 'Non-existing file code' );
ok( $failed->finfo->filetype == Apache2::SSI::Finfo::FILETYPE_NOFILE, 'Non-existing file type' );

isa_ok( $failed, 'Apache2::SSI::File' );

diag( "Expecting ${dir}/ssi/include.cgi" ) if( $DEBUG );
ok( $f->filename eq "${dir}/ssi/include.cgi", 'filename' );

ok( $f->code == 200, 'code' );

my $f2 = $f->clone;

{
    no warnings 'Apache2::SSI::File';
    $f2->filename( "${dir}/ssi/../ssi/plop.pl" );
}

diag( "Filename is: ", $f2->filename, " and I am expecting $dir/ssi/plop.pl" ) if( $DEBUG );
ok( $f2->filename eq "${dir}/ssi/plop.pl", 'filename' );

ok( $f2->code == 404, 'code failed' );

# Access to finfo
my $finfo = $f->finfo;
diag( "File ${dir}/${file} mode is: '", ( (CORE::stat( "${dir}/${file}" ))[2] & 07777 ), "' vs finfo one: '", $f->finfo->mode, "'" ) if( $DEBUG );
ok( ( (CORE::stat( "${dir}/${file}" ))[2] & 07777 ) eq $f->finfo->mode, 'finfo' );

ok( $f->finfo->is_file, 'finfo is_file' );

ok( $f->parent->filename eq "${dir}/ssi", 'parent' );

SKIP:
{
    my $tests = [
        'Apache2::SSI::File object',
        'Non-existing file object',
        'Non-existing file code',
        'Non-existing file type',
        'filename',
        'updated bad filename',
        'updated bad filename code',
        'updated bad filename filetype',
        'finfo',
        'finfo is_file',
        'parent',
    ];
    if( HAS_APACHE_TEST )
    {
        for( my $i = 0; $i < scalar( @$tests ); $i++ )
        {
            my( $ct, $resp ) = &make_request( sprintf( '/tests/test%02d', $i + 20 ) );
            ok( $ct->[0] eq 'ok', sprintf( '%s with Apache test No %d', $tests->[$i], ( $i + 1 ) ) );
            if( $ct->[0] ne 'ok' && scalar( @$ct ) > 1 )
            {
                diag( "Test No $i failed with returned code ", $resp->code, ": ", join( "\n", @$ct[1..$#$ct] ) );
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
    $result = [split( /\n/, Encode::decode( 'utf8', $resp->content ) )];
    return( wantarray() ? ( $result, $resp ) : $result );
}

