package CPAN::Local::Plugin;
{
  $CPAN::Local::Plugin::VERSION = '0.010';
}

# ABSTRACT: Base class for plugins

use strict;
use warnings;

use Moose;
with 'MooseX::Role::Loggable';
use namespace::clean -except => 'meta';

has 'root' =>
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'distribution_class' =>
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub create_distribution
{
    my $self = shift;
    return $self->distribution_class->new(@_);
}

sub requires_distribution_roles
{
    return;
}

__PACKAGE__->meta->make_immutable;


__END__
=pod

=head1 NAME

CPAN::Local::Plugin - Base class for plugins

=head1 VERSION

version 0.010

=head1 ATTRIBUTES

=head2 root

Repository root.

=head2 distribution_class

Base class for distribution objects.

=head1 METHODS

=head2 requires_distribution_roles

Empty class method. If overriden in a subclass should return a list of
distribution roles required by the respective plugin.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

