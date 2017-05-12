package Apache::AuthDigest::API::Multi;

use Apache::Log;

use Apache::AuthDigest::API;

use 5.006;

use strict;

our $VERSION = '0.01';
our @ISA = qw(Apache::AuthDigest::API);

sub note_digest_auth_failure {

  my $r = shift;

  my $log = $r->server->log;

  my $auth_name = $r->auth_name;
  my $header_type = $r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate';
  my $nonce = $r->request_time;

  my $header_info = qq!Digest realm="$auth_name", nonce="$nonce"!;

  $r->err_headers_out->add($header_type => $header_info);
}

sub note_basic_auth_failure {

  my $r = shift;

  my $log = $r->server->log;

  my $auth_name = $r->auth_name;
  my $header_type = $r->proxyreq ? 'Proxy-Authenticate' : 'WWW-Authenticate';

  my $header_info = qq!Basic realm="$auth_name"!;

  $r->err_headers_out->add($header_type => $header_info);
}

1;

__END__

=head1 NAME

Apache::AuthDigest::API::Multi - allow for multiple WWW-Authenticate headers

=head1 SYNOPSIS

  PerlModule Apache::AuthDigest::API::Multi
  PerlModule My::MultiAuthenticator

  <Location /protected>
    PerlAuthenHandler My::MultiAuthenticator
    Require valid-user
    AuthName "cookbook"
  </Location>

=head1 DESCRIPTION

coming soon...

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3), Apache::AuthDigest(3)

=head1 AUTHORS

Geoffrey Young E<lt>geoff@modperlcookbook.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2002, Geoffrey Young

All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 HISTORY

This code is derived from the I<Cookbook::DigestAPI> module,
available as part of "The mod_perl Developer's Cookbook".

For more information, visit http://www.modperlcookbook.org/

=cut
