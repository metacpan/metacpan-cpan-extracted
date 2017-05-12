package Apache::ACEProxy::UTF8_RACE;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Apache::ACEProxy);

use Convert::RACE qw(to_race);
use Unicode::String qw(utf8);

sub encode {
    my($class, $domain) = @_;
    return to_race(utf8($domain)->utf16);
}

1;
__END__

=head1 NAME

Apache::ACEProxy::UTF8_RACE - IDN compatible RACE proxy server

=head1 SYNOPSIS

  # in httpd.conf
  PerlTransHandler Apache::ACEProxy::UTF8_RACE

=head1 DESCRIPTION

Apache::ACEProxy::UTF8_RACE is one of the implementations of
Apache::ACEProxy. This module encodes UTF8 encoded domain names into
RACE encoding, specified in C<draft-ietf-idn-race-03.txt>.

RACE encoding is currently tested domain name encoding by some
regitrars. Note that this may (possibly, will) be changed if an ACE is
chosen as the standard. See http://www.i-d-n.net/ for the details.

=head1 CAVEATS

Works well only for browsers which sends URL as UTF8. See
L<Apache::ACEProxy/"CAVEATS"> for details.

=head1 AUTHOR

Tastuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module comes with NO WARANTY.

=head1 SEE ALSO

L<Unicode::String>, L<Convert::RACE>, L<Apache::ACEProxy>

=cut
