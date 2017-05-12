# Audio::LADSPA perl modules for interfacing with LADSPA plugins
# Copyright (C) 2003  Joost Diepenmaat.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# See the COPYING file for more information.



package Audio::LADSPA::LibraryLoader;
use strict;
use base qw(DynaLoader);
use Carp;

our $VERSION = "0.021";
use Audio::LADSPA::Library;
use Audio::LADSPA::Plugin::XS;
use Config;

sub find_libraries {
    my @libs = map {
	find_libraries_in_dir($_)
    } split/:/,($ENV{LADSPA_PATH} || '/usr/lib/ladspa:/usr/local/lib/ladspa');
    unless (scalar @libs) {
	if ($ENV{LADSPA_PATH}) {
	    carp "No libraries found in LADSPA_PATH ($ENV{LADSPA_PATH})";
	}
	else {
	    carp "No libraries found in /usr/lib/ladspa and /usr/local/lib/ladspa. Please set LADSPA_PATH.";
	}
    }
    return @libs;
}

sub find_libraries_in_dir {
    my $dir = shift;
      opendir D,$dir or return;
      my @files = map "$dir/$_",grep /\.$Config{so}$/, readdir(D);
      closedir D;
      @files;
 }   


sub load {
    my ($self,$library_path) = @_;
    $library_path =~ /([\w\-\+]+)\.($Config{so})$/ or die "Cannot form a package name from $library_path";
    my $package = "Audio::LADSPA::Library::$1";
    if ($package->can("library_file")) {
#        warn "Already made a package $package for ".$package->library_file.", skipping $library_path";
        return;
    }
#    warn "loading $library_path to $package\n";
    $self->load_lib_to_package(
	$library_path,
	$package,
    );
    return $package;
}


Audio::LADSPA::LibraryLoader->bootstrap($VERSION);

1;

