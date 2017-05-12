# encoding: Windows1258
# This file is encoded in Windows-1258.
die "This file is not encoded in Windows-1258.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Windows1258;
print "1..11\n";

my $__FILE__ = __FILE__;

eval {
    require English;
    English->import;
};
if ($@) {
    for (1..11) {
        print qq{ok - $_ # PASS $^X $__FILE__\n};
    }
    exit;
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (${POSTMATCH} eq 'XYZ456') {
        print qq{ok - 1 \${POSTMATCH} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \${POSTMATCH} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \${POSTMATCH} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ("${POSTMATCH}" eq 'XYZ456') {
        print qq{ok - 2 "\${POSTMATCH}" $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "\${POSTMATCH}" $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "\${POSTMATCH}" $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (qq{${POSTMATCH}} eq 'XYZ456') {
        print qq{ok - 3 qq{\${POSTMATCH}} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 qq{\${POSTMATCH}} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 qq{\${POSTMATCH}} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<END eq "XYZ456\n") {
${POSTMATCH}
END
        print qq{ok - 4 <<END\${POSTMATCH}END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 <<END\${POSTMATCH}END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 <<END\${POSTMATCH}END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<"END" eq "XYZ456\n") {
${POSTMATCH}
END
        print qq{ok - 5 <<"END"\${POSTMATCH}END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 <<"END"\${POSTMATCH}END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 <<"END"\${POSTMATCH}END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('AABABCXXYXYZ456' =~ /(${POSTMATCH})/) {
        if ($& eq 'XYZ456') {
            print qq{ok - 6 /\${POSTMATCH}/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 6 /\${POSTMATCH}/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 /\${POSTMATCH}/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 /\${POSTMATCH}/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('AABABCXXYXYZ456' =~ m/(${POSTMATCH})/) {
        if ($& eq 'XYZ456') {
            print qq{ok - 7 m/\${POSTMATCH}/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 7 m/\${POSTMATCH}/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 7 m/\${POSTMATCH}/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 m/\${POSTMATCH}/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    $_ = 'AABABCXXYXYZ456';
    if ($_ =~ s/(${POSTMATCH})/jkl/) {
        if ($_ eq 'AABABCXXYjkl') {
            print qq{ok - 8 s/\${POSTMATCH}// $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 8 s/\${POSTMATCH}// $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 8 s/\${POSTMATCH}// $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 s/\${POSTMATCH}// $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(/${POSTMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 9 split(/${POSTMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 split(/${POSTMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 split(/${POSTMATCH}/) $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(m/${POSTMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 10 split(m/${POSTMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 split(m/${POSTMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 split(m/${POSTMATCH}/) $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(qr/${POSTMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 11 split(qr/${POSTMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 split(qr/${POSTMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 split(qr/${POSTMATCH}/) $^X $__FILE__\n};
}

__END__

