package # ...
  API::Mathpix::Response;

use Moose;

has 'confidence' => (
  is => 'rw',
  isa => 'Num'
);

has 'confidence_rate' => (
  is => 'rw',
  isa => 'Num'
);

has 'text' => (
  is => 'rw',
  isa => 'Str'
);

has 'html' => (
  is => 'rw',
  isa => 'Str'
);

=head1 NAME

API::Mathpix::Response - Use the API of Mathpix

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 AUTHOR

Eriam Schaffter, C<< <eriam at mediavirtuel.com> >>

=head1 BUGS & SUPPORT

Please go directly to Github

    https://github.com/eriam/API-Mathpix

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Eriam Schaffter.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;
