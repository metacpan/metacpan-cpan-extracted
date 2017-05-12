# encoding: Big5Plus
use Big5Plus;
print "1..31\n";

my $__FILE__ = __FILE__;

# [\\]
if ("\\" =~ m/[\\]/) {
    print qq{ok - 1 "\\\\" =~ m/[\\\\]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 1 "\\\\" =~ m/[\\\\]/ $^X $__FILE__\n};
}

# [|]
if ("|" =~ m/[|]/) {
    print qq{ok - 2 "|" =~ m/[|]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 2 "|" =~ m/[|]/ $^X $__FILE__\n};
}

# [(]
if ("(" =~ m/[(]/) {
    print qq{ok - 3 "(" =~ m/[(]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 3 "(" =~ m/[(]/ $^X $__FILE__\n};
}

# [)]
if (")" =~ m/[)]/) {
    print qq{ok - 4 ")" =~ m/[)]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 4 ")" =~ m/[)]/ $^X $__FILE__\n};
}

# [[]
if ("[" =~ m/[[]/) {
    print qq{ok - 5 "[" =~ m/[[]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 5 "[" =~ m/[[]/ $^X $__FILE__\n};
}

# [{]
if ("{" =~ m/[{]/) {
    print qq<ok - 6 "{" =~ m/[{]/\n>;
}
else{
    print qq<not ok - 6 "{" =~ m/[{]/\n>;
}

# [\^]
if ("^" =~ m/[\^]/) {
    print qq{ok - 7 "^" =~ m/[\\^]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 7 "^" =~ m/[\\^]/ $^X $__FILE__\n};
}

# [\$]
if ("\$" =~ m/[\$]/) {
    print qq{ok - 8 "\\\$" =~ m/[\\\$]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 8 "\\\$" =~ m/[\\\$]/ $^X $__FILE__\n};
}

# [*]
if ("*" =~ m/[*]/) {
    print qq{ok - 9 "*" =~ m/[*]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 9 "*" =~ m/[*]/ $^X $__FILE__\n};
}

# [+]
if ("+" =~ m/[+]/) {
    print qq{ok - 10 "+" =~ m/[+]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 10 "+" =~ m/[+]/ $^X $__FILE__\n};
}

# [?]
if ("?" =~ m/[?]/) {
    print qq{ok - 11 "?" =~ m/[?]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 11 "?" =~ m/[?]/ $^X $__FILE__\n};
}

# [.]
if ("." =~ m/[.]/) {
    print qq{ok - 12 "." =~ m/[.]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 12 "." =~ m/[.]/ $^X $__FILE__\n};
}
if ("A" !~ m/[.]/) {
    print qq{ok - 13 "A" !~ m/[.]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 13 "A" !~ m/[.]/ $^X $__FILE__\n};
}

# [-]
if ("-" =~ m/[-]/) {
    print qq{ok - 14 "-" =~ m/[-]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 14 "-" =~ m/[-]/ $^X $__FILE__\n};
}

# [A-]
if ("A" =~ m/[A-]/) {
    print qq{ok - 15 "A" =~ m/[A-]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 15 "A" =~ m/[A-]/ $^X $__FILE__\n};
}
if ("-" =~ m/[A-]/) {
    print qq{ok - 16 "-" =~ m/[A-]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 16 "-" =~ m/[A-]/ $^X $__FILE__\n};
}

# [-Z]
if ("-" =~ m/[-Z]/) {
    print qq{ok - 17 "-" =~ m/[-Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 17 "-" =~ m/[-Z]/ $^X $__FILE__\n};
}
if ("Z" =~ m/[-Z]/) {
    print qq{ok - 18 "Z" =~ m/[-Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 18 "Z" =~ m/[-Z]/ $^X $__FILE__\n};
}

# [--Z]
if ("-" =~ m/[--Z]/) {
    print qq{ok - 19 "-" =~ m/[--Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 19 "-" =~ m/[--Z]/ $^X $__FILE__\n};
}
if ("A" =~ m/[--Z]/) {
    print qq{ok - 20 "A" =~ m/[--Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 20 "A" =~ m/[--Z]/ $^X $__FILE__\n};
}
if ("Z" =~ m/[--Z]/) {
    print qq{ok - 21 "Z" =~ m/[--Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 21 "Z" =~ m/[--Z]/ $^X $__FILE__\n};
}

# [^-]
if ("-" !~ m/[^-]/) {
    print qq{ok - 22 "-" !~ m/[^-]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 22 "-" !~ m/[^-]/ $^X $__FILE__\n};
}
if ("A" =~ m/[^-]/) {
    print qq{ok - 23 "A" =~ m/[^-]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 23 "A" =~ m/[^-]/ $^X $__FILE__\n};
}

# [^A-]
if ("A" !~ m/[^A-]/) {
    print qq{ok - 24 "A" !~ m/[^A-]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 24 "A" !~ m/[^A-]/ $^X $__FILE__\n};
}
if ("-" !~ m/[^A-]/) {
    print qq{ok - 25 "-" !~ m/[^A-]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 25 "-" !~ m/[^A-]/ $^X $__FILE__\n};
}

# [^-Z]
if ("-" !~ m/[^-Z]/) {
    print qq{ok - 26 "-" !~ m/[^-Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 26 "-" !~ m/[^-Z]/ $^X $__FILE__\n};
}
if ("Z" !~ m/[^-Z]/) {
    print qq{ok - 27 "Z" !~ m/[^-Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 27 "Z" !~ m/[^-Z]/ $^X $__FILE__\n};
}

# [^--Z]
if ("-" !~ m/[^--Z]/) {
    print qq{ok - 28 "-" !~ m/[^--Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 28 "-" !~ m/[^--Z]/ $^X $__FILE__\n};
}
if ("A" !~ m/[^--Z]/) {
    print qq{ok - 29 "A" !~ m/[^--Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 29 "A" !~ m/[^--Z]/ $^X $__FILE__\n};
}
if ("Z" !~ m/[^--Z]/) {
    print qq{ok - 30 "Z" !~ m/[^--Z]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 30 "Z" !~ m/[^--Z]/ $^X $__FILE__\n};
}

# [^^]
if ("^" !~ m/[^^]/) {
    print qq{ok - 31 "^" !~ m/[^^]/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 31 "^" !~ m/[^^]/ $^X $__FILE__\n};
}

__END__
