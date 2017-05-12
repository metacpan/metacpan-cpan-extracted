use 5.006;    # our
use strict;
use warnings;

package CPAN::Meta::Prereqs::Diff::Addition;

our $VERSION = '0.001004';

# ABSTRACT: A new dependency

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( with has );





has 'requirement' => ( is => ro =>, required => 1 );

with 'CPAN::Meta::Prereqs::Diff::Role::Change';











sub is_addition { return 1 }
sub is_removal  { }
sub is_change   { }









sub describe {
  my ($self) = @_;
  return sprintf q[%s.%s: +%s %s], $self->phase, $self->type, $self->module, $self->requirement;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::Prereqs::Diff::Addition - A new dependency

=head1 VERSION

version 0.001004

=head1 METHODS

=head2 C<is_addition>

  returns true

=head2 C<is_removal>

=head2 C<is_change>

=head2 C<describe>

  $object->describe();

  # runtime.requires: +ExtUtils::MakeMaker 5.0

=head1 ATTRIBUTES

=head2 C<requirement>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
