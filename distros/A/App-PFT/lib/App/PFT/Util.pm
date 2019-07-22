# Copyright 2014 - Giovanni Simoni
#
# This file is part of PFT.
#
# PFT is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# PFT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PFT.  If not, see <http://www.gnu.org/licenses/>.
#
package App::PFT::Util v1.3.0;

use strict;
use warnings;

use Exporter qw/import/;
our @EXPORT_OK = qw/
    ln
/;

use Carp;

use Encode;
use Encode::Locale;

use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree make_path/;
use File::Spec::Functions qw/updir catfile catdir rootdir/;
use File::Basename qw/dirname/;
use Cwd qw/abs_path cwd/;

sub ln {
    my($from, $to, $verbose) = @_;
    my $ok;

    -e $to && remove_tree $to, {verbose => $verbose};
    make_path dirname $to;
    $verbose and say STDERR "Linking $from to $to";
    $ok = link($from, $to);
    $ok and return 1;
    $verbose and say STDERR "Could not hardlink: $!. Symlinking";
    $ok = eval { symlink($from, $to) };
    $ok and return 1;
    $verbose and say STDERR "Could not symlink: $@$!. Copying";
    remove_tree $to, {verbose => $verbose};
    $ok = dircopy $from, $to;
    $ok and return 1;
    $verbose and say STDERR "Everything failed";
    return '';
}

1;
