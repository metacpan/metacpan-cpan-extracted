use Test2::V0;
use Acme::Alien::DontPanic;
use File::chdir;


diag '';
diag '';
diag '';

diag "Acme::Alien::DontPanic->dynamic_libs = ", Acme::Alien::DontPanic->dynamic_libs;

diag '';
diag '';


pass 'and so it goes';

done_testing;
