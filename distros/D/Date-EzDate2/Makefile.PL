use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'EXE_FILES' => [],
               'NAME' => 'Date::EzDate2',
               'PL_FILES' => {},
               'LICENSE' => 'perl',
               'ABSTRACT' => 'Date::EzDate2 - Date and time manipulation made easy',
               'PREREQ_PM' => {
                                'DateTime' => '1.34',
                                'Clone' => '0.38',
                                'DateTime::TimeZone' => '2.01',
                                'Test::Most' => '0.34'
                              },
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'VERSION_FROM' => 'lib/Date/EzDate2.pm'
             };


WriteMakefile(%$make_args);
