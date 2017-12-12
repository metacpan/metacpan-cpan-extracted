use 5.004;
use ExtUtils::MakeMaker;

# Y’know, it’d be nice if MM provided a way to ask whether a parameter is
# valid, instead of just screaming.  What’s more, old MMs print explicitly
# to STDOUT, making my job harder.
$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /is not a known parameter/};
*STDWHATEVER = *STDOUT; *STDOUT = *foo; tie *STDOUT, 'gronk';
{package #
 gronk;
 sub TIEHANDLE { bless[] }
 sub PRINT {
  shift;
  return if $_[0] =~ /is not a known MakeMaker parameter/;
  print ::STDWHATEVER @_;
 }
 sub PRINTF {
  shift;
  return if $_[0] =~ /is not a known MakeMaker parameter/;
  printf ::STDWHATEVER @_;
 }
}

WriteMakefile(
    NAME                => 'Acme::Eatemup',
    AUTHOR              => 'Father Chrysostomos <sprout [hat] cpan . org>',
    VERSION_FROM        => 'lib/Acme/Eatemup.pm',
    ABSTRACT_FROM       => 'lib/Acme/Eatemup.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	Exporter        => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'Acme-Eatemup-*' },
    META_MERGE         => { dynamic_config => 0 },
    MIN_PERL_VERSION   => 5,
);
