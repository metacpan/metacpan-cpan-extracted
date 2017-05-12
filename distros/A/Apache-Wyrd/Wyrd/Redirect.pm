#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Redirect;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);
use Apache::Constants qw(REDIRECT);
use Apache::Wyrd::Services::SAK qw(normalize_href);

=pod

=head1 NAME

Apache::Wyrd::Redirect - Redirect a browser via a Wyrd

=head1 SYNOPSIS

    <BASENAME::Redirect url="http://some.other.place.org/" />

    <BASENAME::Redirect>http://some.other.place.org/</BASENAME::Redirect>

=head1 DESCRIPTION

Forces a redirect.  The browser is redirected without the page being loaded.

=head2 HTML ATTRIBUTES

=over

=item url

The URL to redirect to.  It should be a complete URL.  If the URL is not
supplied, the enclosed text will be used as the URL.  Otherwise, the
enclosed text will not be processed.

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup method.

=cut

sub _setup {
	my ($self) = @_;
	my $url = $self->{'url'};
	$url ||= $self->{'_data'};
	$self->_raise_exception("No URL was supplied to Redirect") unless($url);
	$url = normalize_href($self->dbl, $url);
	$self->dbl->req->custom_response(REDIRECT, $url);
	$self->abort(REDIRECT);
}


=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;