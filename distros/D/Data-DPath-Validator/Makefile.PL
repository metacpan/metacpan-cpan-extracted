
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Data-DPath-Validator',
  NAME      => 'Data::DPath::Validator',
  AUTHOR    => "Nicholas\ Perez\ \<nperez\@cpan\.org\>",
  ABSTRACT  => "Validate\ data\ based\ on\ Perl\ data\ structure\ templates",
  VERSION   => '0.093411',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.92',
    "MooseX::Role::BuildInstanceOf" => '0.02',
    "Scalar::Util" => '1.22',
    "namespace::autoclean" => '0.09',
    "MooseX::Types" => '0.20',
    "Data::DPath" => '0.32',
    "Data::Visitor" => '0.26',
    "Moose" => '0.93',
  },
  test => {TESTS => 't/*.t'}
);

