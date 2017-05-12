# $Id: Hostname.pm,v 1.3 2004/06/24 18:28:37 nachbaur Exp $

package Apache::AxKit::StyleChooser::Hostname;

use strict;
use Apache::Constants qw(OK);
our $VERSION = 0.01;

sub handler {
	my $r = shift;
	
	my $style = $r->hostname();

	if ($style && $style ne $r->server->server_hostname()) {
        $style =~ s/^www\.//; # trim off useless "www" prefix
		$r->notes('preferred_style', $style);
	}
	return OK;
}

1;
__END__

=head1 NAME

Apache::AxKit::StyleChooser::Hostname - Choose stylesheet using the hostname of the HTTP request

=head1 SYNOPSIS

  AxAddPlugin Apache::AxKit::StyleChooser::Hostname

=head1 DESCRIPTION

This module lets you pick a stylesheet based on the domain name
of the HTTP request.  To use it, simply add this module as an
AxKit plugin that will be run before main AxKit processing is
done.

  AxAddPlugin Apache::AxKit::StyleChooser::Hostname  

Then simply by referencing your xml files as follows:

   http://xml.server.com/myfile.xml

or

   http://www.server.com/myfile.xml

or whatever site aliases you have configured.  In the above example,
the two styles that will be used will be C<xml.server.com> and C<server.com>,
respectively.

See the B<AxStyleName> AxKit configuration directive
for more information on how to setup named styles.

=head1 SEE ALSO

AxKit.

=cut

