require 5.6.0;

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'DNS::EasyDNS',
    'ABSTRACT'      => 'Update your EasyDNS dynamic DNS records',
    'AUTHOR'        => 'Gavin Brock <gbrock@cpan.org>',
    'PREREQ_PM'     => { 'LWP::UserAgent' => 2.001, 'HTTP::Request::Common' => 1.19 },
    'VERSION_FROM'  => 'lib/DNS/EasyDNS.pm',
    'dist'          => { COMPRESS=>'gzip', SUFFIX=>'gz' },
);
