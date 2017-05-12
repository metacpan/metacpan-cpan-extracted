#!/usr/bin/perl

while (<>) {
	unless (m/^#line/) {
		s/\byy/amd_yy/g;
		s/YYSTYPE/AMD_YYSTYPE/g;
	}
}
continue {
	print;
}
