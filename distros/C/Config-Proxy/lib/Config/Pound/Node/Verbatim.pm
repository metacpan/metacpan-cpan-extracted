package Config::Pound::Node::Verbatim;
use parent 'Config::Proxy::Node';

=head1 NAME

Config::Pound::Node::Verbatim - A verbatim line from Pound ACL.

=head1 DESCRIPTION

Objects of this class represent verbatim context embedded in
a Pound configuration.  Currently it is used to represent contents of
B<ConfigText> statement in B<Resolver> section.

B<ConfigText> is a section statement, that contains the resolver
configuration (as described in B<resolv.conf>(5)) verbatim.  Each line
from that section is represented by a single object of this class.

=head1 METHODS

See L<Config::Proxy::Node> for a discussion of methods.  Notes for this
class:

=head2 kw

This method returns an empty string.

=head2 orig

This method returns the actual line read from the configuration file.

=head1 SEE ALSO

L<Config::Pound>, L<Config::Proxy::Node>, L<Text::Locus>.

=cut


1;

	
    
