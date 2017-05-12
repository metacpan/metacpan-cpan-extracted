package Data::TreeValidator::Node;
{
  $Data::TreeValidator::Node::VERSION = '0.04';
}
# ABSTRACT: Represents a node in the validation tree specification
use Moose::Role;
use namespace::autoclean;

requires 'process';

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Node - Represents a node in the validation tree specification

=head1 DESCRIPTION

This role is used as a market to indicate that a certain object can be used as
validation specification.

=head1 METHODS

=head2 process($input)

This method is required for all classes that consume this role.

It takes some form of input, and should return an object that does the
L<Data::TreeValidator::Result> role.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

