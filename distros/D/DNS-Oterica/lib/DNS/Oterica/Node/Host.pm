package DNS::Oterica::Node::Host;
# ABSTRACT: a host node
$DNS::Oterica::Node::Host::VERSION = '0.311';
use Moose;
extends 'DNS::Oterica::Node';

#pod =head1 OVERVIEW
#pod
#pod C<DNS::Oterica::Node::Host> represents an individual machine in DNS::Oterica.
#pod A node has interfaces (which have IP addresses) and is part of a named domain.
#pod
#pod =attr hostname
#pod
#pod This is the name of the host.  B<It does not include the domain name.>
#pod
#pod =cut

has hostname => (is => 'ro', isa => 'Str', required => 1);

#pod =attr aliases
#pod
#pod This is an arrayref of other fully-qualified names that refer to this host.
#pod
#pod The accessor returns a list.
#pod
#pod =cut

has aliases  => (
  isa => 'ArrayRef',
  required => 1,
  default  => sub { [] },
  traits   => [ 'Array' ],
  handles  => {
    aliases => 'elements',
  },
);

#pod =attr interfaces
#pod
#pod This is an arrayref of pairs, each one an IP address and a network.
#pod
#pod This attribute is pretty likely to change later.
#pod
#pod =cut

has interfaces => (
  isa => 'ArrayRef',
  required => 1,
  traits   => [ 'Array' ],
  handles  => {
    interfaces => 'elements',
  },
);

#pod =attr location
#pod
#pod The name of the network location of this host
#pod
#pod =cut

has location => (is => 'ro', isa => 'Str', required => 1);

#pod =attr ttl
#pod
#pod This is the default TTL for the host's A records -- it doesn't affect the TTL
#pod for records created by families to which the host belongs.  If not provided,
#pod it will be unset, and the default TTL is used.
#pod
#pod =cut

has ttl => (is => 'ro', isa => 'Int');

#pod =method fqdn
#pod
#pod This is the fully-qualified domain name of this host.
#pod
#pod =cut

sub fqdn {
  my ($self) = @_;
  sprintf '%s.%s', $self->hostname, $self->domain;
}

sub _family_names {
  my ($self) = @_;
  my @all_families = $self->hub->node_families;
  my @has_self = grep { grep { $_ == $self } $_->nodes } @all_families;

  return map { $_->name } @has_self;
}

sub as_data_lines {
  my ($self) = @_;

  my @lines = $self->rec->comment("begin host ". $self->fqdn);

  push @lines, $self->rec->comment(
    "  families: " . join(q{, }, $self->_family_names)
  );

  push @lines, $self->rec->a_and_ptr({
    name => $self->fqdn,
    node => $self,
    ttl  => scalar $self->ttl,
  });

  for ($self->aliases) {
    push @lines, $self->rec->a({
      name => $_,
      node => $self,
      ttl  => scalar $self->ttl,
    });
  }

  push @lines, $self->rec->comment("end host ". $self->fqdn . "\n");

  return @lines;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Oterica::Node::Host - a host node

=head1 VERSION

version 0.311

=head1 OVERVIEW

C<DNS::Oterica::Node::Host> represents an individual machine in DNS::Oterica.
A node has interfaces (which have IP addresses) and is part of a named domain.

=head1 ATTRIBUTES

=head2 hostname

This is the name of the host.  B<It does not include the domain name.>

=head2 aliases

This is an arrayref of other fully-qualified names that refer to this host.

The accessor returns a list.

=head2 interfaces

This is an arrayref of pairs, each one an IP address and a network.

This attribute is pretty likely to change later.

=head2 location

The name of the network location of this host

=head2 ttl

This is the default TTL for the host's A records -- it doesn't affect the TTL
for records created by families to which the host belongs.  If not provided,
it will be unset, and the default TTL is used.

=head1 METHODS

=head2 fqdn

This is the fully-qualified domain name of this host.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
