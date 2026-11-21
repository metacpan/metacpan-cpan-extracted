# Shared by scripts/binary-smoke.sh and scripts/binary-verify.sh (sourced, not run): the
# wiped environment a packed briefing runs under, and the project fixtures both build.
# Needs $work (a temporary directory) and $BIN (the binary) set by the caller.

fail() { echo "FAIL: $*" >&2; exit 1; }

windows=
case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) windows=1 ;; esac

mkdir -p "$work/empty" "$work/tmp/par"
home=$work/home
# The binary under a wiped environment: every home, harness and temporary path is inside the
# work dir; env -i drops PERL5LIB and every other ambient value. PAR extracts only below it.
# $runtime_path is the PATH it sees (the caller sets it).
if [ -n "$windows" ]; then
  export LC_ALL=C.UTF-8 # the shell must write UTF-8 file names
  w_home=$(cygpath -w "$home")
  w_tmp=$(cygpath -w "$work/tmp")
  envs=(PATH="$runtime_path" SYSTEMROOT="${SYSTEMROOT:-C:\\Windows}" USERPROFILE="$w_home" HOME="$w_home"
        CODEX_HOME="$w_home\\.codex" TEMP="$w_tmp" TMP="$w_tmp" TMPDIR="$w_tmp"
        PAR_GLOBAL_TEMP="$w_tmp\\par")
  # A path as the binary takes it: Windows' own, forward slashes (JSON needs no escape).
  native() { cygpath -m "$1"; }
else
  envs=(PATH="$runtime_path" HOME="$home" CODEX_HOME="$home/.codex"
        TMPDIR="$work/tmp" TMP="$work/tmp" TEMP="$work/tmp" PAR_GLOBAL_TEMP="$work/tmp/par" LC_ALL=C)
  native() { printf '%s\n' "$1"; }
fi
mkdir -p "$home/.claude" "$home/.codex"
bin() { env -i "${envs[@]}" "$BIN" "$@" </dev/null; }

# fixture DIRNAME SKILL: a project under $work/DIRNAME with an agent that declares SKILL (ok),
# settings, and the user skill under the home.
fixture() {
  local dir=$work/$1 skill=$2
  mkdir -p "$dir/.claude/agents" "$home/.claude/skills/$skill"
  printf 'SMOKE-MARKER-%s\n' "$skill" >"$home/.claude/skills/$skill/SKILL.md"
  printf -- '---\nname: demo\ndescription: d\nbriefing:\n  skills:\n    - %s\n---\nbody\n' "$skill" \
    >"$dir/.claude/agents/demo.md"
  printf '{"enabledPlugins":{"briefing@getty":true},"extraKnownMarketplaces":{"getty":{"source":{"source":"github","repo":"Getty/marketplace"}}}}\n' \
    >"$dir/.claude/settings.json"
  [ -f "$dir/.claude/agents/demo.md" ] || fail "cannot create the fixture below '$1'"
}
# An agent that declares an unknown skill.
broken_agent() {
  printf -- '---\nname: broken\ndescription: d\nbriefing:\n  skills:\n    - no-such-skill\n---\nbody\n' \
    >"$work/$1/.claude/agents/broken.md"
}
