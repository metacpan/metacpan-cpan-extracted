use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Amazon::EC2',
    AUTHOR       => q{Rob Lauer <rlauer6@comcast.net>},
    VERSION_FROM => 'lib/Amazon/EC2.pm',
    ABSTRACT     => 'Amazon AWS EC2 API interface',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
                  'Amazon::API'         => 0,
                  'Amazon::Credentials' => 0,
                  'JSON'                => 0,
                  'XML::Simple'         => 0
                  }
);
