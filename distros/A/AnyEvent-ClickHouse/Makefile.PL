use 5.10.0;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'AnyEvent::ClickHouse',
    VERSION_FROM      => 'lib/AnyEvent/ClickHouse.pm', 
    PREREQ_PM         => {
        'AnyEvent'               	=> 7.13,
        'AnyEvent::HTTP' 	        => 2.23,
        'URI'                           => 1.71,
        'URI::QueryParam'               => 1.71,
        'Data::Dumper'                  => 2.161,
        'Scalar::Util'                  => 1.46,
        'Test::HTTP::AnyEvent::Server' => 0.013,
        'strict'                => 0,
        'warnings'              => 0,
    },
    ABSTRACT_FROM     => 'lib/AnyEvent/ClickHouse.pm',
    AUTHOR            => 'Maxim Motylkov <mmv@cpan.org>',
    LICENSE           => 'perl',
    META_MERGE          => {
        requires        => {
                perl    => '5.10.0'
        }
    }
);
