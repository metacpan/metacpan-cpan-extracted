package CPAN::Local::Role::Prune;
{
  $CPAN::Local::Role::Prune::VERSION = '0.010';
}

# ABSTRACT: Remove distributions from selection list

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

requires 'prune';

1;


__END__
=pod

=head1 NAME

CPAN::Local::Role::Prune - Remove distributions from selection list

=head1 VERSION

version 0.010

=head1 DESCRIPTION

Plugins implementing this role are executed right after the initial list of
distributions that need to be added is determined, and their purpose is to
remove any unneeded distributions from that list.

=head1 INTERFACE

Plugins implementing this role should provide a C<prune> method with the
following interface:

=head2 Parameters

List of L<CPAN::Local::Distribution> objects that are planned for addition.

=head2 Returns

List of L<CPAN::Local::Distribution> objects for addition, with any unneeded
distributions removed.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

