use 5.008; #Unicode
use ExtUtils::MakeMaker;

eval "use Coro::MakeMaker qw(coro_args);";
if($@){ die 'Install Coro first! '};

WriteMakefile(coro_args(
  'NAME' => 'Coro::LocalScalar::XS',
  'VERSION' => '0.2',
  'OPTIMIZE' => ' -O2'));

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
