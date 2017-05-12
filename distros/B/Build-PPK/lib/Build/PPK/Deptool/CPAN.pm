package Build::PPK::Deptool::CPAN;

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Build::PPK::Deptool::HTTP;

use Carp ('confess');

sub fetch_dist {
    my ( $class, %args ) = @_;

    confess('Unknown URL format') unless $args{'url'} =~ /^cpan:\/\/([a-z0-9_\-]+)\/([^\/]+)$/i;

    my ( $author, $cpan_dist ) = ( $1, $2 );

    my $cpan_url = 'http://search.cpan.org/CPAN/authors/id/'
      . join(
        '/',
        substr( $author, 0, 1 ),
        substr( $author, 0, 2 ),
        $author,
        $cpan_dist
      );

    return Build::PPK::Deptool::HTTP->fetch_dist(
        'url'  => $cpan_url,
        'dist' => $args{'dist'},
        'path' => $args{'path'}
    );
}

1;
