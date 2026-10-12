use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use ExtUtils::MakeMaker 7.12;
use Config;

# -----------------------------------------------------------------------------
# Compile flags.
#
# Clay requires C99 (or C++20, but we use C). We force the standard and
# enable a strict warning baseline (GCC/Clang flags). Users who hit a
# portability issue can override CCFLAGS on the command line
# (perl Makefile.PL CCFLAGS=...) or through PERL_MM_OPT.
# -----------------------------------------------------------------------------

my @ccflags = qw( -std=c99 -Wall -Wextra -Wno-unused-parameter );

# Clay's vendored header probes for SIMD support itself. If a user
# environment lacks the relevant intrinsics, they can run:
#   PERL_CLAY_DISABLE_SIMD=1 perl Makefile.PL
if ($ENV{PERL_CLAY_DISABLE_SIMD}) {
    push @ccflags, '-DCLAY_DISABLE_SIMD';
}

my $ccflags = join(' ', @ccflags);

# -----------------------------------------------------------------------------
# Clay patches.
#
# The pristine upstream Clay header lives in src/clay/clay.h.orig (tracked in
# git). The build copy at src/clay/clay.h is regenerated each time the pristine
# header or a patch changes; the patches apply in this order, each on top of
# the previous ones. The patched header is written to a temporary file and
# moved into place only when every patch succeeds, so a failed patch never
# leaves an up-to-date-looking, unpatched src/clay/clay.h behind.
# src/clay/clay.h is gitignored so the working tree stays clean after a build.
# On Windows the patches are applied with --binary: Strawberry Perl's GNU
# patch 2.5.9 fails an assertion on LF patches without it, and the BSD patch
# of macOS does not know the option.
# -----------------------------------------------------------------------------

my @clay_patches = qw(
    patches/0001-clay-sizing-groups.patch
    patches/0002-clay-flow-layout.patch
    patches/0003-clay-back-to-front.patch
    patches/0004-clay-upstream-fixes.patch
);

# -----------------------------------------------------------------------------
# The C sources of the binding besides lib/Clay/XS.xs. Each gets an explicit
# compile rule in MY::postamble below.
# -----------------------------------------------------------------------------

my @c_sources = qw(
    src/clay_impl.c
    src/clay_perl_context.c
    src/marshal.c
    src/callbacks.c
);

sub object_of ($source) { return $source =~ s/\.c\z/\$(OBJ_EXT)/r }

WriteMakefile(
    NAME           => 'Clay::UI',
    VERSION_FROM   => 'lib/Clay/UI.pm',
    ABSTRACT_FROM  => 'lib/Clay/UI.pm',

    # The dist is Clay-UI, but the single XS module loads as Clay::XS
    # (see lib/Clay/XS.pm). XSMULTI places lib/Clay/XS.xs at the canonical
    # blib/arch/auto/Clay/XS/XS.so where XSLoader::load(__PACKAGE__) finds it.
    XSMULTI        => 1,
    XSBUILD        => {
        xs => {
            'lib/Clay/XS' => {
                OBJECT => join(' ', 'lib/Clay/XS$(OBJ_EXT)', map { object_of($_) } @c_sources),
                INC    => '-I. -Isrc',
            },
        },
    },
    AUTHOR         => 'davenonymous <perl@davenonymous.com>',
    LICENSE        => 'zlib',
    MIN_PERL_VERSION => '5.026',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.12',
    },
    PREREQ_PM => {
        'Exporter'         => '5.57',
        'List::Util'       => '1.45',
        'XSLoader'         => 0,
        'Object::Pad'      => '0.800',
        'Object::PadX::Enum' => '0.01',
    },
    TEST_REQUIRES => {
        'Test2::V0' => 0,
        'JSON::PP'  => 0,
    },

    C          => [ @c_sources ],
    H          => [ 'src/clay_perl.h',
                    'src/clay_perl_enums.h',
                    'src/clay_impl_helpers.h',
                    'src/clay/clay.h.orig' ],

    CCFLAGS    => "$Config{ccflags} $ccflags",

    # Sanity: clean intermediate objects.
    clean      => { FILES => 'lib/Clay/XS.c lib/Clay/XS.o src/*.o src/clay/clay.h src/clay/clay.h.tmp*' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        # tools/make-images renders the figures in images/ that the
        # documentation shows; both are shipped but not installed.
        no_index    => { directory => [qw(tools images)] },
        # tools/pod2markdown writes the Markdown pages in docs/ (make markdown)
        prereqs     => {
            develop => { requires => { 'Pod::Markdown' => '3.400' } },
        },
        resources   => {
            bugtracker => { web => 'https://github.com/davenonymous/perl-clay-xs/issues' },
            repository => {
                type => 'git',
                url  => 'https://github.com/davenonymous/perl-clay-xs.git',
                web  => 'https://github.com/davenonymous/perl-clay-xs',
            },
        },
    },
);

