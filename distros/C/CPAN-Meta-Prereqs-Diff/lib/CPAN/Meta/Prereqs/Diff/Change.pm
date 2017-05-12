use 5.006;    # our
use strict;
use warnings;

package CPAN::Meta::Prereqs::Diff::Change;

our $VERSION = '0.001004';

# ABSTRACT: A dependency which changes its requirements

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( with has );







has 'old_requirement' => ( is => ro =>, required => 1 );
has 'new_requirement' => ( is => ro =>, required => 1 );

with 'CPAN::Meta::Prereqs::Diff::Role::Change';















sub is_addition  { }
sub is_removal   { }
sub is_change    { return 1 }
sub is_upgrade   { }
sub is_downgrade { }









sub describe {
  my ($self) = @_;
  return sprintf q[%s.%s: ~%s %s -> %s], $self->phase, $self->type, $self->module, $self->old_requirement, $self->new_requirement;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::Prereqs::Diff::Change - A dependency which changes its requirements

=head1 VERSION

version 0.001004

=head1 METHODS

=head2 C<is_addition>

=head2 C<is_removal>

=head2 C<is_change>

  returns true

=head2 C<is_upgrade>

=head2 C<is_downgrade>

=head2 C<describe>

  $object->describe();

  # runtime.requires: ~ExtUtils::MakeMaker < 5.0 -> > 5.1

=head1 ATTRIBUTES

=head2 C<old_requirement>

=head2 C<new_requirement>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
