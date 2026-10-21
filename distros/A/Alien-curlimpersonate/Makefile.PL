use v5.10; use strict; use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME             => 'Alien::curlimpersonate',
    DISTNAME         => 'Alien-curlimpersonate',
    VERSION_FROM     => 'lib/Alien/curlimpersonate.pm',
    ABSTRACT_FROM    => 'lib/Alien/curlimpersonate.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    # mm_args derives these from the alienfile itself; declared anyway because
    # a git checkout, unlike a CPAN install, has no META to read them from first.
    CONFIGURE_REQUIRES => {
        'Alien::Build::MM'                        => '0.32',
        'Alien::Build::Plugin::Download::Git'     => '0',
    },
    BUILD_REQUIRES     => {
        'Alien::Build::MM'                        => '0.32',
        'Alien::Build::Plugin::Download::Git'     => '0',
    },
    TEST_REQUIRES      => { 'Test::More' => '0.88', 'Test::Alien' => '2.53' },
    PREREQ_PM          => { 'Alien::Base' => '0' },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-alien-curlimpersonate.git',
                web  => 'https://github.com/vividsnow/perl5-alien-curlimpersonate',
            },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-alien-curlimpersonate/issues' },
        },
        (eval { require Module::Metadata; 1 }
            ? (provides => Module::Metadata->provides(version => 2, dir => 'lib'))
            : ()),
    },
));

# README is generated, never edited: it drifted from the POD twice while it was
# a hand-kept file. distdir depends on it so a release cannot ship a stale one.
sub MY::postamble {
    my $self = shift;
    return $abmm->mm_postamble($self) . <<"MAKE";

readme : README

README : lib/Alien/curlimpersonate.pm
\t\$(PERLRUN) -MPod::Text -e "Pod::Text->new->parse_from_file(q{lib/Alien/curlimpersonate.pm}, q{README})"

create_distdir : README

MAKE
}
