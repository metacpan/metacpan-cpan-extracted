use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'DateTime::Util::DayOfWeek',
    AUTHOR        => 'Tokuhiro Matsuno <person@example.com>',
    'VERSION_FROM' => 'lib/DateTime/Util/DayOfWeek.pm',    # finds $VERSION
    MIN_PERL_VERSION => '5.008001',
    'PREREQ_PM'    => {
        'Test::More' => 0.98,
        'DateTime'   => 0.2901,
    },
	LICENSE => 'perl'
);
