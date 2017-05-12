# encoding: Big5HKSCS
use Big5HKSCS;
print "1..10\n";

my $__FILE__ = __FILE__;

local $^W = 0;

$a = split;
if ($a == 0) {
    print qq{ok - 1 \$a = split $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \$a = split $^X $__FILE__\n};
}

@a = split;
if ("@a" eq '') {
    print qq{ok - 2 \@a = split $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \@a = split $^X $__FILE__\n};
}

$a = split /A/;
if ($a == 0) {
    print qq{ok - 3 \$a = split /A/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 \$a = split /A/ $^X $__FILE__\n};
}

@a = split /A/;
if ("@a" eq '') {
    print qq{ok - 4 \@a = split /A/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 \@a = split /A/ $^X $__FILE__\n};
}

$a = split /A/, undef;
if ($a == 0) {
    print qq{ok - 5 \$a = split /A/, undef $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 \$a = split /A/, undef $^X $__FILE__\n};
}

@a = split /A/, undef;
if ("@a" eq '') {
    print qq{ok - 6 \@a = split /A/, undef $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 \@a = split /A/, undef $^X $__FILE__\n};
}

$a = split /A/, '';
if ($a == 0) {
    print qq{ok - 7 \$a = split /A/, '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 \$a = split /A/, '' $^X $__FILE__\n};
}

@a = split /A/, '';
if ("@a" eq '') {
    print qq{ok - 8 \@a = split /A/, '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 \@a = split /A/, '' $^X $__FILE__\n};
}

$a = split /A/, '', 3;
if ($a == 0) {
    print qq{ok - 9 \$a = split /A/, '', 3 $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 \$a = split /A/, '', 3 $^X $__FILE__\n};
}

@a = split /A/, '', 3;
if ("@a" eq '') {
    print qq{ok - 10 \@a = split /A/, '', 3 $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 \@a = split /A/, '', 3 $^X $__FILE__\n};
}

__END__
