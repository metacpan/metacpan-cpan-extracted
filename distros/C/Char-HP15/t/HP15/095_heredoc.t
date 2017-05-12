# encoding: HP15
# This file is encoded in HP-15.
die "This file is not encoded in HP-15.\n" if q{あ} ne "\x82\xa0";

use HP15;
print "1..6\n";

my $__FILE__ = __FILE__;

my $aaa = 'AAA';
my $bbb = 'BBB';

if (<<'END' eq "ソ\$aaaソ\n" and <<'END' eq "表\$bbb表\n") {
ソ$aaaソ
END
表$bbb表
END
    print qq{ok - 1 <<'END' and <<'END' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 <<'END' and <<'END' $^X $__FILE__\n};
}

if (<<\END eq "ソ\$aaaソ\n" and <<\END eq "表\$bbb表\n") {
ソ$aaaソ
END
表$bbb表
END
    print qq{ok - 2 <<\\END and <<\\END $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 <<\\END and <<\\END $^X $__FILE__\n};
}

if (<<END eq "ソ\L$aaaソ\n" and <<END eq "表\L$bbb\E表\n") {
ソ\L$aaaソ
END
表\L$bbb\E表
END
    print qq{ok - 3 <<END and <<END $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 <<END and <<END $^X $__FILE__\n};
}

if (<<"END" eq "ソ\L$aaaソ\n" and <<"END" eq "表\L$bbb\E表\n") {
ソ\L$aaaソ
END
表\L$bbb\E表
END
    print qq{ok - 4 <<"END" and <<"END" $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 <<"END" and <<"END" $^X $__FILE__\n};
}

if (<<'END' eq "ソ\$aaaソ\n" and <<END eq "ソ$aaaソ\n" and <<'END' eq "表\$bbb表\n") {
ソ$aaaソ
END
ソ$aaaソ
END
表$bbb表
END
    print qq{ok - 5 <<'END' and <<"END" and <<'END' $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 <<'END' and <<"END" and <<'END' $^X $__FILE__\n};
}

if (<<END eq "ソ\L$aaaソ\n" and <<'END' eq "表\$bbb表\n" and <<END eq "表\L$bbb\E表\n") {
ソ\L$aaaソ
END
表$bbb表
END
表\L$bbb\E表
END
    print qq{ok - 6 <<END and <<'END' and <<END $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 <<END and <<'END' and <<END $^X $__FILE__\n};
}

__END__
