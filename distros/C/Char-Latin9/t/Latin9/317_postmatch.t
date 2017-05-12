# encoding: Latin9
# This file is encoded in Latin-9.
die "This file is not encoded in Latin-9.\n" if q{ } ne "\x82\xa0";

use strict;
use Latin9;
print "1..11\n";

my $__FILE__ = __FILE__;

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if (${^POSTMATCH} eq 'XYZ456') {
        print qq{ok - 1 \${^POSTMATCH} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \${^POSTMATCH} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \${^POSTMATCH} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if ("${^POSTMATCH}" eq 'XYZ456') {
        print qq{ok - 2 "\${^POSTMATCH}" $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "\${^POSTMATCH}" $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "\${^POSTMATCH}" $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if (qq{${^POSTMATCH}} eq 'XYZ456') {
        print qq{ok - 3 qq{\${^POSTMATCH}} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 qq{\${^POSTMATCH}} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 qq{\${^POSTMATCH}} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if (<<END eq "XYZ456\n") {
${^POSTMATCH}
END
        print qq{ok - 4 <<END\${^POSTMATCH}END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 <<END\${^POSTMATCH}END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 <<END\${^POSTMATCH}END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if (<<"END" eq "XYZ456\n") {
${^POSTMATCH}
END
        print qq{ok - 5 <<"END"\${^POSTMATCH}END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 <<"END"\${^POSTMATCH}END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 <<"END"\${^POSTMATCH}END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if ('AABABCXXYXYZ456' =~ /(${^POSTMATCH})/) {
        if ($& eq 'XYZ456') {
            print qq{ok - 6 /\${^POSTMATCH}/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 6 /\${^POSTMATCH}/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 /\${^POSTMATCH}/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 /\${^POSTMATCH}/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    if ('AABABCXXYXYZ456' =~ m/(${^POSTMATCH})/) {
        if ($& eq 'XYZ456') {
            print qq{ok - 7 m/\${^POSTMATCH}/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 7 m/\${^POSTMATCH}/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 7 m/\${^POSTMATCH}/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 m/\${^POSTMATCH}/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/p) {
    $_ = 'AABABCXXYXYZ456';
    if ($_ =~ s/(${^POSTMATCH})/jkl/) {
        if ($_ eq 'AABABCXXYjkl') {
            print qq{ok - 8 s/\${^POSTMATCH}// $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 8 s/\${^POSTMATCH}// $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 8 s/\${^POSTMATCH}// $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 s/\${^POSTMATCH}// $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/p) {
    @_ = split(/${^POSTMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 9 split(/${^POSTMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 split(/${^POSTMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 split(/${^POSTMATCH}/) $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/p) {
    @_ = split(m/${^POSTMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 10 split(m/${^POSTMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 split(m/${^POSTMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 split(m/${^POSTMATCH}/) $^X $__FILE__\n};
}

$_ = ',123,';
if ($_ =~ m/([0-9]+)/p) {
    @_ = split(qr/${^POSTMATCH}/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 11 split(qr/${^POSTMATCH}/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 split(qr/${^POSTMATCH}/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 split(qr/${^POSTMATCH}/) $^X $__FILE__\n};
}

__END__

