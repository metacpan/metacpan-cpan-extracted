#!/usr/bin/env bash
# -*- mode: sh; -*-
########################################################################
#  CI script suitable for GitHub actions and other runners
########################################################################
#
# To run locally:

# Assuming your project directory name is the same as your repo name
# repo_name=$(basename -s .git "$(git remote get-url origin)")
# docker run --rm -it \
#   -v "$(pwd)/builder:/builder" \
#   -v "$(pwd):/$(basename $(pwd)) \
#   -e GITHUB_REF_NAME=master \
#   -e REPO=$(basename  -s .git "$(git remote get-url origin)")
#   -e INSTALLER=cpm \
#   debian:trixie \
#   /bin/bash
#
# --or--
#
#  make build-ci
#
########################################################################

INSTALLER="${INSTALLER:-cpm install -g --no-prebuilt --show-build-log-on-failure --verbose}"

########################################################################
function install_deps {
########################################################################
    
    EXTRA_DEPS=(CPAN::Maker CPAN::Maker::Bootstrapper)
    EXTRA_DEPS+=(File::ShareDir File::ShareDir::Install)
    EXTRA_DEPS+=(Pod::Markdown Markdown::Render)

    if [[ -n "$PERLCRITICRC" ]]; then
        EXTRA_DEPS+=(Perl::Critic Perl::Critic::Policy::Compatibility::PodMinimumVersion)
        EXTRA_DEPS+=(Perl::Critic::Policy::Community::PreferredAlternatives)
    fi

    if [[ -n "$PERLTIDYRC" ]]; then
        EXTRA_DEPS+=(Perl::Tidy)
    fi

    $INSTALLER "${EXTRA_DEPS[@]}"

# Regenerate cpanfile for CI - includes build-requires and test-requires
# in addition to runtime requires. The committed cpanfile only contains
# runtime dependencies for consumer installs.

    all_requires=$(mktemp)

    trap 'rm -f "$all_requires"' EXIT

    test -e requires && cat requires >> $all_requires
    test -e build-requires && cat build-requires >> $all_requires
    test -e test-requires && cat test-requires >> $all_requires

    perl -ne 'chomp;($m,$v)=split /(?:[@]|\s+)/,$_,2; $v //= q{}; $m=~s/^\+//; $v = $v eq q{0} ? q{} : $v; print qq{requires "$m", "$v";\n};' \
         $all_requires | sort -u  >cpanfile

    if [[ "$INSTALLER" =~ cpanm ]]; then
        cpanm --installdeps .
    else
        $INSTALLER
    fi
}

########################################################################
# main script starts here
########################################################################

REPO="$1"

set -euo pipefail
set -x

########################################################################
# Install the minimum set of dependencies required to do a build
# Add any additional dependences to: build-apt-deps
########################################################################
apt-get update && apt-get install -y \
   git \
   gcc \
   make \
   perl \
   curl \
   ca-certificates \
   libexpat-dev \
   libssl-dev \
   libzip-dev

if [[ "$INSTALLER" =~ cpm ]]; then
    curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm | perl - install -g App::cpm
    if [[ "$INSTALLER" = "cpm" ]]; then
        INSTALLER="$INSTALLER install -g"
    fi
elif [[ $INSTALLER =~ cpanm ]]; then
    curl -L https://cpanmin.us | perl - App::cpanminus
else
    echo >&2 "ERROR: unknown installer ($INSTALLER)"
    exit 1;
fi

if [[ -n "$REPO" ]]; then
    dir=$(basename $REPO .git)
    if ! [[ -d "$dir" ]]; then
        git clone $REPO
    fi
    cd $dir
fi

BRANCH_NAME="${BUILD_BRANCH:-${GITHUB_REF_NAME:-}}"
if [[ -n "${BRANCH_NAME}" ]]; then
    if [[ -d ".git" ]]; then
        echo "checking out $BRANCH_NAME"
        git checkout "$BRANCH_NAME"
    fi
else
   BRANCH_NAME=$(git branch --show-current)
   echo "BRANCH: $BRANCH_NAME"
fi

if [[ -e build-apt-deps ]]; then
    apt-get update && apt-get install -y $(cat build-apt-deps)
fi

########################################################################
# Add your mirror to build-mirrors to use a DarkPAN mirror
########################################################################
if [[ "$INSTALLER" =~ cpanm ]]; then
    MIRRORS=("--mirror https://cpan.metacpan.org")

    if [[ -e build-mirrors ]]; then
        for a in $(cat build-mirrors); do
            MIRRORS+=("--mirror $a")
        done
    fi

    export PERL_CPANM_OPT="-n -v --cascade-search ${MIRRORS[@]} --mirror-only"
else 
    RESOLVERS=()
    if [[ -e build-mirrors ]]; then
        for a in $(cat build-mirrors); do
            RESOLVERS+="--resolver 02packages,$a"
        done
    fi

    INSTALLER="$INSTALLER ${RESOLVERS[@]}"
fi

########################################################################
# Note that we deliberately do the robust build:
# LINT=on, SCAN=on, PERLCRITIC=on, PERLTIDY=on
#-----------------------------------------------------------------------
# If your build does not work with these on, try turning them
# off by uncommenting the lines below.
#-----------------------------------------------------------------------
# SYNTAX_CHECKING=off
# SCAN=off
# LINT=off
########################################################################

export PERLTIDYRC=$(find . -name '.perltidyrc' -o -name 'perltidyrc')
export PERLCRITICRC=$(find . -name '.perlcriticrc' -o -name 'perlcriticrc')
set +x
                           echo "+-------------------------------------------------"
                           echo "|      BUILD_DATE: $(date +'%Y-%m-%d %H:%M:%S')"
                           echo "|          BRANCH: $BRANCH_NAME"
                           echo "|            SCAN: ${SCAN:-on}"
                           echo "| SYNTAX_CHECKING: ${SYNTAX_CHECKING:-on}"
test -n "$PERLTIDYRC" &&   echo "|        PERLTIDY: ${PERLTIDYRC:-disabled}"
test -n "$PERLCRITICRC" && echo "|      PERLCRITIC: ${PERLCRITICRC:-disabled}"

if [[ "$INSTALLER" =~ cpanm ]]; then
                           echo "|         MIRRORS: ${MIRRORS[@]}"
                           echo "|  PERL_CPANM_OPT: ${PERL_CPANM_OPT:-}"
else
                           echo "|       RESOLVERS: ${RESOLVERS[@]}"
fi
                           echo "+-------------------------------------------------"
set -x

install_deps

########################################################################
# Uncomment these to increase verbosity level of the build
########################################################################
# make-cpan-dist debug mode
#-----------------------------------------------------------------------
# DEBUG=1
########################################################################

########################################################################
# make-cpan-dist.pl log level
#-----------------------------------------------------------------------
# LOG_LEVEL=trace
########################################################################

########################################################################
# Full output of make steps
#-----------------------------------------------------------------------
# export NO_ECHO=""
########################################################################

time make CMB_VERSION_DRIFT=ignore NO_ECHO=
