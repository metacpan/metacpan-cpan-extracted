use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CPM',
    AUTHOR              => q{Juan Jose 'Peco' San Martin <peco@cpan.org>},
    VERSION_FROM        => 'lib/CPM.pm',
    ABSTRACT_FROM       => 'lib/CPM.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'IO::Socket' => 0,
        'Net::SNMP' => 0,
        'Net::Address::IP::Local' => 0,
        'Net::Ping' => 0,
        'Net::SMTP_auth' => 0,
        'LWP::UserAgent' => 0,
        'XML::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CPM-*' },
);
