use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Daemon::Whois',
    AUTHOR              => q{Alexx Roche <notice-dev@alexx.net>},
    VERSION_FROM        => 'lib/Daemon/Whois.pm',
    ABSTRACT_FROM       => 'lib/Daemon/Whois.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'This program is free software; you can redistribute it and/or modify it
under the following license: Eclipse Public License, Version 1.0
See http://www.opensource.org/licenses/ for more information.
')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::Server'=> 0,
        'CDB_File'   => 0,
        'DateTime'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Daemon-Whois-*' },
);