# In git only lib/Clay/UI.pm and lib/Clay/XS.pm carry a $VERSION; distdir
# (which `make disttest` and `make dist` both build on) gives every other
# module of the dist directory the dist version with tools/stamp-versions.
sub MY::distdir ($self, @args) {
    my $rules = $self->MM::distdir(@args);
    $rules =~ s{^(distdir :[^\n]*\n)}{$1\t\$(PERLRUN) tools/stamp-versions \$(DISTVNAME) \$(VERSION)\n}m
        or die "Makefile.PL: ExtUtils::MakeMaker wrote no distdir rule to extend\n";
    return $rules;
}

# ExtUtils::MakeMaker's default `.c.o` suffix rule does not pass `-o $@`,
# so when a source file lives in a subdirectory the compiler still emits
# the .o into CWD instead of the matching subdirectory. Every file of
# @c_sources therefore gets an explicit rule (plain make syntax, no GNU
# pattern rules), so the object files land where O_FILES expects them.
# The rule for src/clay/clay.h is built from @clay_patches (see above).
sub MY::postamble {
    my $patch = $^O eq 'MSWin32' ? 'patch --binary' : 'patch';
    my $apply_patches = join '', map { "\t$patch src/clay/clay.h.tmp < $_\n" } @clay_patches;
    my $compile_sources = join '', map {
        my $object = object_of($_);
        "$object : $_ src/clay/clay.h\n"
            . "\t\$(CCCMD) \$(CCCDLFLAGS) -I. -Isrc \"-I\$(PERL_INC)\" \$(PASTHRU_DEFINE) \$(DEFINE) -o $object $_\n\n"
    } @c_sources;
    return "\nsrc/clay/clay.h : src/clay/clay.h.orig @clay_patches\n"
        . "\t\$(RM_F) src/clay/clay.h.tmp\n"
        . "\t\$(CP) src/clay/clay.h.orig src/clay/clay.h.tmp\n"
        . $apply_patches
        . "\t\$(MV) src/clay/clay.h.tmp src/clay/clay.h\n\n"
        . $compile_sources
        . <<'POSTAMBLE';
lib/Clay/XS$(OBJ_EXT) : src/clay/clay.h

# --- Markdown pages ---------------------------------------------------
# Usage: make markdown
#
# The pages in docs/ are the pod of every module and pod file under lib/
# converted with tools/pod2markdown, a Pod::Markdown subclass that links
# the pages to each other's Markdown files, points the figures to the
# master branch on GitHub, removes the shared indentation of code
# blocks, fences them with the language set by '=for highlighter' and
# turns tables in 'text' blocks into Markdown tables. docs/ is for
# GitHub and not shipped (see MANIFEST.SKIP). Regenerate it after any
# pod change.

.PHONY: markdown

POD_MARKDOWN_CHECK = $(PERLRUN) -MPod::Markdown -e1 2>/dev/null || { \
	    echo "ERROR: Pod::Markdown is not installed; cpanm Pod::Markdown"; \
	    exit 1; \
	}

markdown :
	@$(POD_MARKDOWN_CHECK)
	$(PERLRUN) tools/pod2markdown

# --- Documentation figures -------------------------------------------
# Usage: make images         (after changing a figure or a pod reference)
#        make images-check   (fails when a figure, an image URL or a
#                             Markdown page is stale)
#
# tools/make-images lays every figure in images/ out with the Clay::UI
# in blib/, draws it with Imager, runs the examples that write a PNG or
# a PDF, and points the image URLs in the pod to the tag of the current
# version on GitHub. It fails when the pod shows a file it does not
# render, or does not show one that it renders. Then docs/ is
# regenerated.

.PHONY: images images-check

images : pure_all
	$(FULLPERLRUN) -Mblib tools/make-images
	$(MAKE) markdown

images-check : pure_all
	$(FULLPERLRUN) -Mblib tools/make-images --check
	@$(POD_MARKDOWN_CHECK)
	@$(PERLRUN) tools/pod2markdown --check || { \
	    echo "ERROR: the Markdown pages are out of date; run 'make markdown' (or 'make images')."; \
	    exit 1; \
	}

# --- Release target -------------------------------------------------
# Usage: make release
#
# Tests the dist via `make disttest`, builds the tarball via
# `make dist` (disttest alone only creates the unpacked directory),
# then uploads it to CPAN with cpan-upload (from CPAN::Uploader).
# Refuses to run if the git working tree is dirty, if a tag for the
# current $(VERSION) already exists, if a figure, an image URL or a
# Markdown page is out of date (images-check), or if the GitHub CI run
# of HEAD has not passed (ci-check, which needs gh).
# See RELEASING.md.
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

release-check : images-check ci-check
	@git diff-index --quiet HEAD -- || { \
	    echo "ERROR: git working tree is dirty; commit or stash first."; \
	    exit 1; \
	}
	@if git rev-parse -q --verify "refs/tags/v$(VERSION)" >/dev/null; then \
	    echo "ERROR: tag v$(VERSION) already exists; bump \$$VERSION in lib/Clay/UI.pm and lib/Clay/XS.pm."; \
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

POSTAMBLE
}
