#!/usr/bin/perl

use strict;
use warnings;

use File::Compare;
use File::Which;
use Test::More;
use Test::Exception;
use FindBin;
use BioX::Seq;
use BioX::Seq::Utils qw/rev_com is_nucleic all_orfs build_ORF_regex/;

chdir $FindBin::Bin;

#----------------------------------------------------------------------------#
# BioX::Seq::Utils testing
#----------------------------------------------------------------------------#

my $seq = 'AATE';
throws_ok { rev_com($seq) } qr/Bad input sequence/, 'undefined quality check';

done_testing();
exit;
