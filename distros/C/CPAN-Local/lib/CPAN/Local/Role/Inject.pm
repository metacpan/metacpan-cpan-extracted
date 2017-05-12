package CPAN::Local::Role::Inject;
{
  $CPAN::Local::Role::Inject::VERSION = '0.010';
}

# ABSTRACT: Add selected distributions to a repo

use strict;
use warnings;

use Moose::Role;
use namespace::clean -except => 'meta';

requires 'inject';

1;


__END__
=pod

=head1 NAME

CPAN::Local::Role::Inject - Add selected distributions to a repo

=head1 VERSION

version 0.010

=head1 DESCRIPTION

Plugins implementing this role are executed at the point where the list of
distributions that need to be added has been determined, and the actual
addition needs to be performed.

=head1 INTERFACE

Plugins implementing this role should provide an C<inject> method with the
following interface:

=head2 Parameters

List of L<CPAN::Local::Distribution> objects to inject.

=head2 Returns

List of L<CPAN::Local::Distribution> objects successflly injected.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

