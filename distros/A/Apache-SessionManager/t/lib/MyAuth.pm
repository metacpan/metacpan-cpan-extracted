package MyAuth;
use Apache::SessionManager;
use strict;

use vars qw($VERSION);
$VERSION = '0.2';

use mod_perl;
use constant MP2 => ($mod_perl::VERSION >= 1.99);

BEGIN {
	# Test mod_perl version and use the appropriate components
	if (MP2) {
		require Apache::Const;
		Apache::Const->import(-compile => qw(OK REDIRECT FORBIDDEN));
		require Apache::RequestRec;
		require Apache::Response;
		require Apache::RequestIO;
		require Apache::Connection;
		require Apache::Log;
		require CGI;
		CGI->import(qw(:cgi-lib));
	}
	else {
		require Apache::Constants;
		Apache::Constants->import(qw(OK REDIRECT FORBIDDEN));
	}
}

sub handler {
	my $r = shift;
	my $session = Apache::SessionManager::get_session($r);

	# Login ok: user is already logged or login form is requested
	if ( $session->{'logged'} == 1 || $r->uri eq $r->dir_config('MyAuthLogin') ) { 
	   return MP2 ? Apache::OK : Apache::Constants::OK;
	}
	# user not logged in or session expired

	# store in session the destination url if not set
	$session->{'redirect'} ||= $r->uri . ( ( $r->args ) ? ('?' . $r->args) : '' );

	# verify credenitals
#	unless ( verifiy_cred( ($r->args) ) ) {
	unless ( verifiy_cred( ( (MP2) ? Vars : $r->args() ) ) ) {
		# Log error
		$r->log_error('MyAuth: access to ' . $r->uri . ' failed for ' . (MP2 ? $r->connection->get_remote_host : $r->get_remote_host) );
		# Redirect to login page
		$r->custom_response((MP2 ? Apache::FORBIDDEN : Apache::Constants::FORBIDDEN), $r->dir_config('MyAuthLogin'));
		return MP2 ? Apache::FORBIDDEN : Apache::Constants::FORBIDDEN;
	}
	$session->{'logged'} = 1;
	# Redirect to original protected resource
	$r->content_type('text/html'); 
	$r->headers_out->{'Location'} = $session->{'redirect'};
	return MP2 ? Apache::REDIRECT : Apache::Constants::REDIRECT;
}

sub verifiy_cred {
   my %cred = @_;

	#use Data::Dumper;
	#print STDERR Dumper(\%cred);

   # Check correct username and password
   return 1 if ( $cred{'username'} eq 'foo' && $cred{'password'} eq 'baz' );
   return 0;
}

1;
