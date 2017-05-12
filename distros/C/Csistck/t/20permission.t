use Test::More;
use Test::Exception;
use Csistck;
use File::Temp;
use File::stat;

plan tests => 6;

# Make file and test array (due to glob)
my $h = File::Temp->new();
my $file = $h->filename;
print $h "Test";
chmod(oct('0666'), $file);
my $perm = Csistck::Test::File->new($file, mode => '0660');

# Get first test, make sure we are what we are
isa_ok($perm, Csistck::Test);
ok($perm->can('check'));

# Expect check to fail first, as well as manual. Repair and final check should
# succeed, throw in a manual check again to test Csistck::Test abstraction
ok($perm->check, "Manual check of mode" );
isa_ok($perm->check, Csistck::Test::Return, "Manual check return");
ok($perm->execute('repair')->passed, 'Testing repair operation');
ok($perm->execute('check')->passed, 'Testing file mode again');

1;
