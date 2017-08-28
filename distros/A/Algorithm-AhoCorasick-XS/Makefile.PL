use v5.8.8;
use ExtUtils::MakeMaker;

$CC = "g++";

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # developer release/version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME         => "Algorithm::AhoCorasick::XS",
    VERSION_FROM => "lib/Algorithm/AhoCorasick/XS.pm",
    PREREQ_PM    => { 'Test::More' => 0.96, "Data::Dump" => 0, "List::MoreUtils" => 0 },
    TYPEMAPS     => ['perlobject.map', 'typemap'],
    CC           => $CC,
    LD           => '$(CC)',
    XSOPT        => '-C++',
    CCFLAGS       => '-Wall -std=c++11',
    OBJECT       => '$(O_FILES)',
    # Force the makefile to be regenerated when the version is changed
    depend       => { '$(FIRST_MAKEFILE)' => '$(VERSION_FROM)' },
    # New keywords since 5.5
    ($] >= 5.005 ? (
      ABSTRACT   => 'Algorithm::AhoCorasick::XS',
      AUTHOR     => 'Richard Harris <richardjharris@gmail.com>',
    ) : ()),
    ($mm_ver >= 6.48 ? (
      MIN_PERL_VERSION => 5.006,
    ) : ()),
);

# Possible fix for FreeBSD
sub MY::postamble {
    return <<'END'
test_dynamic ::

END
}
