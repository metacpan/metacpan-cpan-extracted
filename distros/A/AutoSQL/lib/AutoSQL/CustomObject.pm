package AutoSQL::CustomObject;
use strict;
use AutoSQL::Root;
our @ISA=qw(AutoSQL::Root);


BEGIN {
    ;
}

sub import {
    my $pkg=shift;
    my $schemapkg=shift;
    my $callpkg=caller;

    use $schemapkg;
    my $schema = $schemapkg->new;

}



