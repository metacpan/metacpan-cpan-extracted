use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'Date::EzDate',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Date::EzDate - Date and time manipulation made easy',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/Date/EzDate.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {}
             };


WriteMakefile(%$make_args);
