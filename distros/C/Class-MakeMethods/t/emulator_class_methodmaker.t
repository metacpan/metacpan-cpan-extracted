use Test;
use Test::Harness; 
BEGIN { plan tests => 1 }

my $subtest_dir = 'emulator_class_methodmaker';
my $subtest_glob = "t/$subtest_dir/*.t";

my @tests = glob($subtest_glob);
my $count = scalar @tests
    or die "Can't find subtests: $subtest_glob\n";

warn "Running $count subtests from $subtest_glob...\n";
ok( runtests( @tests ) )
