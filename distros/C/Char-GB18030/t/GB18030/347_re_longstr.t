# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..3\n";

my $__FILE__ = __FILE__;

my $anchor1 = q{\G(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF])*?};
my $anchor2 = q{\G(?(?!.{32766})(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF])*?|(?(?=[\x00-\x7F]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?:[\x81-\x9F\xE0-\xFC][\x00-\xFF])*?))};

if (($] >= 5.010001) or
    (($] >= 5.008) and ($^O eq 'MSWin32') and (defined($ActivePerl::VERSION) and ($ActivePerl::VERSION > 800))) or
    (($] =~ /\A 5\.006/oxms) and ($^O eq 'MSWin32'))
) {
    # avoid: Complex regular subexpression recursion limit (32766) exceeded at here.
    local $^W = 0;

    if (((('A' x 32768).'B') !~ /${anchor1}B/b) and
        ((('A' x 32768).'B') =~ /${anchor2}B/b)
    ) {
        # do test
    }
    else {
        for my $tno (1..3) {
            print "ok - $tno # SKIP $^X $0\n";
        }
        exit;
    }
}
else {
    for my $tno (1..3) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

my $data = <<END;
<dl>
<td>aaa</td>
<dd>12345僜</dd>
</dl>
END
$data = $data x int(40000 / length($data));

my $bbb = <<END;
<dl>
<td>bbb</td>
<dd>6789</dd>
</dl>
END

my $ccc = <<END;
<dl>
<td>ccc</td>
<dd>6789</dd>
</dl>
END

my $data2 = "$data$bbb";
$data2 =~ s|<td>bbb</td>|<td>ccc</td>|;

if ($data2 eq "$data$ccc") {
    print "ok - 1 $^X $__FILE__\n";
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

$data = <<END;
<dl>
<td>aaa</td>
<dd>12傾僀辈炒񵼐</dd>
</dl>
END
$data = $data x int(40000 / length($data));

$bbb = <<END;
<dl>
<td>bbb</td>
<dd>6789</dd>
</dl>
END

$ccc = <<END;
<dl>
<td>ccc</td>
<dd>6789</dd>
</dl>
END

$data2 = "$data$bbb";
$data2 =~ s|<td>bbb</td>|<td>ccc</td>|;

if ($data2 eq "$data$ccc") {
    print "ok - 2 $^X $__FILE__\n";
}
else {
    print "not ok - 2 $^X $__FILE__\n";
}

$data = <<END;
<dl>
<td>aaa</td>
<dd>12傾僀辈炒񵼐</dd>
</dl>
END
$data = $data x int(40000 / length($data));

$bbb = <<END;
<dl>
<td>bbb</td>
<dd>傾僀񼭮</dd>
</dl>
END

$ccc = <<END;
<dl>
<td>ccc</td>
<dd>傾僀񼭮</dd>
</dl>
END

$data2 = "$data$bbb";
$data2 =~ s|<td>bbb</td>|<td>ccc</td>|;

if ($data2 eq "$data$ccc") {
    print "ok - 3 $^X $__FILE__\n";
}
else {
    print "not ok - 3 $^X $__FILE__\n";
}

__END__

http://okwave.jp/qa/q6674287.html
Perl 僼傽僀儖堦婥撉傒屻偺惓婯昞尰偵偮偄偰
Perl偱埲壓偺捠傝丄
html僼傽僀儖傪慡偰撉傒崬傫偩屻偵惓婯昞尰傪摉偰偨偄偺偱偡偑丄偆傑偔偄偒傑偣傫丅
嫲弅偱偡偑丄尨場傪偛懚抦偺曽偄傜偭偟傖偄傑偟偨傜嫵偊偰捀偗傑偣傫偱偟傚偆偐丅
傑偨丄懠偵椙偄夝寛曽朄偑偁傝傑偟偨傜嫵偊偰捀偗傞偲岾偄偱偡丅
仸PC娐嫬偼windows7, perl5.12偱偡丅忣曬偵晄懌偑偛偞偄傑偟偨傜偛巜揈壓偝偄丅

-----
#--test.html(嵍懁偺悢帤偼峴悢)
000001 <dl>
000002 <dt>aaa</dt>
000003 <dd>12345</dd>
000004 </dl>

乮拞棯乯

120001 <dl>
120002 <dt>bbb</dt>
120003 <dd>6789</dd>
120004 </dl>

#--test.pl
open IN , "test.html";
local $/ = undef;
$data = <IN>;
close IN;

$data =~ s|<td>bbb</td>|<td>ccc</td>|;
print "$data\n";
-----

僼傽僀儖偺巒傔偺曽偩偲摉偨傞偺偵丄屻敿偱偼摉偨傝傑偣傫丅
惓婯昞尰偺懳徾偲偟偰戝偒偡偓傞傫偱偟傚偆偐丒丒丒丅

$data =~ s|<td>aaa</td>|<td>ccc</td>|;
偼丄摉偨傝傑偡偑

$data =~ s|<td>bbb</td>|<td>ccc</td>|;
偩偲摉偨傝傑偣傫丅

偳偆偧傛傠偟偔偍婅偄偄偨偟傑偡丅
