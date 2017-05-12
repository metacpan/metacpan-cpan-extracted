# $Id: AuthenDBMCache.pm,v 1.17 2006/03/02 21:13:21 reggers Exp $
#
# Author          : Reg Quinton
# Created On      : 23-Sep-2002 
# Derivation      : from AuthenCache by Jason Bodnar, Christian Gilmore
# Status          : Functional
#
# PURPOSE
#    User Authentication Cache implemented in a DBM database.

# Package name

package Apache2::AuthenDBMCache;

# Required libraries

use mod_perl2 ;
use Apache2::Access ;
use Apache2::Log ;
use Apache2::RequestRec ;
use Apache2::RequestUtil ;
use Apache2::Const -compile => qw(HTTP_UNAUTHORIZED HTTP_INTERNAL_SERVER_ERROR DECLINED HTTP_FORBIDDEN OK) ;
use APR::Table ;
use Carp;
use strict;
use warnings FATAL => 'all';

# Global variables

$Apache2::AuthenDBMCache::VERSION = '0.01';

# local subroutines and data not exported to anyone

my($cache)= "/var/cache/authen-web/cache";

# key index to value -- an expiration date.

sub GetCache {
    my (%DBM);    my($key)=@_;

    croak "No access to $cache"
	unless dbmopen(%DBM,$cache,0600);

    my ($tmp)=$DBM{$key}; dbmclose(%DBM);

    return ($tmp);
}

sub SetCache {
    my (%DBM);    my ($key,$val)=@_;

    croak "No access to $cache"
	unless dbmopen(%DBM,$cache,0600);

    $DBM{$key}=$val;    dbmclose(%DBM);
}

sub ExpireCache {
    my ($file) = @_;
    $cache=$file if $file;

    my (%DBM,$key,$now);

    croak "No access to $cache"
	unless dbmopen(%DBM,$cache,0600);

    $now=time();

    foreach $key (keys %DBM) {
	delete $DBM{$key} if $DBM{$key} < $now;
    }

    dbmclose(%DBM);

}

# squish userid, password, config and realm into a hash

sub Digest {
    use Digest::MD5;

    my ($string)=Digest::MD5->md5_hex(@_);
    $string=~ s/[^0-9a-zA-Z]//g;
    return($string);
}

# handler: hook into Apache2/mod_perl2 API

sub handler {
  my $r = shift;
  my $tmp;

  # Get response and password

  my($status, $passwd) = $r->get_basic_auth_pw;
  return Apache2::Const::OK unless $r->is_initial_req;
  return $status unless ($status == Apache2::Const::OK); # e.g. HTTP_UNAUTHORIZED
  # Get configuration... are we debugging?

  my $debug = (lc($r->dir_config('AuthenDBMCache_Debug')) eq 'on');
  $cache=$tmp if ($tmp = $r->dir_config('AuthenDBMCache_file'));

  # Get username and Realm

  my $realm = lc($r->auth_name);
  my $user  = lc($r->user);
  return Apache2::Const::DECLINED  unless ($user);

  # Get all parameters -- current config (to limit cache poison).

  my $config=$r->dir_config(); $config=join(":",%$config);

  # construct a unique key for userid/realm/config/password

  my $key   = Digest("$user $realm $config $passwd");

  $r->log->debug("handler: user=$user") if $debug;

  # if there is an expiration date for that key

  if (my $exp = GetCache("$key")) {
      if ($exp < time()) {
	  $r->log->debug("handler: user cache stale") if $debug;
	  $r->push_handlers(PerlFixupHandler => \&manage_cache);
	  return Apache2::Const::DECLINED;
      }

      # Hash hasn't expired, password is ok, clear the stacked handlers

      $r->log->debug("handler: $user cache hit") if $debug;
      $r->set_handlers(PerlAuthenHandler => undef);
      return Apache2::Const::OK;
  }

  # that key is not in cache

  $r->log->debug("handler: user cache miss") if $debug;
  $r->push_handlers(PerlFixupHandler => \&manage_cache);
  return Apache2::Const::DECLINED;
}

# manage_cache: insert new entries into the cache

sub manage_cache {
  my $r = shift;
  my $tmp;

  # Get configuration

  my $ttl   = $r->dir_config('AuthenDBMCache_TTL') || 3600;
  my $debug = (lc($r->dir_config('AuthenDBMCache_Debug')) eq 'on');
  $cache=$tmp if ($tmp = $r->dir_config('AuthenDBMCache_file'));

  # Get response and password

  my ($status, $passwd) = $r->get_basic_auth_pw;

  # Get username and Realm

  my $realm = lc($r->auth_name);
  my $user  = lc($r->user);
  return Apache2::Const::DECLINED  unless ($user);

  # Get all parameters -- current config

  my $config=$r->dir_config(); $config=join(":",%$config);

  # construct a unique key for userid/realm/config/password

  my $key   = Digest("$user $realm $config $passwd");

  $r->log->debug("manage_cache: user=$user") if $debug;

  # Add the key to the cache with an expiration date

  SetCache("$key",time() + $ttl);

  $r->log->debug("manage_cache: $user cache add") if $debug;

  return Apache2::Const::OK;
}

