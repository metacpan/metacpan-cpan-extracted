#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use C::Tokenize '$cvar_re';
my $c = 'func (x->y, & z, ** a, & q);';
while ($c =~ /[,\(]\s*($cvar_re)/g) {
    print "$1 is a C variable.\n";
}
