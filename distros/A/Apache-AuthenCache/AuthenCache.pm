# $Id: AuthenCache.pm,v 1.6 2001/01/03 19:17:56 cgilmore Exp $
#
# Author          : Jason Bodnar, Christian Gilmore
# Created On      : Long ago
# Status          : Functional
#
# PURPOSE
#    User Authentication Cache
#
###############################################################################


# Package name
package Apache::AuthenCache;


# Required libraries
use strict;
use mod_perl ();
use Apache::Constants qw(OK AUTH_REQUIRED DECLINED DONE);
use Apache::Log ();
use IPC::Cache;


# Global variables
$Apache::AuthenCache::VERSION = '0.05';


###############################################################################
###############################################################################
# handler: hook into Apache/mod_perl API
###############################################################################
###############################################################################
sub handler {
  my $r = shift;
  return OK unless $r->is_initial_req; # only the first internal request

  # Get configuration
  my $nopasswd = $r->dir_config('AuthenCache_NoPasswd') || 'off';
  my $encrypted = $r->dir_config('AuthenCache_Encrypted') || 'on';
  my $casesensitive = $r->dir_config('AuthenCache_CaseSensitive') || 'on';
  my $cache_time_limit = $r->dir_config('AuthenCache_CacheTime');
  my $auth_name = $r->auth_name;

  # Clear for paranoid security precautions
  $r->notes('AuthenCache' => 'miss');

  # Get response and password
  my($res, $passwd_sent) = $r->get_basic_auth_pw;
  return $res if $res; # e.g. HTTP_UNAUTHORIZED

  # Get username
  my $user_sent = $r->connection->user;
  # If the user left the username field blank, we must catch it and DECLINE
  # for the downstream handler
  unless ($user_sent) {
    return DECLINED;
  }
  $r->log->debug("handler: username=$user_sent");

  # Do we want Windows-like case-insensitivity?
  if ($casesensitive eq 'off') {
    $user_sent = lc($user_sent);
  }

  # Create or retreive the cache (if already created)
	# Use the Realm name ($auth_name) for different caches for each realm
  my $cache = IPC::Cache->new({ namespace => $auth_name });
  my $passwd = $cache->get($user_sent);
  # Is the user in the cache
  if ($passwd) {
    $r->log->debug("handler: using cached passwd for $user_sent");

    # Allow no password
    if ($nopasswd eq 'on' and not length($passwd)) {
      $r->log->debug("handler: no password required; returning DONE");
      # Must return DECLINED so that user has a chance to put in
      # no password
      return DONE;
    }

    # If nopasswd is off, reject user
    unless (length($passwd_sent) and length($passwd)) {
      $r->log->debug("handler: user $user_sent: empty password(s) rejected" .
		     $r->uri);
      # Must return DECLINED so that user has a chance to put in a
      # new password
      return DECLINED;
    }

    # Is crypt is needed
    if ($encrypted eq 'on') {
      my $salt = substr($passwd, 0, 2);
      $passwd_sent = crypt($passwd_sent, $salt);
    }

    unless ($passwd_sent eq $passwd) {
      $r->log->debug("AuthenCache::handler: user $user_sent: " . 
		     "password mismatch" .  $r->uri);
      # Must return DECLINED so that user has a chance to put in a
      # new password
      return DECLINED;
    }

    # Password matches so end stage
    # The required patch was not introduced in 1.26. It is no longer
    # promised to be included in any timeframe. Commenting out.
    # if ($mod_perl::VERSION > 1.25) {
      # I should be able to use the below lines and be done with it.
      # Since set_handlers() doesn't work properly until 1.26
      # (according to Doug MacEachern) I have to work around it by
      # cobbling together cheat sheets for the subsequent handlers
      # in this phase. I get the willies about the security implications
      # in a general environment where you might be using someone else's
      # handlers upstream or downstream...
    $r->log->debug("handler: user in cache and password matches; ",
		   "returning OK and clearing authen handler stack");
    $r->set_handlers(PerlAuthenHandler => undef);
    # } else {
    #  $r->log->debug("handler: user in cache and password matches; ",
    #		     "returning OK and setting notes");
    #  $r->notes('AuthenCache' => 'hit');
    #}
    return OK;
  } # End if()

  # User not in cache
  $r->log->debug("handler: user/group not in cache; returning DECLINED");
  return DECLINED;
}

