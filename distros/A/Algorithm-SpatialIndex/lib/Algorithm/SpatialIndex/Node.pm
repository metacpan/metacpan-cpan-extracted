package Algorithm::SpatialIndex::Node;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use Class::XSAccessor {
  constructor => 'new',
  accessors => [qw(
    id
    subnode_ids
    coords
  )],
};

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Node - A non-leaf node in a SpatialIndex

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'QuadTree', # or others
  );

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Constructor

=head2 id

Read/write accessor for node id.

=head2 subnode_ids

Returns the array ref of subnode ids if set.
Works as setter, too.

=head2 coords

Returns the array ref coordinates if set.
Works as setter, too.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
