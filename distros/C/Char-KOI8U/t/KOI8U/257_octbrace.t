# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8U;
print "1..5\n";

my $__FILE__ = __FILE__;

# ""
if ("\o{2215053170}" eq "\x12\x34\x56\x78") {
    print qq{ok - 1 "\\o{2215053170}" eq "\\x12\\x34\\x56\\x78" $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "\\o{2215053170}" eq "\\x12\\x34\\x56\\x78" $^X $__FILE__\n};
}

# <<HEREDOC
my $var1 = <<END;
\o{2215053170}
END
my $var2 = <<END;
\x12\x34\x56\x78
END
if ($var1 eq $var2) {
    print qq{ok - 2 <<END \\o{2215053170} END eq <<END \\x12\\x34\\x56\\x78 END $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 <<END \\o{2215053170} END eq <<END \\x12\\x34\\x56\\x78 END $^X $__FILE__\n};
}

# m//
if ("\x12\x34\x56\x78" =~ /\o{2215053170}/) {
    print qq{ok - 3 "\\x12\\x34\\x56\\x78" =~ /\\o{2215053170}/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "\\x12\\x34\\x56\\x78" =~ /\\o{2215053170}/ $^X $__FILE__\n};
}

# s///
my $var = "\x12\x34\x56\x78";
if ($var =~ s/\o{2215053170}//) {
    print qq{ok - 4 "\\x12\\x34\\x56\\x78" =~ s/\\o{2215053170}// $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "\\x12\\x34\\x56\\x78" =~ s/\\o{2215053170}// $^X $__FILE__\n};
}

# split //
@_ = split(/\o{2215053170}/,"AAA\x12\x34\x56\x78BBB\x12\x34\x56\x78CCC");
if (scalar(@_) == 3) {
    print qq{ok - 5 split(/\\o{2215053170}/,"AAA\\x12\\x34\\x56\\x78BBB\\x12\\x34\\x56\\x78CCC") == 3 $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 split(/\\o{2215053170}/,"AAA\\x12\\x34\\x56\\x78BBB\\x12\\x34\\x56\\x78CCC") == 3 $^X $__FILE__\n};
}

__END__
