
#
# Copyright (C) 2003  Sam Horrocks
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#

package SpeedyMake::mod_speedycgi2;

use strict;
use ExtUtils::MakeMaker;
use vars qw(@ISA);


$main::do_not_write_makefile = 1;
require '../mod_speedycgi/Makefile.PL';
$main::do_not_write_makefile = 0;

@ISA = 'SpeedyMake::mod_speedycgi';

sub inc {'apache2'}
sub main_file_full {'mod_speedycgi2'}
sub main_h {'mod_speedycgi'}
sub my_name_full {shift->main_file_full}
sub mod_speedycgi_out {'.libs/mod_speedycgi.so'}
sub mod_speedycgi_target {'mod_speedycgi.la'}
sub clean_files_extra {qw(.libs *.lo *.slo t mod_speedycgi.so)}
sub mod_speedycgi_cmds {'../src/mod_speedycgi2_cmds.c'}

# Need symlinks for tests.
symlink("../mod_speedycgi/t", "t") || die "Can't create symlinks for tests";

SpeedyMake::mod_speedycgi2->init->write_makefile;
