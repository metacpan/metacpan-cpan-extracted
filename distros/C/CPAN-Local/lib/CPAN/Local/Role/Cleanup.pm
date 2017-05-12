package CPAN::Local::Role::Cleanup;
{
  $CPAN::Local::Role::Cleanup::VERSION = '0.010';
}

# ABSTRACT: Remove orphan files

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

requires 'cleanup';

1;


__END__
=pod

=head1 NAME

CPAN::Local::Role::Cleanup - Remove orphan files

=head1 VERSION

version 0.010

=head1 DESCRIPTION

Plugins implementing this role are executed whenever there is a request to
clean up unused files in the repository.

=head1 INTERFACE

Plugins implementing this role should provide a C<cleanup> method with the
following interface:

=head2 Parameters

None.

=head2 Returns

List of paths to files under the repository root that this module cares about,
and should not be cleaned.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

