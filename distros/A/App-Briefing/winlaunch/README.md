# winlaunch

Claude Code on Windows starts an exec-form hook whose command has no
extension (`${CLAUDE_PLUGIN_ROOT}/hooks/x` with `args`) as `hooks/x.exe`;
Linux and macOS start `hooks/x` itself. `winlaunch.exe` is that `.exe`: it
reads `# winlaunch:` lines from the script next to it and starts what they
name, or exits 0 silently when there are none. The header of `winlaunch.c`
has the details.

- `build.py OUT.exe` builds it reproducibly with zig 0.13 (`pip install
  ziglang==0.13.0.post1`); the same source gives the same bytes on Windows
  and Linux.
- `test_winlaunch.py PATH\TO\winlaunch.exe` tests it on Windows.
- `.cicd/python+3.12+test.winlaunch.sh` rebuilds it in CI and checks every
  committed `hooks/*.exe` and `bin/*.exe` against that build.

The source of truth is `tools/winlaunch` in the windows-developer hub; plugins
carry a copy. After changing `winlaunch.c`, rebuild and copy the result over
every `.exe` of the plugin.
