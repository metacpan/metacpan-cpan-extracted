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


package Cache::Static::XML_Comma_Util;

use strict;
use warnings;
require Cache::Static;

sub _get_timestamp_file {
	my ($type, $spec) = @_;
	Cache::Static::_log(4, "XML_Comma_Util: in get_timestamp_file for $type $spec");
	return $Cache::Static::ROOT.'/timestamps/'.
		Cache::Static::md5_path("XML::Comma|$type|$spec").'.ts';
}

sub modtime {
	my $file = _get_timestamp_file(@_);
	my @t = stat($file);
	die "XML_Comma_Util couldn't get modtime for $file (@_): $!" unless(@t);
	return @t ? $t[9] : 0;
}

#bummer, this takes 0.02 seconds... too slow...
#  we could cache the spec lookup...
sub get_extra_deps {
	my ($type, $spec) = @_;

	my @t = split(/\|/, $spec, 1);
	my $def_spec = $t[0];
	my $def = XML::Comma::Def->$def_spec;
	my $ff = $def->{_from_file};
	print "extra dep for XML::Comma|$type : $ff\n";
	return ( "file|$ff" );
}

1;

