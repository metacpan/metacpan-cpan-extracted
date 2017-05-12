use strict;
use warnings;
use Test::Exception tests => 2;
use Data::Compare::Module;

throws_ok {
    my $obj = Data::Compare::Module->new('ModA');
} qr{\Athe constructor must receive 0 or 2 arguments}, "1 arg";

throws_ok {
    my $obj = Data::Compare::Module->new('ModA', 'ModB', 'ModC');
} qr{\Athe constructor must receive 0 or 2 arguments}, "3 modules";
