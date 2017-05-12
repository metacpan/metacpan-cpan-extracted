##
#
#    Copyright 2005-2006, Brian Szymanski
#
#    This file is part of Cache::Static
#
#    Cache::Static is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about Cache::Static, point a web browser at
#    http://chronicle.allafrica.com/scache/ or read the
#    documentation included with the Cache::Static distribution in the
#    doc/ directory
#
##


package Cache::Static::DBI_Util;

use strict;
use warnings;
require Cache::Static;

sub _get_timestamp_file {
	my ($type, $spec) = @_;
	Cache::Static::_log(4, "DBI_Util: in get_timestamp_file for $type $spec");
	return $Cache::Static::ROOT.'/timestamps/'
		.Cache::Static::md5_path("DBI|$type|$spec").'.ts';
}

sub modtime {
	my $file = _get_timestamp_file(@_);
	my @t = stat($file);
	die "DBI_Util couldn't get modtime for $file (@_): $!" unless(@t);
	return @t ? $t[9] : 0;
}

sub get_extra_deps {
	return ( );
}

1;

