#
# bibliography package for Perl
#
# Character set tables, to be loaded on demand
#
# Dana Jacobsen (dana@acm.org)
# 30 November 1995

#
# Remember, these are loaded on demand because of their size, so if you're
# going to use these, you must do something like:
#
#   require "${glb_bpprefix}p-cstab.pl" unless defined %bib'uapprox_tab;
#
# which will properly load the file if it hasn't done so already.

# XXXXX We really ought to be reading these in from tables

%mapprox_tab = (
'0000',	'0000',
  # HTML 2.0 idiomatic mappings -> common display styles
'2110',	'0120',
'2111',	'0140',
'2112',	'0120',
'2113',	'0140',
'2114',	'0140',
'2115',	'0130',
'2116',	'0120',
'2120',	'0121',
'2121',	'0141',
'2122',	'0121',
'2123',	'0141',
'2124',	'0141',
'2125',	'0131',
'2126',	'0121',
  # begin/end protect
'3100',	'0000',
'3110',	'0000',
);

# These should never have objectionable characters in them, such as
# \, <, >, |, %, #, &, ...
%uapprox_tab = (
'0107', 'c',
'010D', 'c',
'0159', 'r',
'0161', 's',
'017A',	'z',
'017E', 'z',
'0268',	'i',
'03B3', 'gamma',
'03B4', 'delta',
'03BC', 'mu',
'03C3', 'sigma',
'2002', ' ',
'2003', '  ',
'2007', ' ',
'2008', ' ',
'2009', ' ',
'2212', '-',
'2013', '--',
'2014', '---',
'201C', '``',
'201D', '\'\'',
);

&debugs("Loading approx tables", 8192);

1;
