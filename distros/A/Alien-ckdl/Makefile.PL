use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    DISTNAME         => 'Alien-ckdl',
    NAME             => 'Alien::ckdl',
    VERSION_FROM     => 'lib/Alien/ckdl.pm',
    ABSTRACT_FROM    => 'lib/Alien/ckdl.pm',
    AUTHOR           => 'Davenonymous <perl@davenonymous.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.52',
        'Alien::Build::MM'    => '0.32',
    },
    BUILD_REQUIRES => {
        'Alien::Build::MM' => '0.32',
    },
    PREREQ_PM => {
        'Alien::Base' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'  => '0.88',
        'Test::Alien' => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/tjol/ckdl',
            bugtracker => { web => 'https://github.com/Davenonymous/perl-alien-ckdl/issues' },
            repository => {
                type => 'git',
                url  => 'https://github.com/Davenonymous/perl-alien-ckdl.git',
                web  => 'https://github.com/Davenonymous/perl-alien-ckdl',
            },
        },
        dynamic_config => 1,
    },
));

sub MY::postamble {
    my $abmm_postamble = $abmm->mm_postamble;

    my $release_postamble = <<'MAKE_FRAG';

# --- Release target -------------------------------------------------
# Usage: make release
#
# Builds and tests the dist tarball via `make disttest`, then uploads
# it to CPAN with cpan-upload (from CPAN::Uploader). Refuses to run
# if the git working tree is dirty or if a tag for the current
# $(VERSION) already exists. See RELEASING.md.

.PHONY: release release-check

release-check :
	@git diff-index --quiet HEAD -- || { \
	    echo "ERROR: git working tree is dirty; commit or stash first."; \
	    exit 1; \
	}
	@if git rev-parse -q --verify "refs/tags/v$(VERSION)" >/dev/null; then \
	    echo "ERROR: tag v$(VERSION) already exists; bump \$$VERSION in lib/Alien/ckdl.pm."; \
	    exit 1; \
	fi
	@command -v cpan-upload >/dev/null 2>&1 || { \
	    echo "ERROR: cpan-upload not found in PATH; cpanm CPAN::Uploader"; \
	    exit 1; \
	}
	@test -r $(HOME)/.pause || { \
	    echo "ERROR: ~/.pause not found; see RELEASING.md for the format."; \
	    exit 1; \
	}

release :: release-check disttest
	cpan-upload $(DISTVNAME).tar.gz
	@echo
	@echo "Uploaded $(DISTVNAME).tar.gz to PAUSE."
	@echo "Next:"
	@echo "  git commit -am 'Release v$(VERSION)'"
	@echo "  git tag v$(VERSION)"
	@echo "  git push --follow-tags"
MAKE_FRAG

    return $abmm_postamble . $release_postamble;
}
