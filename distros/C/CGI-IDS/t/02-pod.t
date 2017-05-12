#****u* t/02-pod.t
# NAME
#   02_pod.t
# DESCRIPTION
#   Tests for POD documention syntax in PerlIDS (CGI::IDS)
# AUTHOR
#   Hinnerk Altenburg <hinnerk@cpan.org>
# CREATION DATE
#   2008-09-12
# COPYRIGHT
#   Copyright (C) 2008, 2009 Hinnerk Altenburg
#
#   This file is part of PerlIDS.
#
#   PerlIDS is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   PerlIDS is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public License
#   along with PerlIDS.  If not, see <http://www.gnu.org/licenses/>.
#****

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use FindBin qw($Bin);
use Test::More;

#------------------------- Tests -----------------------------------------------
# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";

if ($@) {
    plan skip_all => "Test::Pod $min_tp required for testing POD";
}
else {
    plan tests => 3;
    pod_file_ok( "$Bin/../lib/CGI/IDS.pm", "lib/CGI/IDS.pm is a valid POD file" );
    pod_file_ok( "$Bin/../lib/CGI/IDS/Whitelist.pm", "lib/CGI/IDS.pm is a valid POD file" );
    pod_file_ok( "$Bin/../examples/demo.pl", "examples/demo.pl is a valid POD file" );
}
