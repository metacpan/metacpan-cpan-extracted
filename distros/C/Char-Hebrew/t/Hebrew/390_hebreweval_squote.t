# encoding: Hebrew
# This file is encoded in Hebrew.
die "This file is not encoded in Hebrew.\n" if q{ } ne "\x82\xa0";

use Hebrew;

print "1..12\n";

# Hebrew::eval '...' has Hebrew::eval "..."
if (Hebrew::eval ' Hebrew::eval " if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } " ') {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has Hebrew::eval qq{...}
if (Hebrew::eval ' Hebrew::eval qq{ if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } } ') {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has Hebrew::eval '...'
if (Hebrew::eval ' Hebrew::eval \' if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } \' ') {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has Hebrew::eval q{...}
if (Hebrew::eval ' Hebrew::eval q{ if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } } ') {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has Hebrew::eval $var
my $var = q{ if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } };
if (Hebrew::eval ' Hebrew::eval $var ') {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has Hebrew::eval (omit)
$_ = "if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 }";
if (Hebrew::eval ' Hebrew::eval ') {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has Hebrew::eval {...}
if (Hebrew::eval ' Hebrew::eval { if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } } ') {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has "..."
if (Hebrew::eval ' if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return "1" } else { return "0" } ') {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has qq{...}
if (Hebrew::eval ' if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return qq{1} } else { return qq{0} } ') {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has '...'
if (Hebrew::eval ' if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return \'1\' } else { return \'0\' } ') {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has q{...}
if (Hebrew::eval ' if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return q{1} } else { return q{0} } ') {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Hebrew::eval '...' has $var
my $var1 = 1;
my $var0 = 0;
if (Hebrew::eval ' if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return $var1 } else { return $var0 } ') {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
