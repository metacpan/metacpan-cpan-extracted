# vim: set ft=perl ts=4 sw=4:
# Module::Build::Yapp - Module::Build subclass for turning .yp files into .pm modules.
# 
# Copyright (C) 2004 Dylan William Hardison.
# 
# This module is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This module is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this module; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
package Module::Build::Yapp;
use strict;
use warnings;

our $VERSION = '0.002';
use base 'Module::Build';
use File::Spec;


sub ACTION_code {
	my $me = shift;
	my $p = $me->{properties};

	if (exists $p->{yapp_files}) {
		my @files = @{ $p->{yapp_files} };
		foreach my $file (@files) {
			$file = _sane_file($file);
			my $modfile = _yp2pm($file);
			my $modname = _file2mod($modfile);

			if (not $me->up_to_date($file, $modfile)) {
				$me->do_system('yapp',
					'-s', # stand alone now.
					'-m' => $modname,
					'-o' => $modfile, $file);
			}
		}
	}

	$me->SUPER::ACTION_code(@_);
}

sub _sane_file {
	my $file = shift;
	
	$file = File::Spec->canonpath($file);
	if (File::Spec->file_name_is_absolute($file)) {
		$file = File::Spec->abs2rel($file);
	}

	return $file;
}

sub _yp2pm {
	my $file = shift;
	$file =~ s/yp$/pm/;
	return $file;
}

sub _file2mod {
	my $file = shift;
	$file =~ s/^lib\///;
	$file =~ s/\//::/g;
	$file =~ s/\.pm$//;
	return $file;
}


1;