1;

__END__

# Documentation - try 'pod2text AuthenDBMCache.pm'

=head1 NAME

Apache2::AuthenDBMCache - Authentication caching

=head1 SYNOPSIS

 # In your httpd.conf

 PerlModule Apache2::AuthenDBMCache

 # In httpd.conf or .htaccess:

 AuthName Name
 AuthType Basic

 PerlAuthenHandler Apache2::AuthenDBMCache <Primary Authentication Module>

 # Typical constraints one of these

 require valid-user
 require user larry moe curly
 require group stooges

 # Optional parameters/Defaults are listed to the right.

 PerlSetVar AuthenDBMCache_File /file-path # Default: /var/cache/authen-web
 PerlSetVar AuthenDBMCache_TTL         900 # Default: 3600 sec
 PerlSetVar AuthenDBMCache_Debug        On # Default: Off

=head1 DESCRIPTION

B<Apache2::AuthenDBMCache> implements a caching mechanism in order to
speed up authentication and to reduce the usage of system
resources. It must be used in conjunction with a regular mod_perl2
authentication module (we use it to accelerate AuthenURL and AuthenMSAD
methods but it can be used with any perl authentication module).

When a authorization request is received this handler uses a DBM data
base cache to answer the request. Each entry in the cache is indexed
by a key which is a hash of user name, the authentication "realm", the
authentication parameters and the password. The value at the key is an
expiration date. If the supplied user name and password hash to a key
which exists and has not expired then the handler returns OK and
clears the downstream Authen handlers from the stack. Otherwise, it
returns DECLINED and allows the next PerlAuthenHandler in the stack to
be called.

After the primary authentication handler completes with an OK,
AuthenDBMCache adds the new hash to the cache with an appropriate
expiration date.

=head1 CONFIGURATION OPTIONS

The following variables can be defined within the configuration
of Directory, Location, or Files blocks or within .htaccess
files.

=head2 PerlSetVar AuthenDBMCache_File /var/file/path

The B<AuthenDBMCache_File> variable specifices an alternate cache
location.  The default is /var/cache/authen-web/cache -- the cache
database and the direcotries containing the cache need to be
protected.

=head2 PerlSetVar AuthenDBMCache_TTL 3600

The B<AuthenDBMCache_TTL> variable contains the "Time to Live" in
seconds of entries within the cache.  The default value is one hour
(3600 seconds). When entries are created in the cache they're marked
with an expiration date calculated from the TTL value.

=head2 PerlSetVar AuthenDBMCache_Debug off

If the B<AuthenDBMCache_Debug> variable is set to "on" some debugging
messages are logged.

=head1 FUNCTIONS

The function B<Apache2::AuthenDBMCache::ExpireCache> will expire all
cache entries that are no longer current. However, it's much easier to
just clobber the cache file.

=head1 BUGS/BEWARE

The cache and directory holding the cache (in the
/var/cache/authen-web directory) should exist and belong to the userid
of the web server. They should be protected so that nobody else can
read them. The module will croak if it cannot access the cached
authentication data.

We make no effort to lock the database. The worst case that can happen
is we return a false negative and that has no serious consequences.

Other processes are required to purge the cache of entries which have
expired -- you can clear the entire cache periodically (ie. remove the
file or clear it with /dev/null) or use the
B<Apache2::AuthenDBMCache::ExpireCache> function to clear entries in
the cache.

A caching mechanism is vulnerable to cache-poisoning -- we have made
an effort to prevent that but you should be cautious. Especially on
multi-user systems with users who aren't trustworthy.

The cache is not indexed by "userid" and the key is a one way hash
that includes the userid, password and more -- that is intentional. We
don't want bad guys cracking passwords out of the cache.

=head1 SEE ALSO

httpd(8), mod_perl2(1), Digest::MD5

=head1 AUTHORS

Reg Quinton E<lt>reggers@uwaterloo.caE<gt> from AuthenCache by Jason Bodnar
and Christian Gilmore.

=head1 COPYRIGHT

Copyright (C) 2002-2006, Reg Quinton. AuthenCache Copyright (C) 1998-2001,
Jason Bodnar.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
