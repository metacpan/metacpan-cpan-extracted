use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;    # do not supply an empty list because import() has to be called
use File::Spec::Functions qw( catfile );

my @main_module_namespace = qw( Class Enumeration );
my $release_status        = 'stable';                  # transition: unstable => testing => stable

my $distname            = join '-',  @main_module_namespace;
my $main_module         = join '::', @main_module_namespace;
my $main_module_file    = catfile( @main_module_namespace ) . '.pm';
my $main_module_podfile = catfile( @main_module_namespace ) . '.pod';
# we are not using
# VERSION_FROM  => catfile( 'lib', $main_module_file )
# because we have to set the main module version in META_MERGE/provides too
my $main_module_version = MM->parse_version( catfile( 'lib', $main_module_file ) );

my %att = (
  NAME          => $main_module,
  AUTHOR        => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION       => $main_module_version,
  ABSTRACT_FROM => catfile( 'lib', $main_module_podfile ),
  # another valid license string is "restricted"
  # https://metacpan.org/pod/CPAN::Meta::Spec#license
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.010001',
  # safe naming of custom arguments passed to Makefile.PL
  # https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/470
  DISTVNAME => "$distname-$main_module_version"
    . ( $release_status ne 'stable' ? '-TRIAL1' : '' ),    # related to the below release_status metadata field
  META_MERGE => {
    'meta-spec'    => { version => 2 },
    release_status => $release_status,
    provides       => {
      $main_module => {
        file    => catfile( 'lib', $main_module_file ),
        version => $main_module_version
      },
      join( '::', $main_module, 'Builder' ) => {
        file    => catfile( 'lib', @main_module_namespace, 'Builder' ) . '.pm',
        version => $main_module_version
      }
    },
    resources => {
      repository => {
        type => 'git',
        url  => "https://github.com/XSven/$distname.git",
        web  => "https://github.com/XSven/$distname"
      },
      bugtracker => {
        web => "https://github.com/XSven/$distname/issues"
      }
    }
  },
  # check ExtUtils::MakeMaker Changes
  NORECURS  => 1,
  clean     => { FILES                => "$distname*" },
  dist      => { TARFLAGS             => 'cf', COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
  realclean => { FILES                => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 }
);

# Makefile.PL as a modulino
# https://www.masteringperl.org/2015/01/makefile-pl-as-a-modulino/
if ( caller() ) {
  no warnings qw( redefine ); ## no critic (ProhibitNoWarnings)
  # redefine ExtUtils::MakeMaker::WriteMakefile() to echo its atributes
  *ExtUtils::MakeMaker::WriteMakefile = sub {
    +{ @_ }    # \%att
  };
  # re-trigger the ExtUtils::MakeMaker::WriteMakefile() modification
  ExtUtils::MakeMaker::CPANfile->import
}
WriteMakefile( %att )
