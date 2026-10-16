use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

# A final, deprecated release: Text::KDL::XS 0.003 bundles ckdl itself.
# The notice is informational; the build still works for the older
# Text::KDL::XS releases that depend on this Alien.
warn "Alien::ckdl is deprecated: Text::KDL::XS 0.003 and later bundle ckdl and no longer need it.\n";

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
        x_deprecated   => 1,
    },
));

sub MY::postamble {
    my $abmm_postamble = $abmm->mm_postamble;

    my $release_postamble = <<'MAKE_FRAG';

# --- Release target -------------------------------------------------
# Usage: make release
#
# Tests the dist via `make disttest`, builds the tarball via
# `make dist` (disttest alone only creates the unpacked directory),
# then uploads it to CPAN with cpan-upload (from CPAN::Uploader).
# Refuses to run if the git working tree is dirty, if a tag for the
# current $(VERSION) already exists, or if the GitHub CI run of HEAD
# has not passed (ci-check, which needs gh). See RELEASING.md.
#
# disttest and dist run as separate sub-makes on purpose: as
# prerequisites of one target they would share a single distdir
# build, and the tarball would pack the blib/ that disttest left
# behind. PAUSE refuses to index such a tarball.

.PHONY: release release-check ci-check

ci-check :
	@command -v gh >/dev/null 2>&1 || { \
	    echo "ERROR: gh not found in PATH; it reads the CI result of the release commit."; \
	    exit 1; \
	}
	@commit=$$(git rev-parse HEAD) || exit 1; \
	run=$$(gh run list --workflow ci.yml --commit "$$commit" --limit 1 --json status,conclusion --jq '.[] | "\(.status) \(.conclusion)"') || exit 1; \
	case "$$run" in \
	    "completed success") ;; \
	    "") echo "ERROR: no CI run for $$commit; push it and wait for CI first."; exit 1 ;; \
	    "completed "*) echo "ERROR: the CI run for $$commit did not pass ($${run#completed }); see gh run list --commit $$commit."; exit 1 ;; \
	    *) echo "ERROR: the CI run for $$commit has not finished; wait with gh run watch."; exit 1 ;; \
	esac

release-check : ci-check
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

release :: release-check
	$(MAKE) disttest
	$(MAKE) dist
	@test -f $(DISTVNAME).tar.gz || { \
	    echo "ERROR: $(DISTVNAME).tar.gz was not built; refusing to upload."; \
	    exit 1; \
	}
	@if tar tzf $(DISTVNAME).tar.gz | grep -qE '/(blib/|Makefile$$|MYMETA\.|pm_to_blib)'; then \
	    echo "ERROR: $(DISTVNAME).tar.gz contains build artefacts; refusing to upload."; \
	    exit 1; \
	fi
	cpan-upload $(DISTVNAME).tar.gz
	@echo
	@echo "Uploaded $(DISTVNAME).tar.gz to PAUSE."
	@echo "Next:"
	@echo "  git tag -a v$(VERSION) -m 'Release v$(VERSION)'"
	@echo "  git push --follow-tags"
MAKE_FRAG

    return $abmm_postamble . $release_postamble;
}
