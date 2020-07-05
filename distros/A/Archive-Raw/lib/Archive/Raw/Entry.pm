package Archive::Raw::Entry;
$Archive::Raw::Entry::VERSION = '0.03';
use strict;
use warnings;
use Archive::Raw;

=head1 NAME

Archive::Raw::Context - libarchive Entry class

=head1 VERSION

version 0.03

=head1 DESCRIPTION

A L<Archive::Raw::Entry> represents an entry, similar to C<"struct stat">.

=head1 METHODS

=head2 pathname( [$pathname] )

=head2 filetype( [$filetype] )

=head2 size_is_set( )

=head2 ctime_is_set( )

=head2 mtime_is_set( )

=head2 is_data_encrypted( )

=head2 is_metadata_encrypted( )

=head2 is_encrypted( )

=head2 size( [$size] )

=head2 uname( [$uname] )

=head2 gname( [$gname] )

=head2 ctime( [$secs, $nano] )

=head2 mtime( [$secs, $nano] )

=head2 mode( [$mode] )

=head2 strmode( )

=head2 gid( [$gid] )

=head2 uid( [$uid] )

=head2 symlink( [$sylink] )

=head2 symlink_type( [$type] )

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Archive::Raw::Entry
