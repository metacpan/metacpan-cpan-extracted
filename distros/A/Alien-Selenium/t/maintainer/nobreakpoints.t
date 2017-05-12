#!perl

=head1 NAME

nobreakpoints.t - Checks that there are no soft breakpoints anywhere in the
source code (those are made by setting $DB::single to 1).

=cut

use Test::More;
unless (eval <<"USE") {
use Test::NoBreakpoints qw(all_files_no_breakpoints_ok all_perl_files);
1;
USE
    plan skip_all => "Test::NoBreakpoints required";
    warn $@ if $ENV{DEBUG};
    exit;
}

plan no_plan => 1;

all_files_no_breakpoints_ok(all_perl_files(qw(Build.PL Build lib inc t)));

