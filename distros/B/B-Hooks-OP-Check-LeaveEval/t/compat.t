use Test::More tests => 4;
use B::Hooks::OP::Check::LeaveEval;

# just check if we're not breaking existing functionality
B::Hooks::OP::Check::LeaveEval::register(sub { 1 });

my $num = eval '1';
is $num, 1, 'constant eval';

my $tempfile = eval 'use File::Temp; File::Temp->new(UNLINK => 1)';
isa_ok $tempfile, 'File::Temp', 'module use eval';

my $result = eval 'die "error\n"; 1';
ok !defined $result, 'failing eval returns undef';
is $@, "error\n", '$@ contains the error message';
