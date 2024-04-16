require 5.014000;
use ExtUtils::MakeMaker;
use Config;
die "Taint stuuport in perl is required for this module" unless (!exists($Config{taint_support}) || $Config{taint_support});
die "OS unsupported" if ($^O =~ /^(mswin|dos|os2)/oi);

WriteMakefile
(
  'PL_FILES' => {},
  'EXE_FILES' => [],
  'NAME' => 'Acme::TaintTest',
  'VERSION_FROM' => 'lib/Acme/TaintTest.pm',
  'PREREQ_PM' => {
                   'Cwd' => 0,
                   'File::Spec' => 0,
                   'File::Temp' => 0,
                   'Test::Simple' => 1.302067,
                   'Scalar::Util' => 0,
		   'Test::More' => 0,
		   'Carp' => 0,
		   'Mock::MonkeyPatch' => 0
                 },
  'INSTALLDIRS' => 'site'
)
;
