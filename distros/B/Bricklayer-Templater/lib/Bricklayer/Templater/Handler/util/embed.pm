#------------------------------------------------------------------------------- 
# 
# File: embed.pm
# Version: 0.1
# Author: Jeremy Wall
# Definition: allows us to embed code in the containing template
#
#--------------------------------------------------------------------------
package Bricklayer::Templater::Handler::util::embed;
use Bricklayer::Templater::Handler;
use base qw(Bricklayer::Templater::Handler);

=head1 embedded code tag handler

Will run and coderef passed into it and return the results for placement in the template.

=cut

sub run {
	my ($self, $embed) = @_;
	
	if (ref($embed) eq 'CODE') {
		return &$embed();
	} else {
		return $embed;
	}
	return;
}

return 1;
