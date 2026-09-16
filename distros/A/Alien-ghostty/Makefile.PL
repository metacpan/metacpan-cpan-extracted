use v5.10;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

if ($abmm->build->install_type eq 'share') {
    my $zig = do { no warnings 'once'; $Alien::ghostty::Zig::ZIG_VERSION };
    die "OS unsupported: libghostty-vt cannot be built on MSWin32\n" if $^O eq 'MSWin32';
    die "OS unsupported: no prebuilt zig $zig for $^O; install zig $zig or set ALIEN_GHOSTTY_ZIG\n"
        unless Alien::ghostty::Zig::find() || Alien::ghostty::Zig::platform();
}

WriteMakefile($abmm->mm_args(
    NAME             => 'Alien::ghostty',
    DISTNAME         => 'Alien-ghostty',
    VERSION_FROM     => 'lib/Alien/ghostty.pm',
    ABSTRACT_FROM    => 'lib/Alien/ghostty.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',

    CONFIGURE_REQUIRES => {
        'Alien::Build'     => '2.60',
        'Alien::Build::MM' => '2.60',
    },
    BUILD_REQUIRES => {
        'Alien::Build::MM' => '2.60',
        'Digest::SHA'      => 0,
        'HTTP::Tiny'       => '0.056',
    },
    PREREQ_PM => {
        'Alien::Base' => '2.60',
    },
    TEST_REQUIRES => {
        'Test::More'  => '0.98',
        'Test::Alien' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-alien-ghostty.git',
                web  => 'https://github.com/vividsnow/perl5-alien-ghostty',
            },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-alien-ghostty/issues' },
        },
    },
));

sub MY::install {
    my ($mm, @rest) = @_;
    my $section = do { package MY; $mm->SUPER::install(@rest) };
    return ".NOTPARALLEL :\n\n.NO_PARALLEL :\n\ninstall :: alien_ghostty_clean_install\n\n$section";
}

sub MY::postamble {
    $abmm->mm_postamble . <<'MAKE';

alien_ghostty_clean_install : pure_all _alien/mm/prefix
	[ -n "$(DESTDIR)" ] || $(FULLPERL) -MAlien::Build::MM=cmd -e clean_install

readme : README

README : lib/Alien/ghostty.pm
	$(PERLRUN) -MPod::Text -e "Pod::Text->new->parse_from_file(q{lib/Alien/ghostty.pm}, q{README})"

create_distdir : README
MAKE
}
