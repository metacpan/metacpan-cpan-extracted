use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'DBD::PgPPSjis',
    'VERSION_FROM'  => 'lib/DBD/PgPPSjis.pm',
    'ABSTRACT_FROM' => 'lib/DBD/PgPPSjis.pm',
    'PREREQ_PM'     => {
        'DBI' => 1.0,
    },
    'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
);

__END__
