#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

our ($VERSION) = '$Revision: 1.2 $' =~ /(\d+\.\d+)/;


WriteMakefile(
    NAME         => 'DS',
    AUTHOR       => 'Michael Zedeler',
    VERSION_FROM => 'lib/DS.pm',
    PREREQ_PM    => {
                        'Carp::Assert'      => '0.20',
                        'IO::File'          => '1.11',
                        'List::MoreUtils'   => '0.21',
                        'Clone'             => '0.28'
    }
);
