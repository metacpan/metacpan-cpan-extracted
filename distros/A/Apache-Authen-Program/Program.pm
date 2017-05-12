# Apache::Authen::Program allows you to call an external program
# that performs username/password authentication in Apache.
#
# Copyright (c) 2002-2004 Mark Leighton Fisher, Fisher's Creek Consulting, LLC
# 
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


package Apache::Authen::Program;

use strict;
use Apache::Constants ':common';
use File::Temp q(tempfile);

$Apache::Authen::Program::VERSION = '0.93';


sub handler {
    my $request  = shift;	# Apache request object
    my @args     = ();		# authentication program arguments
    my $cmd      = "";		# program command string
    my $i        = 0;		# counter for @args
    my $ofh      = "";		# output file handle for password temp file
    my $password = "";		# password from Basic Authentication
    my $passfile = "";		# temporary file containing password
    my $passtype = "";		# "File" if communicating password by temp file
    my $program  = "";		# authentication program filename
    my $response = ""; 		# Apache response object
    my $success  = "";		# success string from authentication program
    my $username = "";		# username from Basic Authentication

    # get password, decline if not Basic Authentication
    ($response, $password) = $request->get_basic_auth_pw;
    return $response if $response;

    # get username
    $username = $request->connection->user;
    if ($username eq "") {
	$request->note_basic_auth_failure;
        $request->log_reason("Apache::Authen::Program - No Username Given", $request->uri);
        return AUTH_REQUIRED;
    }

    # get authentication program, args, and success string
    $program = $request->dir_config("AuthenProgram");
    for ($i = 1; $i < 10; $i++) {
        $args[$i] = $request->dir_config("AuthenProgramArg$i");
    }
    $success = $request->dir_config("AuthenProgramSuccess");

    # write temp. password file on request
    $passtype = $request->dir_config("AuthenProgramPassword");
    if ($passtype eq "File") {
        ($ofh, $passfile) = tempfile();
        if (!defined($ofh) || $ofh eq "") {
            $request->log_reason("Apache::Authen::Program can't create password file",
	     $request->uri);
            return SERVER_ERROR;
        }
        chmod(0600, $passfile)
         || $request->log_reason(
         "Apache::Authen::Program can't chmod 0600 password file '$passfile' because: $!",
	 $request->uri);
        if (!print $ofh $password,"\n") {
            $request->log_reason("Apache::Authen::Program can't write password file '$ofh'",
	     $request->uri);
            return SERVER_ERROR;
        }
        if (!close($ofh)) {
            $request->log_reason("Apache::Authen::Program can't close password file '$ofh'",
	     $request->uri);
            return SERVER_ERROR;
        }
        $password = $passfile;
    }

    # execute command, then examine output for success or failure
    $cmd = "$program '$username' '$password' ";
    $cmd .= join(' ', @args);
    my @output = `$cmd`;
    if ($passtype eq "File") {
        if (!unlink($passfile)) {
            $request->log_reason("Apache::Authen::Program can't delete password file '$ofh'",
	     $request->uri);
        }
    }
    if (!grep(/$success/, @output)) {
	$request->note_basic_auth_failure;
	$request->log_reason("login failure: " . join(' ', @output), $request->uri);
	return AUTH_REQUIRED;
    }

    unless (@{ $request->get_handlers("PerlAuthzHandler") || []}) {
	$request->push_handlers(PerlAuthzHandler => \&authz);
    }

    return OK;
}

sub authz {
    my $request = shift;		# Apache request
    my $requires = $request->requires;	# Apache Requires arrayref
    my $username			# username
      = $request->connection->user;
    my $require = "";			# one Requires statement
    my $type    = "";			# type of Requires
    my @users   = ();			# list of valid users

    # decline unless we have a requires
    return OK unless $requires;

    # process each Requires statement
    for my $require (@$requires) {
        my($type, @users) = split /\s+/, $require->{requirement};

	# user is one of these users
	if ($type eq "user") {
	    return OK if grep($username eq $_, @users);

	# user is simply authenticated
	} elsif ($type eq "valid-user") {
	    return OK;
	}
    }
    
    $request->note_basic_auth_failure;
    $request->log_reason("user $username: not authorized", $request->uri);
    return AUTH_REQUIRED;

}

1;

__END__

=head1 NAME

Apache::Authen::Program - mod_perl external program authentication module


=head1 SYNOPSIS

    <Directory /foo/bar>
    # This is the standard authentication stuff
    AuthName "Foo Bar Authentication"
    AuthType Basic

    # Variables you need to set
    PerlSetVar AuthenProgram         /usr/local/Samba-2.2.3a/bin/smbclient
    PerlSetVar AuthenProgramSuccess  "OK: SMB login succeeded"

    # other variables needed by AuthenProgram (up to 9 supported)
    PerlSetVar AuthenProgramArg1     thompdc4
    PerlSetVar AuthenProgramArg2     netlogon

    PerlAuthenHandler Apache::Authen::Program

    # Standard require stuff, only user and 
    # valid-user work currently
    require valid-user
    </Directory>

    These directives can be used in a .htaccess file as well.

    If you wish to use your own PerlAuthzHandler then the require 
    directive should follow whatever handler you use.

= head1 DESCRIPTION

This mod_perl module provides a reasonably general mechanism
to perform username/password authentication in Apache by
calling an external program.  Authentication by an external
program is useful when a program can perform an authentication
not supported by any Apache modules (for example, cross-domain
authentication is not supported by Apache::NTLM or
Apache::AuthenSmb, but is supported by Samba's smbclient
program).

You must define the program pathname AuthenProgram and the
standard output success string AuthenProgramSuccess.
The first two arguments to the program are the username and
either the password or a temporary file with the password, 
depending on whether AuthenProgramPassword has the value "File".
"File" forces sending the password to AuthenProgram through a
temporary file to avoid placing passwords on the command line where
they can be seen by ps(1).

Additional program arguments can be passed in the variables
AuthenProgramArg1, AuthenProgramArg2, etc.  Up to 9 of these
variables are supported.

The examples/ subdirectory has sample programs for doing
Samba-based SMB authentication (examples/smblogon),
Oracle authentication (examples/oralogon), and
a simple example (examples/filelogon) that demonstrates communicating
the password through a temporary file.

If you are using this module please let me know, I'm curious how many
people there are that need this type of functionality.

This module was adapted from Apache::AuthenSmb.

=head1 DESIGN NOTES

This module trades off speed for flexibility -- it is not 
recommended for use when you need to process lots of
authentications/minute, as each authentication requires
a fork().  As any program can be used for the authenticator
(even programs you don't have the source for),
this module does give you great flexibility
(as said before, at the expense of sub-maximal speed).

=head1 AUTHOR

Mark Leighton Fisher <mark-fisher@fisherscreek.com>

=head1 COPYRIGHT

Copyright (c) 2002-2004 Mark Leighton Fisher, 
Fisher's Creek Consulting, LLC.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
