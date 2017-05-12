# encoding: USASCII
# This file is encoded in US-ASCII.
die "This file is not encoded in US-ASCII.\n" if q{┌═} ne "\x82\xa0";

use USASCII;

print "1..12\n";

# eval '...' has eval "..."
if (eval USASCII::escape ' eval USASCII::escape " if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return 1 } else { return 0 } " ') {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval '...' has eval qq{...}
if (eval USASCII::escape ' eval USASCII::escape qq{ if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return 1 } else { return 0 } } ') {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval '...' has eval '...'
if (eval USASCII::escape ' eval USASCII::escape \' if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return 1 } else { return 0 } \' ') {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval '...' has eval q{...}
if (eval USASCII::escape ' eval USASCII::escape q{ if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return 1 } else { return 0 } } ') {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval '...' has eval $var
my $var = q{ if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return 1 } else { return 0 } };
if (eval USASCII::escape ' eval USASCII::escape $var ') {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval '...' has eval (omit)
$_ = "if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return 1 } else { return 0 }";
if (eval USASCII::escape ' eval USASCII::escape ') {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval '...' has eval {...}
if (eval USASCII::escape ' eval { if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return 1 } else { return 0 } } ') {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval '...' has "..."
if (eval USASCII::escape ' if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return "1" } else { return "0" } ') {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval '...' has qq{...}
if (eval USASCII::escape ' if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return qq{1} } else { return qq{0} } ') {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval '...' has '...'
if (eval USASCII::escape ' if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return \'1\' } else { return \'0\' } ') {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval '...' has q{...}
if (eval USASCII::escape ' if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return q{1} } else { return q{0} } ') {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval '...' has $var
my $var1 = 1;
my $var0 = 0;
if (eval USASCII::escape ' if (USASCII::length(q{╕╠╡╡Ё╢╢╣╤╥╦╧╨╩╪╫╬©юабцдефгхийклмнопярстужвьызшэ}) == 47) { return $var1 } else { return $var0 } ') {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
