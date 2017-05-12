use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::AlgebraicToRPN',
    AUTHOR              => 'X Cramps <cramps.the@gmail.com>',
    VERSION_FROM        => 'lib/Acme/AlgebraicToRPN.pm',
    ABSTRACT_FROM       => 'lib/Acme/AlgebraicToRPN.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Regexp::Common' => '2.120',
        'Perl6::Attributes' => '0.04',
        'Math::Symbolic' => '0.603',
        'Math::SymbolicX::ParserExtensionFactory' => '3.02',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-AlgebraicToRPN-*' },
);
