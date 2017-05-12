package CPAN::Local::Role::Finalise;
{
  $CPAN::Local::Role::Finalise::VERSION = '0.010';
}

# ABSTRACT: Do something after updates complete

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

requires 'finalise';

1;


__END__
=pod

=head1 NAME

CPAN::Local::Role::Finalise - Do something after updates complete

=head1 VERSION

version 0.010

=head1 DESCRIPTION

Plugins implementing this role are executed after a successful update of a
repository, i.e. after injection and indexing.

=head1 INTERFACE

Plugins implementing this role should provide a C<finalise> method with the
following interface:

=head2 Parameters

List of L<CPAN::Local::Distribution> objects representing distributions that
were successfully added to the repository.

=head2 Returns

Nothing.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

