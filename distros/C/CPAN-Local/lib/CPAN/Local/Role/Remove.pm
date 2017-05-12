package CPAN::Local::Role::Remove;
{
  $CPAN::Local::Role::Remove::VERSION = '0.010';
}

# ABSTRACT: Remove distributions from the repo

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

requires 'remove';

1;


__END__
=pod

=head1 NAME

CPAN::Local::Role::Remove - Remove distributions from the repo

=head1 VERSION

version 0.010

=head1 DESCRIPTION

Plugins implementing this role are executed whenever a whole repository needs
to be completely removed.

=head1 INTERFACE

Plugins implementing this role should provide a C<remove> method with the
following interface:

=head2 Parameters

None.

=head2 Returns

Nothing.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

