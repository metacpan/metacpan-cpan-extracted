#!/usr/bin/perl

#	Copyright 2001 Jörgen Hägg
#	You may distribute under the terms of the GNU General Public License.

use blib;
use Config::Cfe;

read_file('testdata');
	
goto_top;
delete_sect 'x_sect';
append_sect 'x_sect';
append split(/\n/, `fortune -l`);
end_sect;

list_lines;

my $line = get_sect 'x_sect';

print @$line, "\n";

write_file;
