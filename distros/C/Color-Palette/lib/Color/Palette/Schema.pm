package Color::Palette::Schema;
{
  $Color::Palette::Schema::VERSION = '0.100003';
}
use Moose;
# ABSTRACT: requirements for a palette

use Color::Palette;
use Color::Palette::Types qw(ColorName);
use MooseX::Types::Moose qw(ArrayRef);


has required_colors => (
  is  => 'ro',
  isa => ArrayRef[ ColorName ],
  required => 1,
);


sub check {
  my ($self, $palette) = @_;

  # ->color will throw an exception on unknown colors, doing our job for us.
  # -- rjbs, 2009-05-19
  $palette->color($_) for @{ $self->required_colors };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::Palette::Schema - requirements for a palette

=head1 VERSION

version 0.100003

=head1 DESCRIPTION

Most of this is documented in L<Color::Palette>.  Below is just a bit more
documentation.

=head1 ATTRIBUTES

=head2 required_colors

This is an arrayref of color names that must be present in any palette checked
against this schema.

=head1 METHODS

=head2 check

  $schema->check($palette);

This method will throw an exception if the given palette doesn't meet the
requirements of the schema.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
