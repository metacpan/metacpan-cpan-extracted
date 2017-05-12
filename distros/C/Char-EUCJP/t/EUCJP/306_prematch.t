# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use strict;
use EUCJP;
print "1..11\n";

my $__FILE__ = __FILE__;

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ($` eq 'ABC') {
        print qq{ok - 1 \$` $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$` $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$` $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ("$`" eq 'ABC') {
        print qq{ok - 2 "\$`" $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "\$`" $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "\$`" $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (qq{$`} eq 'ABC') {
        print qq{ok - 3 qq{\$`} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 qq{\$`} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 qq{\$`} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<END eq "ABC\n") {
$`
END
        print qq{ok - 4 <<END\$`END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 <<END\$`END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 <<END\$`END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<"END" eq "ABC\n") {
$`
END
        print qq{ok - 5 <<"END"\$`END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 <<"END"\$`END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 <<"END"\$`END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('AABABCXXYXYZ' =~ /($`)/) {
        if ($& eq 'ABC') {
            print qq{ok - 6 /\$`/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 6 /\$`/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 /\$`/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 /\$`/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('AABABCXXYXYZ' =~ m/($`)/) {
        if ($& eq 'ABC') {
            print qq{ok - 7 m/\$`/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 7 m/\$`/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 7 m/\$`/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 m/\$`/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    $_ = 'AABABCXXYXYZ';
    if ($_ =~ s/($`)/jkl/) {
        if ($_ eq 'AABjklXXYXYZ') {
            print qq{ok - 8 s/\$`// $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 8 s/\$`// $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 8 s/\$`// $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 s/\$`// $^X $__FILE__\n};
}

$_ = ',123,456,789';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(/$`/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 9 split(/$`/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 split(/$`/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 split(/$`/) $^X $__FILE__\n};
}

$_ = ',123,456,789';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(m/$`/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 10 split(m/$`/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 split(m/$`/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 split(m/$`/) $^X $__FILE__\n};
}

$_ = ',123,456,789';
if ($_ =~ m/([0-9]+)/) {
    @_ = split(qr/$`/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 11 split(qr/$`/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 split(qr/$`/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 split(qr/$`/) $^X $__FILE__\n};
}

__END__

