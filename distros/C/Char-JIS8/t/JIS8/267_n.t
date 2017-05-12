# encoding: JIS8
# This file is encoded in JIS8.
die "This file is not encoded in JIS8.\n" if q{‚ } ne "\x82\xa0";

use strict;
use JIS8;
print "1..16\n";

my $__FILE__ = __FILE__;

$_ = "A\nBCDEF";

if (/(.)(.)(.)/ and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 1 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 1 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(.)(.)(\N)/ and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 2 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 2 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(.)(\N)(.)/ and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 3 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 3 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(.)(\N)(\N)/ and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 4 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 4 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(\N)(.)(.)/ and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 5 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 5 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(\N)(.)(\N)/ and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 6 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 6 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(\N)(\N)(.)/ and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 7 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 7 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(\N)(\N)(\N)/ and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 8 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 8 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(.)(.)(.)/s and ("<$1><$2><$3>" eq "<A><\n><B>")) {
    print qq{ok - 9 $^X $__FILE__ ($1)(\\n)($3)\n};
}
else {
    print qq{not ok - 9 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(.)(.)(\N)/s and ("<$1><$2><$3>" eq "<A><\n><B>")) {
    print qq{ok - 10 $^X $__FILE__ ($1)(\\n)($3)\n};
}
else {
    print qq{not ok - 10 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(.)(\N)(.)/s and ("<$1><$2><$3>" eq "<\n><B><C>")) {
    print qq{ok - 11 $^X $__FILE__ (\\n)($2)($3)\n};
}
else {
    print qq{not ok - 11 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(.)(\N)(\N)/s and ("<$1><$2><$3>" eq "<\n><B><C>")) {
    print qq{ok - 12 $^X $__FILE__ (\\n)($2)($3)\n};
}
else {
    print qq{not ok - 12 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(\N)(.)(.)/s and ("<$1><$2><$3>" eq "<A><\n><B>")) {
    print qq{ok - 13 $^X $__FILE__ ($1)(\\n)($3)\n};
}
else {
    print qq{not ok - 13 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(\N)(.)(\N)/s and ("<$1><$2><$3>" eq "<A><\n><B>")) {
    print qq{ok - 14 $^X $__FILE__ ($1)(\\n)($3)\n};
}
else {
    print qq{not ok - 14 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(\N)(\N)(.)/s and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 15 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 15 $^X $__FILE__ ($1)($2)($3)\n};
}

if (/(\N)(\N)(\N)/s and ("<$1><$2><$3>" eq "<B><C><D>")) {
    print qq{ok - 16 $^X $__FILE__ ($1)($2)($3)\n};
}
else {
    print qq{not ok - 16 $^X $__FILE__ ($1)($2)($3)\n};
}

__END__
