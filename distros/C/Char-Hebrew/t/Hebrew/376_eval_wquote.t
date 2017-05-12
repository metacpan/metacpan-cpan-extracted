# encoding: Hebrew
# This file is encoded in Hebrew.
die "This file is not encoded in Hebrew.\n" if q{ } ne "\x82\xa0";

use Hebrew;

print "1..12\n";

# eval "..." has eval "..."
if (eval Hebrew::escape " eval Hebrew::escape \" if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } \" ") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval "..." has eval qq{...}
if (eval Hebrew::escape " eval Hebrew::escape qq{ if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } } ") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval "..." has eval '...'
if (eval Hebrew::escape " eval Hebrew::escape ' if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } ' ") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval "..." has eval q{...}
if (eval Hebrew::escape " eval Hebrew::escape q{ if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } } ") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval "..." has eval $var
my $var = q{q{ if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } }};
if (eval Hebrew::escape " eval Hebrew::escape $var ") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval "..." has eval (omit)
$_ = "if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 }";
if (eval Hebrew::escape " eval Hebrew::escape ") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval "..." has eval {...}
if (eval Hebrew::escape " eval { if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return 1 } else { return 0 } } ") {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval "..." has "..."
if (eval Hebrew::escape " if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return \"1\" } else { return \"0\" } ") {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval "..." has qq{...}
if (eval Hebrew::escape " if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return qq{1} } else { return qq{0} } ") {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval "..." has '...'
if (eval Hebrew::escape " if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return '1' } else { return '0' } ") {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval "..." has q{...}
if (eval Hebrew::escape " if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return q{1} } else { return q{0} } ") {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval "..." has $var
my $var1 = 1;
my $var0 = 0;
if (eval Hebrew::escape " if (Hebrew::length(q{¦±²²³´´µ¶·¸¹÷»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜ}) == 47) { return $var1 } else { return $var0 } ") {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
