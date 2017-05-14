#!/usr/bin/perl
#______________________________________________________________________________
# Title     : Bioinf_module_test.pl
# Usage     : Bioinf_module_test.pl
# Function  : This is to make sure Bioinf module simply compiles when used
# Example   : Bioinf_module_test.pl
# Keywords  : test.pl
# Options   :
# Author    : jong@salt2.med.harvard.edu,
# Category  :
# Version   : 1.0
#------------------------------------------------------------------------------

use Bioinf;


@array=%hash=('a', 'bbb', 'c', 'dddd', 'd', 'ffffffffffffff');

&show_hash(\%hash);
&show_array(\@array); ## this sub is in Bioinf module