###############################################################################
###############################################################################
# manage_cache: insert new entries into the cache
###############################################################################
###############################################################################
sub manage_cache {
  my $r = shift;
  return OK unless $r->is_initial_req; # only the first internal request

  # Get response and password
  my ($res, $passwd_sent) = $r->get_basic_auth_pw;
  return $res if $res; # e.g. HTTP_UNAUTHORIZED

  # Get username
  my $user_sent = $r->connection->user;
  $r->log->debug("manage_cache: username=$user_sent");

  # The required patch was not introduced in 1.26. It is no longer
  # promised to be included in any timeframe. Commenting out.
  # unless ($mod_perl::VERSION > 1.25) {
    # The below test is dubious. I'm putting it in as a hack around the
    # problems with set_handlers not working quite right until 1.26 is
    # released (according to Doug MacEachern).
  my $cache_result = $r->notes('AuthenCache');
  if ($cache_result eq 'hit') {
    $r->log->debug("manage_cache: upstream cache hit for username=",
		   "$user_sent");
    return OK;
  #  }
  }

  # Get configuration
  my $no_passwd = $r->dir_config('AuthenCache_NoPasswd') || 'off';
  my $encrypted = $r->dir_config('AuthenCache_Encrypted') || 'on';
  my $casesensitive = $r->dir_config('AuthenCache_CaseSensitive') || 'on';
  my $cache_time_limit = $r->dir_config('AuthenCache_CacheTime');
  my $auth_name = $r->auth_name;

  # Do we want Windows-like case-insensitivity?
  if ($casesensitive eq 'off') {
    $user_sent = lc($user_sent);
    $passwd_sent = lc($passwd_sent);
  }

  # Do we need to crypt the password?
  if ($encrypted eq 'on') {
    my @alphabet = ('a' .. 'z', 'A' .. 'Z', '0' .. '9', '.', '/');
    my $salt = join ('', @alphabet[rand (64), rand (64)]);
    $passwd_sent = crypt($passwd_sent, $salt);
  }

  # Add the user to the cache
	# Use the Realm name to have different caches for each realm
  my $cache = IPC::Cache->new({ namespace => $auth_name });
  $cache->set($user_sent, $passwd_sent, $cache_time_limit);
  $r->log->debug("manage_cache: added $user_sent to the cache");

  return OK;
}

1;

__END__

# Documentation - try 'pod2text AuthenCache.pm'

=head1 NAME

Apache::AuthenCache - Authentication caching used in conjuction
with a primary authentication module (Apache::AuthenDBI,
Apache::AuthenLDAP, etc.)


=head1 SYNOPSIS

 # In your httpd.conf
 PerlModule Apache::AuthenCache

 # In httpd.conf or .htaccess:
 AuthName Name
 AuthType Basic

 PerlAuthenHandler Apache::AuthenCache <Primary Authentication Module> Apache::AuthenCache::manage_cache

 require valid-user # Limited to valid-user

 # Optional parameters
 # Defaults are listed to the right.
 PerlSetVar AuthenCache_CacheTime     900 # Default: indefinite
 PerlSetVar AuthenCache_CaseSensitive Off # Default: On
 PerlSetVar AuthenCache_Encrypted     Off # Default: On
 PerlSetVar AuthenCache_NoPasswd      On  # Default: Off

=head1 DESCRIPTION

B<Apache::AuthenCache> implements a caching mechanism in order to
speed up authentication and to reduce the usage of system
resources. It must be used in conjunction with a regular mod_perl
authentication module (it was designed with AuthenDBI and
AuthenLDAP in mind).  For a list of mod_perl authentication
modules see:

http://www.cpan.org/modules/by-module/Apache/apache-modlist.html

When a request that requires authorization is received,
AuthenCache::handler looks up the REMOTE_USER in a perl-realm shared-memory
cache (using IPC::Cache) and compares the cached password to the
sent password. A new cache is created for the first request in a realm or if
the realm's cache has expired. If the passwords match, the handler
returns OK and clears the downstream Authen handlers from the
stack. Otherwise, it returns DECLINED and allows the next
PerlAuthenHandler in the chain to be called.

After the primary authentication handler completes with an OK,
AuthenCache::manage_cache adds the new user to the cache.

=head1 CONFIGURATION OPTIONS

The following variables can be defined within the configuration
of Directory, Location, or Files blocks or within .htaccess
files.

=over 4
 
=item B<AuthenCache_CacheTime>

This directive contains the number of seconds before the cache is
expired. Default is an indefinite time limit.

=back

=over 4
 
=item B<AuthenCache_CaseSensitive>
 
If this directive is set to 'Off', userid matches will be case
insensitive. Default is 'On'.
 
=back

=over 4
 
=item B<AuthenCache_Encrypted>
 
If this directive is set to 'Off', passwords are not encrypted.
Default is 'On', ie passwords use standard Unix crypt.
 
=back

=over 4
 
=item B<AuthenCache_NoPasswd>
 
If this directive is set to 'On', passwords must be blank.
Default is 'Off'.
 
=back

=head1 PREREQUISITES

mod_perl 1.11_01 is required. IPC::Cache is also required.

=head1 SEE ALSO

crypt(3c), httpd(8), mod_perl(1)

=head1 AUTHORS

Jason Bodnar <jason@shakabuku.org>
Christian Gilmore <cgilmore@tivoli.com>

=head1 COPYRIGHT

Copyright (C) 1998-2001, Jason Bodnar

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

###############################################################################
###############################################################################
# $Log: AuthenCache.pm,v $
# Revision 1.6  2001/01/03 19:17:56  cgilmore
# rewrote documentation and inserted code to handle pre-1.26 mod_perl
#
# Revision 1.5  2000/11/06 19:33:04  cgilmore
# added catching of empty username field
#
# Revision 1.4  2000/10/18 16:31:12  cgilmore
# removed note_basic_auth_failure lines
#
# Revision 1.3  2000/08/03 21:12:07  cgilmore
# changed from AUTH_REQUIRED to DECLINED to allow for new passwords
# to enter the cache
#
# Revision 1.2  2000/07/18 18:58:05  cgilmore
# corrected mis-use of log (commas instead of periods)
#
# Revision 1.1  2000/07/12 18:32:07  cgilmore
# Initial revision
#
###############################################################################
###############################################################################

