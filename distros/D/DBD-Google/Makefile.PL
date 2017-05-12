use strict;

use DBI;
use DBI::DBD;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
    'DBI'               => 1.50,
    'HTML::Entities'    => 0,
    'Net::Google'       => 0.60,
    'Symbol'            => 0,
    'Test::More'        => 0,
    'URI::Escape'       => 0,
    'SQL::Statement'    => 1.00,
);

my %clean = (
    FILES => '$(DISTVNAME).tar$(SUFFIX) *.xsi',
);

WriteMakefile(
    NAME        => "DBD::Google",
    VERSION     => "0.51",
    PREREQ_PM   => \%PREREQ_PM,
    clean       => \%clean,
);

sub MY::postamble {
    return DBI::DBD::dbd_postamble(@_);
}
