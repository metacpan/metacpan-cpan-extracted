%close = (
    '(' => '\\)',
    '[' => ']'
);
sub CLOSE { warn "@_\n"; '' }

undef $/;
$_ = <>;
s/^\S+//gm;
s/^.+ex-.+\n//gm;
1 while s/([\[\(])(??{"[^$close{$1}]+[$close{$1}]"})//;
s/->\S+$//gm;
print
