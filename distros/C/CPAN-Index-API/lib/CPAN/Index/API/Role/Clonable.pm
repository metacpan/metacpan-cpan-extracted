package CPAN::Index::API::Role::Clonable;
{
  $CPAN::Index::API::Role::Clonable::VERSION = '0.007';
}

# ABSTRACT: Clones index file objects

use strict;
use warnings;

use Moose::Role;

sub clone
{
    my ($self, %params) = @_;
    $self->meta->clone_object($self, %params);
}


1;

__END__
=pod

=head1 NAME

CPAN::Index::API::Role::Clonable - Clones index file objects

=head1 VERSION

version 0.007

=head1 PROVIDES

=head2 clone

Clones the objecct. Parameters can be supplied as key/value paris to override
the values of existing attributes.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

