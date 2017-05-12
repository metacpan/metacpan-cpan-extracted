#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Siesh;
use IO::String;
use Test::Output qw(:tests stdout_from);
use File::Temp qw(tempfile);



sub execute {
	my $cmd = shift;
	return App::Siesh->run(%{ App::Siesh->read_config('t/siesh.conf') }, file => IO::String->new( $cmd ) );
}

if ( not -f 't/siesh.conf' ) {
    plan skip_all => 'Author test. Only run if t/siesh.conf exists.',
}
else {
	plan tests => 9;

	if ( stdout_from( sub { execute('ls') } ) ne "" ) {
		BAIL_OUT('Existing scripts would be deleted. Please use an empty account for testing.')
	}

	my ($fh,$tempfile) = tempfile( UNLINK => 1 );
        print {$fh} <DATA>;
	close $fh;

	execute('rm *');
	stdout_is( sub { execute('ls') },'','rm * succeeded, no files left.');

	execute("put $tempfile foo" );
	stdout_is( sub { execute('ls') },"foo\n",'foo was uploaded');

	execute('cp foo bar');
	stdout_is( sub { execute('ls') },"bar\nfoo\n",'copied foo to bar');

	execute('mv foo quux');
	stdout_is( sub { execute('ls') },"bar\nquux\n",'moved foo to quux');

	execute('activate bar');
	stdout_is( sub { execute('ls') },"bar *\nquux\n",'activated bar');

	execute('activate quux');
	stdout_is( sub { execute('ls') },"quux *\nbar\n",'activated quux (new ordering)');

	execute('deactivate');
	stdout_is( sub { execute('ls') },"bar\nquux\n",'moved foo to quux');

	stdout_is( sub { execute('cat quux') },"#\n",'catting quux');

	stderr_like( sub { execute('cat quuz') },qr/NO/,'catting non-existing script fails');

	execute('rm *');

}

__DATA__
#
