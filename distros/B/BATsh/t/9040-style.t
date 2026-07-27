######################################################################
#
# 9040-style.t  Code style checks
#
#   check_C  US-ASCII only, no trailing whitespace, ends with newline
#   check_K  comma spacing and reference idioms in lib/*.pm
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

plan_tests(count_C($ROOT) + count_K($ROOT));
check_C($ROOT);
check_K($ROOT);

END { end_testing() }
