use Test2::V0 -no_srand => 1;

our @system_args;
my $called_system = 0;
BEGIN {
  *CORE::GLOBAL::system = sub {
    @system_args = @_;
    $called_system = 1;
    return 0;
  }
}

use Browser::Start;

ok lives { open_url 'http://www.metacpan.org' }, "did not die" or diag "error = $@";
is $called_system, T(), "called system";
isnt \@system_args, [], 'argumetns are not empty';
note "command = @system_args";

done_testing
