# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;

print "1..7\n";

local $@;
eval {
    { ... }
};
if (substr($@,0,length('Unimplemented')) eq 'Unimplemented') {
    print qq{ok - 1 { ... } $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 { ... } $^X @{[__FILE__]}\n};
}

local $@;
sub foo1 { ... }
eval {
    foo1();
};
if (substr($@,0,length('Unimplemented')) eq 'Unimplemented') {
    print qq{ok - 2 sub foo1 { ... } $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 sub foo1 { ... } $^X @{[__FILE__]}\n};
}

local $@;
eval {
    ...;
};
if (substr($@,0,length('Unimplemented')) eq 'Unimplemented') {
    print qq{ok - 3 ...; $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 ...; $^X @{[__FILE__]}\n};
}

local $@;
eval {
    ...
};
if (substr($@,0,length('Unimplemented')) eq 'Unimplemented') {
    print qq{ok - 4 eval { ... }; $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 eval { ... }; $^X @{[__FILE__]}\n};
}

local $@;
sub foo2 { my($self)=shift; ...; }
eval {
    foo2();
};
if (substr($@,0,length('Unimplemented')) eq 'Unimplemented') {
    print qq{ok - 5 sub foo2 {my(\$self)=shift;...;} $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 sub foo2 {my(\$self)=shift;...;} $^X @{[__FILE__]}\n};
}

local $@;
eval {
    do {my $n; ...; print 'Hurrah!'};
};
if (substr($@,0,length('Unimplemented')) eq 'Unimplemented') {
    print qq{ok - 6 do {my \$n; ...; print 'Hurrah!'}; $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 do {my \$n; ...; print 'Hurrah!'}; $^X @{[__FILE__]}\n};
}

local $@;
eval {
    my @transformed = map {; ... } (1..10);
};
if (substr($@,0,length('Unimplemented')) eq 'Unimplemented') {
    print qq{ok - 7 my \@transformed = map {; ... } (1..10); $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 my \@transformed = map {; ... } (1..10); $^X @{[__FILE__]}\n};
}

__END__
