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

package App::PFT v1.3.0; # Remember to fix version in $VersionString

use strict;
use warnings;
use PFT;

use Exporter 'import';
our @EXPORT_OK = qw/$Name $ConfName $VersionString/;

our $Name = 'pft';
our $ConfName = 'pft.yaml';
our $NoInitMsg = "Not a $Name site. Try running: $Name init";
our $VersionString = <<"EOF";
App-PFT $App::PFT::VERSION Copyright (C) 2015-*  Giovanni Simoni
    PFT $PFT::VERSION Copyright (C) 2015-*  Giovanni Simoni
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions; see the source code for details.
EOF

use FindBin;
use File::Spec;

sub help_of {
    File::Spec->catfile($FindBin::RealBin, join '-', $Name, @_);
}

1;
