use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Coro::Amazon::SimpleDB',
    AUTHOR              => q{Dave Trischuk <dtrischuk@cpan.org>},
    VERSION_FROM        => 'lib/Coro/Amazon/SimpleDB.pm',
    ABSTRACT_FROM       => 'lib/Coro/Amazon/SimpleDB.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'common::sense'            => 0,
        'Test::More'               => 0,
        'Carp'                     => 0,
        'Scalar::Util'             => 0,
        'List::Util'               => 0,
        'Moose'                    => 0,
        'Coro'                     => 0,
        'Coro::AnyEvent'           => 0,
        'AnyEvent'                 => 0,
        'AnyEvent::HTTP'           => 0,
        'EV'                       => 0,
        'HTTP::Request'            => 0,
        'HTTP::Response'           => 0,
        'Amazon::SimpleDB::Client' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Coro-Amazon-SimpleDB-*' },
);
