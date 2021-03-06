# Note: this file was auto-generated by Module::Build::Compat version 0.4210
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'CPAN::Mini::Inject::Remote',
  'VERSION_FROM' => 'lib/CPAN/Mini/Inject/Remote.pm',
  'PREREQ_PM' => {
                   'Archive::Tar' => 0,
                   'CPAN::Meta' => 0,
                   'File::Spec' => 0,
                   'Getopt::Long' => 0,
                   'HTTP::Request' => 0,
                   'HTTP::Request::Common' => 0,
                   'LWP::UserAgent' => 0,
                   'Params::Validate' => 0,
                   'Pod::Usage' => 0,
                   'Test::More' => 0,
                   'YAML::Any' => 0
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [
                   'bin/mcpani_remote',
                   'bin/mcpani_remote.pl'
                 ],
  'PL_FILES' => {}
)
;
