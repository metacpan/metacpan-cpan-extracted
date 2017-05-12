#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More 0.82;
use FindBin;
use File::Spec;

my $bash_version = `bash --version`;
my $have_bash = ($? == 0 ? 1 : 0);
diag "have_bash $have_bash";
diag "bash_version ", explain $bash_version;

$have_bash
  or plan skip_all => 'bash not available';

plan tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

ok (chdir($FindBin::Bin), "chdir $FindBin::Bin");
my $script = 'bash-completion.bash';
is (system('bash', $script), 0, "run $script");
exit 0;
