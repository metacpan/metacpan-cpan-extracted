package Build::PPK::Deptool::Util;

# Copyright (c) 2018, cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use File::Find ();

sub older_than {
    my ( $class, $a, $b ) = map { ( stat $_ )[9] } @_;

    return 1 if $a < $b;
    return 0;
}

sub recursive_delete {
    my ( $class, @items ) = @_;

    File::Find::finddepth(
        {
            'no_chdir' => 1,
            'wanted'   => sub {
                if ( -d $File::Find::name ) {
                    rmdir $File::Find::name;
                }
                else {
                    unlink $File::Find::name;
                }
              }
        },
        @items
    );
}

1;
