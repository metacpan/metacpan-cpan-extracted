package Apache::AuthDigest;

use Apache::Constants qw(OK DECLINED AUTH_REQUIRED DECLINE_CMD);
use Apache::File;
use Apache::Log;
use Apache::ModuleConfig;

use Apache::AuthDigest::API;

use DynaLoader;
use strict;

our $VERSION = '0.022';
our @ISA = qw(DynaLoader);

__PACKAGE__->bootstrap($VERSION);

sub handler {

  my $r = Apache::AuthDigest::API->new(shift);

  my $log = $r->server->log;

  if (Apache->module('mod_digest.c')) {
    $log->info('Apache::AuthDigest - deferring to mod_digest');

    return DECLINED;
  }

  my $cfg = Apache::ModuleConfig->get($r, __PACKAGE__);

  my ($status, $response) = $r->get_digest_auth_response;

  return $status unless $status == OK;

  my $password_file = $cfg->{_password_file};

  my $fh = Apache::File->new($password_file);

  unless ($fh) {
    $log->error("Apache::AuthDigest - could not open ",
                 "password file '$password_file'");

    return DECLINED;
  }

  my $digest = get_user_credentials($r->user, $r->auth_name, $fh);

  unless ($digest) {
    $log->error("Apache::AuthDigest - user '", $r->user,
                "' not found in password file '$password_file'");

    $r->note_digest_auth_failure;
    return AUTH_REQUIRED;
  }

  return OK if $r->compare_digest_response($response, $digest);

  $log->error("Apache::AuthDigest - user '", $r->user,
              "' password mismatch");

  $r->note_digest_auth_failure;
  return AUTH_REQUIRED;
}

sub get_user_credentials {

  my ($user, $realm, $fh) = @_;

  my ($username, $userrealm, $digest) = ();

  while (my $line = <$fh>) {
    ($username, $userrealm, $digest) = split /:/, $line;

    last if ($user eq $username && $realm eq $userrealm);

    $digest = undef;  # in case we fall through
  }

  chomp $digest;

  return $digest;
}


sub AuthDigestFile ($$$) {

  my ($cfg, $parms, $arg) = @_;

  return DECLINE_CMD if Apache->module('mod_digest.c');

  die "Invalid AuthDigestFile $arg!" unless -f $arg;

  $cfg->{_password_file}  = $arg;
}

sub DIR_CREATE {
  # Initialize an object instead of using the mod_perl default.

  my $class = shift;
  my $self  = { _password_file => undef };

  return bless $self, $class;
}

sub DIR_MERGE {
  # Allow the subdirectory to inherit the configuration
  # of the parent, while overriding with anything more specific.

  my ($parent, $current) = @_;

  my %new = (%$parent, %$current);

  return bless \%new, ref($parent);
}

1;

__END__

=head1 NAME

Apache::AuthDigest - reimplementation of mod_digest.c in Perl

=head1 SYNOPSIS

  PerlModule Apache::AuthDigest

  <Location /protected>
    PerlAuthenHandler Apache::AuthDigest
    Require valid-user
    AuthType Digest
    AuthName "cookbook"
    AuthDigestFile .htdigest
  </Location>

=head1 DESCRIPTION

Apache::AuthDigest is a reimplementation of mod_digest,
the standard Apache module that implements Digest authentication.
For more information on Digest authentication, see RFC 2617:
  ftp://ftp.isi.edu/in-notes/rfc2617.txt

To do this, Apache::AuthDigest uses an API provided by
Apache::AuthDigest::API, which is included in this distribution.
see the Apache::AuthDigest::API manpage if you want to implement
a Digest authentication scheme that uses something other than
a flat file.

=head1 EXAMPLE

The configuration for Apache::AuthDigest is relatively simple:

  PerlModule Apache::AuthDigest

  <Location /protected>
    PerlAuthenHandler Apache::AuthDigest
    Require valid-user
    AuthType Digest
    AuthName "cookbook"
    AuthDigestFile .htdigest
  </Location>

please note that Apache::AuthDigest does not configure a handler
for the authorization phase, which is a bit different than mod_digest.
if you want to use something other than Require valid-user, you will
need to use Apache::AuthzDigest:

  PerlModule Apache::AuthDigest
  PerlModule Apache::AuthzDigest

  <Location /protected>
    PerlAuthenHandler Apache::AuthDigest
    PerlAuthzHandler Apache::AuthzDigest
    Require user foo
    AuthType Digest
    AuthName "cookbook"
    AuthDigestFile .htdigest
  </Location>

see the Apache::AuthzDigest manpage for more information.

=head1 NOTES

this module essentially mimics the Digest implementation provided
by mod_digest.c that ships with Apache.  there is another
implementation, classified as "experimental" that also ships with
Apache, mod_auth_digest.c, which is more complete wrt RFC 2617.
of particular interest is that the mod_digest implementation does
not work with MSIE (so neither does this implemenation).  at some
point, Apache::AuthDigest::API::Full will implement a completely
compliant API - this will have to do for now.

Apache::AuthDigest will decline to process the transaction
if mod_digest.c is detected, allowing the faster mod_digest
implementation to control the fate of the request.

=head1 FEATURES/BUGS

none that I know of yet, but consider this alphaware.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3), Apache::AuthDigest(3)

=head1 AUTHORS

Geoffrey Young E<lt>geoff@modperlcookbook.orgE<gt>

Paul Lindner E<lt>paul@modperlcookbook.orgE<gt>

Randy Kobes E<lt>randy@modperlcookbook.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2002, Geoffrey Young, Paul Lindner, Randy Kobes.  

All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 HISTORY

This code is derived from the I<Cookbook::DigestAPI> module,
available as part of "The mod_perl Developer's Cookbook".

For more information, visit http://www.modperlcookbook.org/

=cut
