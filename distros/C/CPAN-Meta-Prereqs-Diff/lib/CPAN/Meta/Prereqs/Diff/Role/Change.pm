use 5.006;    # our
use strict;
use warnings;

package CPAN::Meta::Prereqs::Diff::Role::Change;

our $VERSION = '0.001004';

# ABSTRACT: A base behavior for prerequisite changes

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo::Role qw( has requires );















has 'phase'  => ( is => ro =>, required => 1, );
has 'type'   => ( is => ro =>, required => 1, );
has 'module' => ( is => ro =>, required => 1, );











requires is_addition =>;
requires is_removal  =>;
requires is_change   =>;
requires describe    =>;

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::Prereqs::Diff::Role::Change - A base behavior for prerequisite changes

=head1 VERSION

version 0.001004

=head1 ATTRIBUTES

=head2 C<phase>

The dependency phase ( such as: C<runtime>,C<configure> )

=head2 C<type>

The dependency type ( such as: C<requires>,C<suggests> )

=head2 C<module>

The depended upon module

=head1 REQUIRES

=head2 C<is_addition>

=head2 C<is_removal>

=head2 C<is_change>

=head2 C<describe>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
