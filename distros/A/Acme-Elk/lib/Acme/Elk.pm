package Acme::Elk;
our $VERSION = '1.001';
use Moose ();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(also => 'Moose');

=head1 NAME

Acme::Elk - it isn't Moose

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  package MyObject;
  use Acme::Elk;

  has foo => (
      is => 'rw',
      isa => 'Str',
  );

=head1 DESCRIPTION

In case you know someone with hang-ups about using L<Moose>, you can use
L<Acme::Elk>. It is exactly the same as Moose, but named Acme::Elk.

And it's already 1.000!

=head1 SPECIAL THANKS

Inspired by Rob Kinyon.

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Andrew Sterling Hanenkamp.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;