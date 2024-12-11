package Config::Pound::Node::IP;
use parent 'Config::Proxy::Node';

=head1 NAME

Config::Pound::Node::IP - IP address or CIDR from Pound ACL.

=head1 DESCRIPTION

Objects of this type represent IP addresses or CIDRs from an
B<ACL> section in Pound configuration section.

=head1 METHODS

See B<Config::Proxy::Node> for a discussion of methods.  In addition to
those the following method is supported by nodes of this type:

=head2 ip

    $addr = $node->ip

Returns the IP address (CIDR) in unquoted form.

=head1 SEE ALSO

L<Config::Pound>, L<Config::Proxy::Node>, L<Text::Locus>.

=cut

sub ip { shift->kw }

1;

	
    
