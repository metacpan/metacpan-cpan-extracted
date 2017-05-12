package Apache::AuthzSplitDomainUser;

use strict;
#use Apache::Constants ':common';
use Apache::Htgroup;

$Apache::AuthzSplitDomainUser::VERSION = '0.01';

############################################
# here is where we start the new code....
############################################
use mod_perl ;

# use Apache::Constants qw(:common);
# setting the constants to help identify which version of mod_perl
# is installed
use constant MP2 => ($mod_perl::VERSION >= 1.99);

# test for the version of mod_perl, and use the appropriate libraries
BEGIN {
        if (MP2) {
                require Apache::Const;
                Apache::Const->import(-compile => 'HTTP_UNAUTHORIZED','OK');
        } else {
                require Apache::Constants;
                Apache::Constants->import('HTTP_UNAUTHORIZED','OK');
        }
}
##################### end modperl code ######################

sub handler {
    my $r = shift;
    my $requires = $r->requires;
    return (MP2 ? Apache::OK : Apache::Constants::OK) unless $requires;

    my $name  = MP2 ? $r->user : $r->connection->user;
    my $error = ""; # Holds error message
    my $authz_username = $r->dir_config('authzUsername') || 'username';

    # Convert 'domain/username' to 'domain\username'
    $name =~ s|/|\\| if $name =~ m|/|;

    if ($authz_username eq 'domain\username') {
        if ($name !~ m/\\/) {
            #If we authzUsername is set to 'domain\username' and $name
            #is not of the form domain\username, then we prepend the domain 
            $name = $r->dir_config('myDOMAIN') . '\\' . $name;
        }
    }
    else {
       #If authzUsername is set to 'username' and $name has if the
       #form domain\username, then set $name = 'username'
       $name = $1 if $name =~ m/\w+\\(.+)/;
    }

    for my $req (@$requires) {
        my($require, @rest) = split /\s+/, $req->{requirement};

	#ok if user is one of these users
	if ($require eq "user") {
	    return (MP2 ? Apache::OK : Apache::Constants::OK) if grep $name eq $_, @rest;
	}
	#ok if user is simply authenticated
	elsif ($require eq "valid-user") {
	    return MP2 ? Apache::OK : 
	    		 Apache::Constants::OK;
	}
        #ok if user is in the 
        elsif ($require eq 'group') {
           unless ($r->dir_config('groupFile')) {
              $error = 'Apache::AuthzSplitDomainUser - Configuration error: no groupFile' . $r->uri;

	      $r->note_basic_auth_failure;
              MP2 ? $r->log_error($error) : $r->log_reason($error);

              return MP2 ? Apache::HTTP_UNAUTHORIZED : 
	                   Apache::Constants::HTTP_UNAUTHORIZED;
           }
           unless (-e $r->dir_config('groupFile')) {
              $error = 'Apache::AuthzSplitDomainUser - groupFile: ' . $r->dir_config('groupFile') . ' does not exist!';

              MP2 ? $r->log_error($error) : $r->log_reason($error);

              return MP2 ? Apache::HTTP_UNAUTHORIZED : 
                           Apache::Constants::HTTP_UNAUTHORIZED;
           }

           if ($@) {
              $error = 'Apache::AuthzSplitDomainUser - Unable to load Apache::Htgroup: ' . @$;
              MP2 ? $r->log_error($error) : $r->log_reason($error);

              return MP2 ? Apache::HTTP_UNAUTHORIZED : 
                           Apache::Constants::HTTP_UNAUTHORIZED;
              
           }

           my $htgrp = Apache::Htgroup->load($r->dir_config('groupFile'));

           foreach my $group (@rest) {
               return (MP2 ? Apache::OK : Apache::Constants::OK) 
                      if $htgrp->ismember($name,$group);
           }
        }
    }
    
    $r->note_basic_auth_failure;
    MP2 ? $r->log_error("user $name: not authorized", $r->uri) : 
    	   $r->log_reason("user $name: not authorized", $r->uri);
	
    return MP2 ? Apache::HTTP_UNAUTHORIZED : 
    		 Apache::Constants::HTTP_UNAUTHORIZED;

}

1;

__END__

=head1 NAME

Apache::AuthzSplitDomainUser - mod_perl module for checking the htgroup file while
		       allowing you to manipulate with perl


=head1 SYNOPSIS

    <Directory /foo/bar>
    # Optional Variables
    PerlSetVar groupFile /path/to/htgroups
    # Set the format of the username to check against
    # defaults to username
    PerlSetVar authzUsername username or domain\username

    PerlAuthzHandler Apache::AuthzSplitDomainUser

    # Standard require stuff, only user and 
    # valid-user work currently
    require valid-user

    # Optional, reqires that you have Apache::Htgroup
    # require group groupname
    </Directory>

    These directives can be used in a .htaccess file as well.

    If you wish to use your own PerlAuthzHandler then the require 
    directive should follow whatever handler you use.

=head1 DESCRIPTION

This module was written so that we could hijack the Authz phase from Apache and 
modify values that are passed to the Authz Handler with perl.  The initial concept
was to deal with a problem that we are seeing from winXP boxes that are sending 
forward DOMAIN\username to Apache.  These obviously fail when checked against an
authentication, or authorization, scheme where the syntax is simply username. 

= item PerlSetVar groupFile

Set this to the path of the htgroup file you wish this module
to check in.  It allows you to specify your users in groups
found on the web server, as opposed to groups within Active 
Directory, etc. 

= item PerlSetVar authzUsername

Set this to "username" or "domain\username" depending on your preference.
(This simply formats the input username to allowing checking the username 
as "domain\username" or "username".)  For example:

# speeves is a DOMAIN user of DOMAIN
domain\username =>  DOMAIN\speeves 

# speeves is a DOMAIN user of DOMAIN,
# but the server administrator wants to
# check this user against groups in the 
# htgroup file as: 

# groupname: speeves userA userB

username => speeves

If you allow users to use B<Domain\Username> and restrict access
using the C<require user username> or C<require group groupname> make
sure to set the username with the domain included. The authorization 
phase will be looking for C<Domain\Username> string.

Example: require user mydomain\ramirezc

=head2 Note
  
If you are using this module please let me know, I'm curious how many
people there are that need this type of functionality.

=head1 AUTHOR

Shannon Eric Peevey <speeves@unt.edu>

=head1 COPYRIGHT

Copyright (c) 2004 Shannon Eric Peevey.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
