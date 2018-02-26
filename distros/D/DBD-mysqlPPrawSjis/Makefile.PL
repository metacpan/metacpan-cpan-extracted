use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'DBD::mysqlPPrawSjis',
    'VERSION_FROM'  => 'lib/DBD/mysqlPPrawSjis.pm',
    'ABSTRACT_FROM' => 'lib/DBD/mysqlPPrawSjis.pm',
    'PREREQ_PM'     => {
        'DBI'        => 1.0,
        'Net::MySQL' => 0.08,
    },
    'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
);

__END__
