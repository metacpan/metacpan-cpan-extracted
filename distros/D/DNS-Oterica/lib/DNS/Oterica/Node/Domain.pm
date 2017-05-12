package DNS::Oterica::Node::Domain;
# ABSTRACT: a domain node
$DNS::Oterica::Node::Domain::VERSION = '0.304';
use Moose;
extends 'DNS::Oterica::Node';

#pod =head1 OVERVIEW
#pod
#pod DNS::Oterica::Node::Domain represents a domain name in DNS::Oterica. Domains
#pod have hosts.
#pod
#pod =method fqdn
#pod
#pod The fully qualified domain name for this domain.
#pod
#pod =cut

sub fqdn { $_[0]->domain; }

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Oterica::Node::Domain - a domain node

=head1 VERSION

version 0.304

=head1 OVERVIEW

DNS::Oterica::Node::Domain represents a domain name in DNS::Oterica. Domains
have hosts.

=head1 METHODS

=head2 fqdn

The fully qualified domain name for this domain.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
