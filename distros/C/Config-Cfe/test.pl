#!/usr/bin/perl

#	Copyright 2001 Jörgen Hägg
#	You may distribute under the terms of the GNU General Public License.

use blib;
use Config::Cfe;

open(OUT, ">testdata") || die "create testdata:$!";
print OUT <<'eof';
Yagi
Yakima
Yale
Yalies
Yalta
Yamaha
Yankee
Yankees
Yankton
Yaounde
Yaqui
Yarmouth
Yates
Yaunde
eof
close(OUT);


read_file('testdata');
list_lines;
	
goto_top;
insert 'Edited by Config::Cfe', '';
append_sect 'my_sect';
append 'Information wants to be free';
end_sect;

list_lines;

delete_all '^Yan';

list_lines;

eval_where '^Yal', sub {
	my ($n, $l) = @_;

	$$l =~ s/^Yal/Zon/;
	$$l =~ tr/ke/yu/;
};
list_lines;

write_file;

