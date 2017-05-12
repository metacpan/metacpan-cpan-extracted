my @file = <*.pl>;

open M, '>LOCAL_MANIFEST' or die $!;

print M "scripts/$_\n" for @file;
