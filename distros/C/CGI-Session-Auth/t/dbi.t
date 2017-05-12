#!perl -T

use Test::More tests => 4;

eval "use CGI";                                                                                                   
if ($@) {                                                                                                         
	plan skip_all => "no CGI module";
}

eval "use CGI::Session";                                                                                                   
if ($@) {                                                                                                         
	plan skip_all => "no CGI::Session module";
}

BEGIN { 
	use_ok('CGI::Session::Auth');
}

require_ok('CGI::Session::Auth');

my $cgi = new CGI;
my $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp'});

# check the DBI driver can be loaded
# note the hack of passing in a dummy DBHandle, this only works because the constructor
# doesn't attempt to use the handle.
{ 
	use_ok('CGI::Session::Auth::DBI');

	$auth_dbi = new CGI::Session::Auth::DBI ( {	CGI => $cgi
											,	Session => $session 
											,	DBHandle => 'dummy' } );

	ok( $auth_dbi, 'instanciate CGI::Session::Auth::DBI' );
}
