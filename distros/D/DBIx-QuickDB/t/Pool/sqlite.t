use Test2::V0;
use Test2::Tools::QuickDB;
use File::Spec;

# Contaminate the ENV vars to make sure things work even when these are all
# set.
BEGIN { $ENV{$_} = 'fake' for qw{DBI_USER DBI_PASS DBI_DSN} }

skipall_unless_can_db(driver => 'SQLite');

sub DRIVER() { 'SQLite' }

my $file = __FILE__;
$file =~ s/sqlite\.t$/Pool.pm/;
$file = File::Spec->rel2abs($file);
require $file;

done_testing;
