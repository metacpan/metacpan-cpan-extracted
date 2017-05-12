#!perl -w

use strict;

=head1 NAME

nodebugwords.t - Checks that there are no words such as DESIGNME, FIXME,
DOCUMENTME, XXX and so on left in the source code.  Other markers
(such as UNIMPLEMENTED, OBSOLESCENT, OBSOLETE) are left alone.

=cut

use Test::More;
unless (eval <<"USE") {
use Test::NoBreakpoints qw(all_perl_files);
1;
USE
    plan skip_all => "Test::NoBreakpoints required";
    warn $@ if $ENV{DEBUG};
    exit;
}

plan no_plan => 1;

foreach my $file (all_perl_files(qw(Build.PL Build lib t))) {
    next if $file =~ m/nodebugwords\.t/; # Heh.
    local *FILE;
    open(FILE, $file) or die "Cannot open $file for reading: $!\n";
    my ($badwords_count, $lineno);
    while (<FILE>) {
        $lineno++;
        foreach my $badword (qw(DESIGNME FIXME DOCUMENTME XXX)) {
            next unless m/\b$badword\b/;
            diag "$badword found at $file line $lineno";
            $badwords_count++;
        }
    }
    ok(! $badwords_count, "no debug words found in $file");
}
