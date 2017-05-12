use ExtUtils::MakeMaker;
my %options = %{
{
  'TYPEMAPS' => [],
  'NAME' => 'CPAN::Test::Dummy::Perl5::Make::CompilationFails',
  'INC' => '',
  'VERSION_FROM' => 'CompilationFails.pm',
   LICENSE => 'perl',
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
