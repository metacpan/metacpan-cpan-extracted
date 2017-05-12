#!/usr/bin/perl

use 5.008003;
use strict;
use constant DEBUG => 0;

our $VERSION='0.001';

my $makefile=(-f 'Makefile')?('Makefile'):
             (-f 'makefile')?('makefile'):
             die "Could not found Makefile\n";

our %macros;
open  MAKEFILE, "<$makefile" or die "Cannot open  $makefile: $!\n";
while (<MAKEFILE>) {
    if (my ($macro_name,$macro_value) = m/^\s*([A-Z_]+)\s*=\s*(\S.+)/) {
        $macro_value =~ s/["']//g;
        $macros{$macro_name}=$macro_value;
        DEBUG && warn "DEBUG - $0: read macro $macro_name = $macro_value\n";
    }
}
close MAKEFILE               or die "Cannot close $makefile: $!\n";

sub subst_macro {
    my ($macro_name,$default_value)=@_;

    return (exists $macros{$macro_name})?("use constant $macro_name => quotemeta('".$macros{$macro_name}."');"):
                                         ("use constant $macro_name => $default_value;");
};

while (<>) {
    s/^\s*use\s+constant\s*([A-Z_]+)\s*=>\s*(\S+)/subst_macro($1,$2)/ge;
    print;
}
