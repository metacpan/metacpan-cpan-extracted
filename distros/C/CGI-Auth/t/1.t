#!/usr/bin/perl -w    

# $Id: 1.t,v 1.5 2004/01/28 04:38:45 cmdrwalrus Exp $

use strict;
use 5.006;
use warnings;

use Test::More tests => 4;

my $authdir = 't/auth';

require CGI::Auth;

# Attempt to create a CGI::Auth object.
my $auth = CGI::Auth->new( {
	-authdir		=> $authdir,
	-formaction		=> 'myscript.pl',
	-authfields		=> [
		{id => 'user', display => 'User Name', hidden => 0, required => 1},
		{id => 'pw', display => 'Password', hidden => 1, required => 1},
	],
} );

# Ensure that an object was created OK.

# * Test 1 * Object exists,
ok( defined $auth, 'object defined' );

# * Test 2 * and it's of the right class.
ok( $auth->isa( 'CGI::Auth' ), 'object is the right class' );


# Now verify that CGI::Auth is going to print the login page, or at least a Content-type.
my $test = ( qx(perl -w t/check.pl) =~ m/^Content-Type:/i );

# * Test 3 * The output was as expected.
ok( $test, "check test script" );


# Now let's try to log in.
# login.pl will print out the name of the session file once the login is successful.
# We need to verify that the username in the session file is right.
qx(perl -w t/login.pl auth_user=testing auth_pw=testing auth_submit=1) =~ m/(\w+)/;
my $sessfile = $1;
if ( $sessfile && open( SESSFILE, "< $authdir/sess/$sessfile" ) )
{
	my $field0 = <SESSFILE>;
	close( SESSFILE );
	unlink( "$authdir/sess/$sessfile" );

	# This test is successful if the username shows up in the session file.
	$test = ( $field0 =~ m/^testing/ );
}
else
{
	undef $test;
}

# * Test 4 * Login succeeded.
ok( $test, "login test script" );

