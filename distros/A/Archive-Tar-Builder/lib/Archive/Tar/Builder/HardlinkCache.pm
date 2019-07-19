package Archive::Tar::Builder::HardlinkCache;

# Copyright (c) 2019, cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

=head1 NAME

Archive::Tar::Builder::HardlinkCache - Index of hardlinked files

=head1 DESCRIPTION

L<Archive::Tar::Builder::HardlinkCache> is a cache of hardlinked files, indexed
by device and inode number, containing the first paths encountered of
hardlinked files.

This module is intended for internal use.

=cut

sub new {
    my ($class) = @_;

    return bless {}, $class;
}

sub lookup {
    my ($self, $dev, $ino, $path) = @_;

    if (exists $self->{$dev}->{$ino}) {
        return $self->{$dev}->{$ino};
    }

    $self->{$dev}->{$ino} = $path;

    return;
}

=head1 COPYRIGHT

Copyright (c) 2019, cPanel, L.L.C.
All rights reserved.
http://cpanel.net/

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  See L<perlartistic> for further details.

=cut

1;
