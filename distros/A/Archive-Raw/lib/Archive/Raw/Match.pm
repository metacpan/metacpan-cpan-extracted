package Archive::Raw::Match;
$Archive::Raw::Match::VERSION = '0.02';
use strict;
use warnings;
use Archive::Raw;

=head1 NAME

Archive::Raw::Match - libarchive Match class

=head1 VERSION

version 0.02

=head1 DESCRIPTION

A L<Archive::Raw::Match> represents a matcher

=head1 METHODS

=head2 new( )

Create a new matcher.

=head2 excluded( $entry )

Test if C<$entry> is excluded.

=head2 path_excluded( $entry )

Test if C<$entry> is excluded.

=head2 time_excluded( $entry )

Test if C<$entry> is excluded.

=head2 owner_excluded( $entry )

Test if C<$entry> is excluded.

=head2 include_pattern( $pattern )

Add C<$pattern> to the include list.

=head2 include_pattern_from_file( $file )

Add the patterns in C<$file> to the include list.

=head2 exclude_pattern( $pattern )

Add C<$pattern> to the exclude list.

=head2 exclude_pattern_from_file( $file )

Add the patterns in C<$file> to the exclude list.

=head2 include_uid( $uid )

Add C<$uid> to the include list.

=head2 include_gid( $gid )

Add C<$gid> to the include list.

=head2 include_uname( $uname )

Add C<$uname> to the include list.

=head2 include_gname( $gname )

Add C<$gname> to the include list.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Archive::Raw::Match
