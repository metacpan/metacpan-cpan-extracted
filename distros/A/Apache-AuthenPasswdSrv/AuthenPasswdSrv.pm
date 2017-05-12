#
# Apache::AuthenPasswdSrv
# Version 0.01 (Alpha Release)
#
# $Id:$
#
# Written by Jeffrey Hulten (jeffh@premier1.net)
# Copyright 1998 
#
# This module may be distributed under the GPL v2 or later.
#

package Apache::AuthenPasswdSrv;

use Apache ();
use Apache::Constants qw(OK AUTH_REQUIRED DECLINED SERVER_ERROR);
use Socket;

use strict;

$Apache::AuthenPasswdSrv::VERSION = '0.01';

$Apache::AuthenPasswdSrv::DEBUG = 0;

sub handler {
   
	my ($r) = shift;

	my ($prefix) = "$$ Apache::AuthenPasswdSrv"; 
	if ($Apache::AuthenPasswdSrv::DEBUG) { 
		my ($type) = ''; 
		$type .= 'inital '   if $r->is_initial_req; 
		$type .= 'main'      if $r->is_main; 
		$r->log_error("\n$prefix request type = $type\n"); 
		$r->log_error("\n$prefix request = ". $r->as_string .  "\n");
	} 
	
	return OK unless $r->is_initial_req; 
	
	my($res, $passwd_sent) = $r->get_basic_auth_pw; 
	
	return $res if $res; 
	# e.g.  HTTP_UNAUTHORIZED 
	
	my($user_sent) = $r->connection->user; 
	my ($remote, $line, $buf, $result); 
	$remote = "/tmp/pswdsock"; 
	socket (SOCK, PF_UNIX, SOCK_STREAM, 0)  or die "socket: $!"; 
	connect (SOCK, sockaddr_un($remote)) or die "connect: $!"; 
	
	select(SOCK); $| = 1; 
	select(STDOUT); 
	
	while (<SOCK>) { 
		if ($_ =~ /^220/) { 
			$line = $user_sent .  " " .  $passwd_sent; 
			print SOCK $line .  "\n"; 
		} elsif ($_ =~ /^221/) { 
			last; 
		} elsif ($_ =~ /^4\d\d/) { 
			$r->log_reason("$prefix Authentication failed from passwd server for $user_sent", $r->filename);
			$r->note_basic_auth_failure; $result = AUTH_REQUIRED; 
		} elsif ($_ =~ /^5\d\d/) { 
			$r->log_error("$prefix Internal authentication error: $_"); 
			$r->note_basic_auth_failure; 
			$result = AUTH_REQUIRED;       
		} elsif ($_ =~ /^200/) { 
			$_ =~ s/^200 OK //; 
			$line = $_; 
			$result = OK; 
		} 
	} 
	
	close SOCK; 
	
	return $result; 
	
} 

1;

__END__

=head1 NAME

B<Apache::AuthenPasswdSrv> - mod_perl Authen Handler

=head1 SYNOPSIS

  PerlAuthenHandler Apache::AuthenPasswdSrv->handler()

=head1 REQUIRES

Perl5.004_04, mod_perl 1.15

=head1 DESCRIPTION

B<Apache::AuthenPasswdSrv> is a mod_perl Authentication handler that
checks a users credentials against a domain socket server.  The included
server, B<passwd_srv.pl>, checks a username and password against an NIS
database using Net::NIS and ypmatch.  This release is very alpha.  The 
server protocol is not documented and transaction format will change.
The system has been running under light load at my office for about a 
month now, and no problems are know with the current release.

=head1 TODO

=over 4

=item B<Module Configuration>

Break out module configuration into PerlSetVar statements.

=item B<NIS Server Configuration>

Figure out MakeMaker enough to auto-configure paths in password server.

=item B<Documentation>

Write up Server Protocol documentation.
Write a better POD file for the module.

=item B<Module/Server Structure>

Build class structure for password service client.
Add security so client/server can be used with standard IP sockets.
Build class structure for server.
Build other example servers.

=back

=head1 ACKNOWLEDGEMENTS 

Thanks to Premier1 Internet Service, Inc. for allowing me to work on
this module during work hours and paying me to muck with Perl.

=head1 AUTHOR

Jeffrey Hulten, jeffh@premier1.net

=head1 SEE ALSO

mod_perl(1).

=cut
