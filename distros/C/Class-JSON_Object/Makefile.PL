#! perl

use strict;
use warnings;

exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.026000;

use ExtUtils::MakeMaker 7.54;

# For binaries/scripts.
my @bins; # = qw( prog );

my %makemaker =
  ( 'ExtUtils::MakeMaker' => 7.54 );

my %prereq =
  ( 'Test2::Suite'        => 0,
    'Object::Pad'         => 0.814,
  );

my %w =
( NAME                => 'Class::JSON_Object',
  AUTHOR              => 'Johan Vromans <jv@cpan.org>',
  VERSION_FROM        => 'lib/Class/JSON_Object.pm',
  ABSTRACT_FROM       => 'lib/Class/JSON_Object.pm',
  LICENSE             => 'perl_5',
  PL_FILES            => {},
  MIN_PERL_VERSION    => '5.026000',

  @bins == 0 ? () : (
    EXE_FILES         => [ map { "script/$_" } @bins ],
    PL_FILES          => {
			   'script/pp.PL' => [ map { "script/$_" } @bins ]
			 },
  ),

  PREREQ_PM => {
    %makemaker,
    %prereq,
  },

  CONFIGURE_REQUIRES => {
    %makemaker,
  },

#  BUILD_REQUIRES => {
#  },

  TEST_REQUIRES  => {
    %prereq,
  },

  META_MERGE => {
    resources    => {
      repository => 'https://github.com/sciurius/perl-Class-JSON_Object',
      bugtracker => "https://github.com/sciurius/perl-Class-JSON_Object/issues",
      license    => "https://dev.perl.org/licenses/",
    },
    'meta-spec' => {
      version => '2',
      url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
    },
  },
);

WriteMakefile(%w);
