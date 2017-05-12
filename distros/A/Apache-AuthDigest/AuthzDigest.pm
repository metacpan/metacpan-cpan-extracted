package Apache::AuthzDigest;

use Apache::Constants qw(OK DECLINED AUTH_REQUIRED);
use Apache::Log;

use Apache::AuthDigest::API;

use strict;

sub handler {

  my $r = Apache::AuthDigest::API->new(shift);

  my $log = $r->server->log;

  if (Apache->module('mod_digest.c')) {
    $log->info('Apache::AuthzDigest - deferring to mod_digest');

    return DECLINED;
  }

  my $user = $r->user;

  unless ($user) {
    $log->error('Apache::AuthzDigest - no user found!');

    $r->note_digest_auth_failure;
    return AUTH_REQUIRED;
  }

  foreach my $requires (@{$r->requires}) {
    my ($directive, @list) = split " ", $requires->{requirement};

    # We're ok if only valid-user was required.
    return OK if lc($directive) eq 'valid-user';

    # Likewise if the user requirement was specified and
    # we match based on what we already know.
    return OK if lc($directive) eq 'user' && grep { $_ eq $user } @list;
  }

  # if we get here we couldn't validate the user
  $log->error("Apache::AuthzDigest - user '", $r->user,
              "' not allowed");

  $r->note_digest_auth_failure;
  return AUTH_REQUIRED;
}

1;

__END__

=head1 NAME

Apache::AuthzDigest - pick up the authorization pieces of mod_digest

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Apache::AuthzDigest picks up the authorization pieces of
mod_digest that Apache::AuthDigest leaves behind, namely
the checking behind the "Require user" directive.

see the Apache::AuthDigest manpage for more information
on Apache::AuthDigest, which is the real driver here - 
Apache::AuthzDigest doesn't do much, really.

=head1 EXAMPLE

see the SYNOPSIS.

=head1 NOTES

Apache::AuthzDigest will decline to process the transaction
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

This code is derived from the I<Cookbook::AuthzRole> module,
available as part of "The mod_perl Developer's Cookbook".

For more information, visit http://www.modperlcookbook.org/

=cut
