package Apache::ACEProxy::SJIS_RACE;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Apache::ACEProxy);

use Convert::RACE qw(to_race);
use Jcode ();

sub encode {
    my($class, $domain) = @_;
    return to_race(Jcode->new($domain, 'sjis')->ucs2);
}

1;
__END__

=head1 NAME

Apache::ACEProxy::SJIS_RACE - IDN compatible RACE proxy server

=head1 SYNOPSIS

  # in httpd.conf
  PerlTransHandler Apache::ACEProxy::SJIS_RACE

=head1 DESCRIPTION

Apache::ACEProxy::SJIS_RACE is one of the implementations of
Apache::ACEProxy. This module encodes Shift_JIS encoded domain names
into RACE encoding.

=head1 CAVEATS

Works well only for browsers which sends URL as Shift_JIS. Candidates
are: Windows Netscape 4.x, Windows Internet Explorer with "Always send
URL as UTF8" setting B<OFF>. See L<Apache::ACEProxy/"CAVEATS"> for
details.

You need Jcode module to get this work.

=head1 AUTHOR

Tastuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module comes with NO WARANTY.

=head1 SEE ALSO

L<Jcode>, L<Convert::RACE>, L<Apache::ACEProxy>

=cut
