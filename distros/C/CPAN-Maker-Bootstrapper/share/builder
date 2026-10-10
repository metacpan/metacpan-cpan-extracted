#!/usr/bin/env bash
# -*- mode: bash; -*-
########################################################################
#  CI script suitable for GitHub actions and other runners
########################################################################
#
# Run from the root of a checked-out project:
#
#   ./builder
#
# Or pass the project directory explicitly:
#
#   /builder /path/to/project
#
# To run in the standard clean-room container:
#
#   make build-ci
#
########################################################################

INSTALLER="${INSTALLER:-cpm install -g --no-prebuilt --show-build-log-on-failure --verbose}"

########################################################################
function install_build_deps {
########################################################################
    
    EXTRA_DEPS=(CPAN::Maker::Bootstrapper)

    if [[ "${LINT:-off}" =~ ^([Oo][Nn])$ ]]; then
        if [[ -n "${PERLCRITICRC:-}" ]]; then
            EXTRA_DEPS+=(
                Perl::Critic
                Perl::Critic::Community
                Perl::Critic::Policy::Compatibility
            )
        fi

        if [[ -n "${PERLTIDYRC:-}" ]]; then
            EXTRA_DEPS+=(Perl::Tidy)
        fi
    fi

    $INSTALLER "${EXTRA_DEPS[@]}"

    # create a cpanfile for build requirements - installed into Perl's global include path
    all_requires=$(mktemp)
    trap 'rm -f "$all_requires"' EXIT

    for a in "${EXTRA_DEPS[@]}"; do 
        echo $a >> $all_requires;
    done

    if ! [[ -e build-requires ]]; then
        echo >&2 "WARNING: add a 'build-requires' file with at least CPAN::Maker::Bootstrapper"
        echo "CPAN::Maker::Bootstrapper" > build-requires
    else
        if ! grep -q "^CPAN::Maker::Bootstrapper" build-requires 2>/dev/null; then
            echo >&2 "WARNING: adding 'CPAN::Maker::Bootstrapper' to your 'build-requires' file"
            echo "CPAN::Maker::Bootstrapper" >>build-requires
        fi
    fi

    cat build-requires >> $all_requires

    perl -ne 'chomp;($m,$v)=split /(?:[@]|\s+)/,$_,2; $v //= q{}; $m=~s/^\+//; $v = $v eq q{0} ? q{} : $v; print qq{requires "$m", "$v";\n};' \
         $all_requires | sort -u  >cpanfile.build

    if [[ "$INSTALLER" =~ cpanm ]]; then
        cpanm --installdeps --cpanfile cpanfile.build .
    else
        $INSTALLER --cpanfile cpanfile.build
    fi
}

########################################################################
# main script starts here
########################################################################

set -euo pipefail
set -x

PROJECT_DIR="${1:-$(pwd)}"

if ! [[ -d "$PROJECT_DIR" ]]; then
    echo >&2 "ERROR: project directory does not exist ($PROJECT_DIR)"
    exit 1
fi

cd "$PROJECT_DIR"

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

set -a
test ! -e ./builder.env || . ./builder.env

if [[ ! -v PERLTIDYRC ]]; then
    PERLTIDYRC=$(find . \( -name '.perltidyrc' -o -name 'perltidyrc' \) -print -quit)
fi

if [[ ! -v PERLCRITICRC ]]; then
    PERLCRITICRC=$(find . \( -name '.perlcriticrc' -o -name 'perlcriticrc' \) -print -quit)
fi

if [[ -n "${PERLTIDYRC:-}" && ! -f "$PERLTIDYRC" ]]; then
    echo >&2 "ERROR: PERLTIDYRC does not exist: $PERLTIDYRC"
    exit 1
fi

if [[ -n "${PERLCRITICRC:-}" && ! -f "$PERLCRITICRC" ]]; then
    echo >&2 "ERROR: PERLCRITICRC does not exist: $PERLCRITICRC"
    exit 1
fi

if [[ "${LINT:-off}" =~ ^([Oo][Nn])$ ]] &&
       [[ -z "${PERLTIDYRC:-}" ]] &&
       [[ -z "${PERLCRITICRC:-}" ]]; then
    echo >&2 "ERROR: LINT=on but no perltidyrc or perlcriticrc was found"
    exit 1
fi

PERL5LIB="$(pwd)/local/lib/perl5"

set +a

set +x

{
echo "+-------------------------------------------------"
echo "|      BUILD_DATE: $(date +'%Y-%m-%d %H:%M:%S')"
echo "|     PROJECT_DIR: $(pwd)"
echo "|            SCAN: ${SCAN:-on}"
echo "| SYNTAX_CHECKING: ${SYNTAX_CHECKING:-off}"
echo "|            LINT: ${LINT:-off}"

if [[ -n "${PERLTIDYRC:-}" ]]; then
    echo "|        PERLTIDY: $PERLTIDYRC"
fi

if [[ -n "${PERLCRITICRC:-}" ]]; then
    echo "|      PERLCRITIC: $PERLCRITICRC"
fi

if [[ "$INSTALLER" =~ cpanm ]]; then
    echo "|         MIRRORS: ${MIRRORS[*]}"
    echo "|  PERL_CPANM_OPT: ${PERL_CPANM_OPT:-}"
else
    echo "|       RESOLVERS: ${RESOLVERS[*]}"
fi

echo "+-------------------------------------------------"
} >&2

set -x

install_build_deps

make clean
make builder-pre
time make
make builder-post
