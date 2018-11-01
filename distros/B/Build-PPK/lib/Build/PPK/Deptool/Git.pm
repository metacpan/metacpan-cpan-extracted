package Build::PPK::Deptool::Git;

# Copyright (c) 2018, cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use File::Basename ();
use Cwd            ();

use Build::PPK::Exec          ();
use Build::PPK::Deptool::Util ();

my $PERL = $^X;
my $MAKE = 'make';

sub fetch_dist {
    my ( $class, %args ) = @_;
    my $clone = File::Basename::basename( $args{'url'}, '.git' );

    if ( -e $args{'path'} && -d $clone ) {
        return unless Build::PPK::Deptool::Util->older_than( $args{'path'}, $clone );
    }

    unless ( -d $clone ) {
        Build::PPK::Exec->silent( qw(git clone), $args{'url'}, $clone ) == 0 or die("Unable to clone repo $args{'url'}: $@");
    }

    if ( -e $args{'path'} ) {
        Build::PPK::Deptool::Util->recursive_delete( $args{'path'} );
    }

    my $oldcwd = Cwd::getcwd();
    my $distrule = ( $args{'dist'} =~ /\.tar/ ) ? 'tardist' : 'distdir';

    chdir($clone) or die("Unable to chdir() to $clone: $!");

    Build::PPK::Exec->silent( $PERL, 'Makefile.PL' ) == 0 or die("Unable to run Makefile.PL: $@");
    Build::PPK::Exec->silent( $MAKE, 'manifest' ) == 0    or die("Unable to run 'make manifest': $@");
    Build::PPK::Exec->silent( $MAKE, $distrule ) == 0     or die("Unable to run 'make $distrule': $@");

    chdir $oldcwd or die("Unable to chdir() to old directory: $!");

    rename( "$clone/$args{'dist'}", $args{'path'} ) or die("Unable to rename $clone/$args{'dist'} to $args{'path'}: $!");
    Build::PPK::Deptool::Util->recursive_delete($clone);

    return;
}

1;
