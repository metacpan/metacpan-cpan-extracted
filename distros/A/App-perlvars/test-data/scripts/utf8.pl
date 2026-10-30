use strict;
use warnings;
use utf8;

# A Unicode identifier in code (é) trips PPI's raw-byte lexer, but the file is
# valid UTF-8 and compiles fine.
my $café = 'coffee';

sub brew {
    my $unused_utf8;
    return uc $café;
}

print brew(), "\n";
