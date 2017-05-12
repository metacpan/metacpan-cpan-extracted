#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Net::ManageSieve::Siesh;
use File::Temp qw(tempfile);
use App::Siesh;

if ( not -f 't/siesh.conf' ) {
    plan skip_all => 'Author test. Only run if t/siesh.conf exists.',

}
else {
    my $config = App::Siesh->read_config('t/siesh.conf');

    plan tests => 18;

    my ( $fh, $tempfile ) = tempfile( UNLINK => 1 );
    my $filter;
    {
        local $/ = undef;
        $filter = <DATA>;
        print {$fh} $filter;
	close($fh);
    }

    ok(
        my $sieve =
          Net::ManageSieve::Siesh->new( $config->{host}, tls => 'require' ),
        'connecting to sieve server'
    );

    ok( $sieve->login( $config->{user}, $config->{password} ), 'logging in' );

    BAIL_OUT('Existing scripts would be deleted. Please use an empty account for testing.') if $sieve->listscripts();

    ok( $sieve->putfile( $tempfile, 'bar' ), 'uploading script' );
    ok( $sieve->script_exists('bar'), 'script was really uploaded' );
    ok( $sieve->copyscript( 'bar', 'foo' ), 'copying script' );
    ok( $sieve->script_exists('foo'), 'script was really copied' );
    ok( $sieve->movescript( 'bar', 'foo' ), 'renaming script' );
    ok( !$sieve->script_exists('bar'), 'script was really moved' );

    ok( $sieve->getfile( 'foo', $tempfile ), 'downloading script' );

    ok( !$sieve->is_active('foo'), "foo is not active" );
    ok( $sieve->activate('foo'),   "activating foo" );
    ok( $sieve->is_active('foo'),  "foo is really active" );
    ok( $sieve->movescript('foo','quux'),  'moving active script' );
    ok( $sieve->is_active('quux'),  'moved script is still active' );
    $sieve->movescript('quux','foo'); # Moving back for next tests
    ok( $sieve->deactivate('foo'), "deactivating 'foo'" );
    ok( !$sieve->is_active('foo'), "foo is really deactive" );

    {
    my ($temp_fh) = $sieve->temp_scriptfile('foo');
    is(<$temp_fh>,"# This filter does nothing at all\n",'temp_scriptfile return filehandle of script');
    }

    ok( $sieve->deletescript($sieve->listscripts()), 'deleting multiple scripts' );
}

__DATA__
# This filter does nothing at all
