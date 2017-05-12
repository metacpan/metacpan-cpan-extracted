#!perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Acme::Perl::VM;

open *SELF, '<', $0;
run_block{
    while(<SELF>){
        print;
    }
};
