package Apache::Session::Generate::ModUsertrack;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use CGI::Cookie;
use constant MOD_PERL => exists $ENV{MOD_PERL};

sub generate {
    my $session = shift;

    my $name = $session->{args}->{ModUsertrackCookieName} || 'Apache';
    my %cookies = CGI::Cookie->fetch;

    if (!exists $cookies{$name} && MOD_PERL) {
	# no cookies, try to steal from notes
	require Apache;
	my $r = Apache->request;
	%cookies = CGI::Cookie->parse($r->notes('cookie'));
    }

    unless ($cookies{$name}) {
	# still bad luck
	require Carp;
	Carp::croak('no cookie found. Make sure mod_usertrack is enabled.');
    }
    $session->{data}->{_session_id} = $cookies{$name}->value;
}

sub validate {
    my $session = shift;

    # remote_host (or remote_addr) + int
    $session->{data}->{_session_id} =~ /^[\d\w\.]+\.\d+$/
	or die "invalid session id: $session->{data}->{_session_id}";
}

1;
__END__

=head1 NAME

Apache::Session::Generate::ModUsertrack - mod_usertrack for session ID generation

=head1 SYNOPSIS

  use Apache::Session::Flex;

  tie %session, 'Apache::Session::Flex', $id, {
      Store     => 'MySQL',
      Lock      => 'Null',
      Generate  => 'ModUsertrack',
      Serialize => 'Storable',
      ModUsertrackCookieName => 'usertrack', # optional
  };

=head1 DESCRIPTION

Apache::Session::Generate::ModUsertrack enables you to use cookie
tracked by mod_usertrack as session id for Apache::Session
framework. This module fits well with long-term sessions, so better
using RDBMS like MySQL for its storage.

=head1 CONFIGURATION

This module accepts one extra configuration option.

=over 4

=item ModUsertrackCookieName

Specifies cookie name used in mod_usertrack. C<Apache> for default, so
change this if you change it via C<CookieName> directive in
mod_usertrack.

=back

=head1 LIMITATION WITHOUT MOD_PERL

This module first tries to fetch named cookie, but will in vain B<ONLY
WHEN> the HTTP request is the first one from specific client to the
mod_usertrack enabled Apache web server. It is because if the request
is for the first time, cookies are not yet baked on clients.

If you run scripts under mod_perl, this module tries to steal (not yet
baked) cookie from Apache request notes.

See L<Apache> for details.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::Flex>, mod_usertrack

=cut
