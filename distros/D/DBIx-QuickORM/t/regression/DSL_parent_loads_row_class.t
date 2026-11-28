# Test origin: AI
use Test2::V0;

use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

# A row block whose parent was another DSL row class, not loaded yet, croaked: the parent's own row
# block ran while the first block was still building.
my $lib = tempdir(CLEANUP => 1);
make_path("$lib/DSLR");
open(my $fh, '>', "$lib/DSLR/Base.pm") or die "Could not write DSLR/Base.pm: $!";
print $fh "package DSLR::Base;\nuse DBIx::QuickORM::DSL ':row';\nrow { parent };\nsub base { 'base' }\n1;\n";
close($fh) or die "Could not close DSLR/Base.pm: $!";
unshift @INC => $lib;

ok(lives { eval "package DSLR::Child; use DBIx::QuickORM::DSL ':row'; row { parent 'DSLR::Base' }; 1" or die $@ }, "A row block's parent may be a DSL row class loaded on the spot") or note($@);
isa_ok('DSLR::Child', ['DSLR::Base', 'DBIx::QuickORM::Row'], "and both blocks ran");
is(DSLR::Child->base, 'base', "with the parent's methods");

done_testing;
