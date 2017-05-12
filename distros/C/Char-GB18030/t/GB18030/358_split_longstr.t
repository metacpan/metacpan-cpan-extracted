# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..12\n";

my $__FILE__ = __FILE__;
local $^W = 0;

my $anchor1 = q{\G(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF])*?};
my $anchor2 = q{\G(?(?!.{32766})(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF])*?|(?(?=[\x00-\x7F]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?:[\x81-\x9F\xE0-\xFC][\x00-\xFF])*?))};

if (($] >= 5.010001) or
#   (($] >= 5.008) and ($^O eq 'MSWin32') and (defined($ActivePerl::VERSION) and ($ActivePerl::VERSION > 800))) or
#   (($] =~ /\A 5\.006/oxms) and ($^O eq 'MSWin32'))
0) {
    # avoid: Complex regular subexpression recursion limit (32766) exceeded at here.
    local $^W = 0;

    if (((('A' x 32768).'B') !~ /${anchor1}B/b) and
        ((('A' x 32768).'B') =~ /${anchor2}B/b)
    ) {
        # do test
    }
    else {
        for my $tno (1..12) {
            print "ok - $tno # SKIP $^X $0\n";
        }
        exit;
    }
}
else {
    for my $tno (1..12) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

$count = 32768;

$substr = 'A' x $count;
$string = join '僀', ($substr) x 5;
@string = split(/僀/, $string);
$want   = "($substr)($substr)($substr)($substr)($substr)";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 $^X $__FILE__\n};
}

$substr = '傾A' x $count;
$string = join '僀', ($substr) x 5;
@string = split(/僀/, $string);
$want   = "($substr)($substr)($substr)($substr)($substr)";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 $^X $__FILE__\n};
}

$substr = 'A' x $count;
$string = join '僀', ($substr) x 5;
@string = split(/僀/, $string, -3);
$want   = "($substr)($substr)($substr)($substr)($substr)";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 3 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 $^X $__FILE__\n};
}

$substr = '傾A' x $count;
$string = join '僀', ($substr) x 5;
@string = split(/僀/, $string, -3);
$want   = "($substr)($substr)($substr)($substr)($substr)";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 4 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 $^X $__FILE__\n};
}

$substr = 'A' x $count;
$string = join '僀', ($substr) x 5;
@string = split(/僀/, $string, 3);
$want   = "($substr)($substr)(${substr}僀${substr}僀${substr})";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 5 $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 $^X $__FILE__\n};
}

$substr = '傾A' x $count;
$string = join '僀', ($substr) x 5;
@string = split(/僀/, $string, 3);
$want   = "($substr)($substr)(${substr}僀${substr}僀${substr})";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 $^X $__FILE__\n};
}

$substr = 'A' x $count;
$string = join '񼭮', ($substr) x 5;
@string = split(/񼭮/, $string);
$want   = "($substr)($substr)($substr)($substr)($substr)";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 7 $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 $^X $__FILE__\n};
}

$substr = '12傾僀辈炒񵼐' x $count;
$string = join '񼭮', ($substr) x 5;
@string = split(/񼭮/, $string);
$want   = "($substr)($substr)($substr)($substr)($substr)";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 8 $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 $^X $__FILE__\n};
}

$substr = 'A' x $count;
$string = join '񼭮', ($substr) x 5;
@string = split(/񼭮/, $string, -3);
$want   = "($substr)($substr)($substr)($substr)($substr)";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 9 $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 $^X $__FILE__\n};
}

$substr = '12傾僀辈炒񵼐' x $count;
$string = join '񼭮', ($substr) x 5;
@string = split(/񼭮/, $string, -3);
$want   = "($substr)($substr)($substr)($substr)($substr)";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 10 $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 $^X $__FILE__\n};
}

$substr = 'A' x $count;
$string = join '񼭮', ($substr) x 5;
@string = split(/񼭮/, $string, 3);
$want   = "($substr)($substr)(${substr}񼭮${substr}񼭮${substr})";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 11 $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 $^X $__FILE__\n};
}

$substr = '12傾僀辈炒񵼐' x $count;
$string = join '񼭮', ($substr) x 5;
@string = split(/񼭮/, $string, 3);
$want   = "($substr)($substr)(${substr}񼭮${substr}񼭮${substr})";
$got    = join('', map {"($_)"} @string);
if ($got eq $want) {
    print qq{ok - 12 $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 $^X $__FILE__\n};
}

__END__
