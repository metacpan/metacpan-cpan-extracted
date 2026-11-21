/*
 * winlaunch - start a plugin hook on Windows.
 *
 * Claude Code starts an exec-form hook whose command has no extension
 * ("${CLAUDE_PLUGIN_ROOT}/hooks/ruler") as hooks/ruler on Linux and macOS and
 * as hooks/ruler.exe on Windows. This program is that .exe. It reads what to
 * run from the script next to it -- the file with its own name minus ".exe" --
 * so the Windows behaviour is declared where the Linux behaviour lives:
 *
 *   # winlaunch: env PYTHONPATH={root}/lib
 *   # winlaunch: run python -s -m ruler.hook
 *
 * Directives, read from the first 64 lines:
 *   run <program> <args...>   what to start; its own arguments follow these
 *   env <NAME>=<value>        set a variable for it
 *   skip <arg> unless <glob>  exit 0 at once when our first argument is <arg>
 *                             and no file matches <glob> -- the cheap early
 *                             exit a sh starter does before starting Python
 * Words are separated by single spaces; quotes are not interpreted. A
 * placeholder that expands to a path with spaces still stays one argument.
 * Placeholders: {root} is the plugin root (the directory above the one this
 * .exe sits in: hooks/ or bin/), {self} the script itself, {data}
 * $CLAUDE_PLUGIN_DATA.
 * <program> "python" picks a Python that really runs (python3.exe,
 * python.exe, py.exe -3 -- the Microsoft Store stubs in WindowsApps are
 * skipped) and sets PYTHONUTF8=1; "node" picks node.exe; anything else is
 * a path relative to the plugin root.
 *
 * No run directive, no script, no interpreter: exit 0 with no output. A hook
 * that is not meant for Windows is therefore off just by having no run line.
 * Otherwise stdin, stdout and stderr are inherited and the exit code is the
 * child's.
 *
 * Build: python -m ziglang cc -target x86_64-windows-gnu -Os -s -o x.exe winlaunch.c
 * Source of truth: windows-developer tools/winlaunch; plugins carry a copy.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define MAXCMD 32768

static wchar_t root[MAX_PATH * 2], self[MAX_PATH * 2], data[MAX_PATH * 2];

static size_t wlen(const wchar_t *s) { size_t n = 0; while (s[n]) n++; return n; }

static int wcat(wchar_t *dst, size_t cap, const wchar_t *src)
{
	size_t n = wlen(dst), m = wlen(src);
	if (n + m + 1 > cap) return 0;
	for (size_t i = 0; i <= m; i++) dst[n + i] = src[i];
	return 1;
}

static int wstarts(const wchar_t *s, const wchar_t *p)
{
	while (*p) if (*s++ != *p++) return 0;
	return 1;
}

static int contains_ci(const wchar_t *hay, const wchar_t *needle)
{
	size_t n = wlen(needle);
	for (; *hay; hay++)
		if (CompareStringOrdinal(hay, (int)n, needle, (int)n, TRUE) == CSTR_EQUAL)
			return 1;
	return 0;
}

/* Replace {root} and {self}; the result goes to out. */
static int expand(const wchar_t *in, wchar_t *out, size_t cap)
{
	out[0] = 0;
	while (*in) {
		if (wstarts(in, L"{root}")) { if (!wcat(out, cap, root)) return 0; in += 6; continue; }
		if (wstarts(in, L"{self}")) { if (!wcat(out, cap, self)) return 0; in += 6; continue; }
		if (wstarts(in, L"{data}")) { if (!wcat(out, cap, data)) return 0; in += 6; continue; }
		wchar_t c[2] = { *in++, 0 };
		if (!wcat(out, cap, c)) return 0;
	}
	return 1;
}

/* Append one argument, quoted the way CommandLineToArgvW reads it back. */
static int add_arg(wchar_t *cmd, size_t cap, const wchar_t *arg)
{
	if (cmd[0] && !wcat(cmd, cap, L" ")) return 0;
	int plain = arg[0] != 0;
	for (const wchar_t *p = arg; *p; p++)
		if (*p == L' ' || *p == L'\t' || *p == L'"') plain = 0;
	if (plain) return wcat(cmd, cap, arg);
	if (!wcat(cmd, cap, L"\"")) return 0;
	for (const wchar_t *p = arg;; p++) {
		size_t bs = 0;
		while (*p == L'\\') { bs++; p++; }
		size_t rep = !*p ? bs * 2 : *p == L'"' ? bs * 2 + 1 : bs;
		for (size_t i = 0; i < rep; i++) if (!wcat(cmd, cap, L"\\")) return 0;
		if (!*p) break;
		wchar_t c[2] = { *p, 0 };
		if (!wcat(cmd, cap, c)) return 0;
	}
	return wcat(cmd, cap, L"\"");
}

/* Search PATH for name; skip the WindowsApps directory (Store stubs). */
static int find_on_path(const wchar_t *name, wchar_t *out)
{
	static wchar_t path[MAXCMD];
	DWORD n = GetEnvironmentVariableW(L"PATH", path, MAXCMD);
	if (!n || n >= MAXCMD) return 0;
	wchar_t *dir = path;
	for (;;) {
		wchar_t *end = dir;
		while (*end && *end != L';') end++;
		wchar_t keep = *end;
		*end = 0;
		if (*dir && !contains_ci(dir, L"\\WindowsApps")) {
			out[0] = 0;
			if (wcat(out, MAX_PATH * 2, dir) && wcat(out, MAX_PATH * 2, L"\\")
			    && wcat(out, MAX_PATH * 2, name)) {
				DWORD a = GetFileAttributesW(out);
				if (a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY)) {
					*end = keep;
					return 1;
				}
			}
		}
		if (!keep) return 0;
		dir = end + 1;
	}
}

/* Read the first 64 lines of the script next to us into buf (UTF-16). */
static int read_script(wchar_t *buf, size_t cap)
{
	HANDLE h = CreateFileW(self, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
	if (h == INVALID_HANDLE_VALUE) return 0;
	static char raw[16384];
	DWORD got = 0;
	BOOL ok = ReadFile(h, raw, sizeof raw - 1, &got, NULL);
	CloseHandle(h);
	if (!ok) return 0;
	int lines = 0;
	DWORD i;
	for (i = 0; i < got && lines < 64; i++) if (raw[i] == '\n') lines++;
	int n = MultiByteToWideChar(CP_UTF8, 0, raw, (int)i, buf, (int)cap - 1);
	buf[n > 0 ? n : 0] = 0;
	return n > 0;
}

/* Our own first argument, as Claude Code passed it (one word, maybe quoted). */
static void first_arg(wchar_t *out, size_t cap)
{
	const wchar_t *p = GetCommandLineW();
	if (*p == L'"') { p++; while (*p && *p != L'"') p++; if (*p) p++; }
	else { while (*p && *p != L' ' && *p != L'\t') p++; }
	while (*p == L' ' || *p == L'\t') p++;
	size_t n = 0;
	int quoted = *p == L'"';
	if (quoted) p++;
	while (*p && n + 1 < cap && (quoted ? *p != L'"' : (*p != L' ' && *p != L'\t'))) out[n++] = *p++;
	out[n] = 0;
}

/* Does any file match the wildcard pattern? Names starting with a dot do
 * not count, as in a sh glob -- and "*" would otherwise find "." and "..". */
static int any_match(const wchar_t *pattern)
{
	WIN32_FIND_DATAW fd;
	HANDLE h = FindFirstFileW(pattern, &fd);
	if (h == INVALID_HANDLE_VALUE) return 0;
	int found = 0;
	do {
		if (fd.cFileName[0] != L'.') { found = 1; break; }
	} while (FindNextFileW(h, &fd));
	FindClose(h);
	return found;
}

int main(void)
{
	static wchar_t exe[MAX_PATH * 2], script[16384], cmd[MAXCMD], tmp[MAXCMD];
	static wchar_t program[MAX_PATH * 2];

	DWORD n = GetModuleFileNameW(NULL, exe, MAX_PATH * 2);
	if (!n || n >= MAX_PATH * 2 || n < 5) return 0;

	/* self = this file without ".exe"; root = the directory above ours. Not
	 * $CLAUDE_PLUGIN_ROOT: a command in bin/ may be run from a hook of
	 * another plugin, where that names the other plugin. */
	for (DWORD i = 0; i <= n - 4; i++) self[i] = exe[i];
	self[n - 4] = 0;
	for (DWORD i = 0; i <= n; i++) root[i] = exe[i];
	for (int up = 0; up < 2; up++) {
		wchar_t *s = root + wlen(root);
		while (s > root && *s != L'\\' && *s != L'/') s--;
		*s = 0;
	}

	if (!GetEnvironmentVariableW(L"CLAUDE_PLUGIN_DATA", data, MAX_PATH * 2)) data[0] = 0;
	if (!read_script(script, sizeof script / sizeof *script)) return 0;
	static wchar_t arg1[MAX_PATH];
	first_arg(arg1, MAX_PATH);

	/* Walk the directives. */
	const wchar_t *run = NULL;
	for (wchar_t *line = script; *line;) {
		wchar_t *end = line;
		while (*end && *end != L'\n') end++;
		wchar_t keep = *end;
		*end = 0;
		if (end > line && end[-1] == L'\r') end[-1] = 0;
		if (wstarts(line, L"# winlaunch: ")) {
			wchar_t *d = line + 13;
			if (wstarts(d, L"run ")) {
				run = d + 4;
			} else if (wstarts(d, L"skip ")) {
				/* skip <arg> unless <glob> */
				wchar_t *a = d + 5, *u = a;
				while (*u && *u != L' ') u++;
				if (*u && wstarts(u, L" unless ")) {
					*u = 0;
					if (CompareStringOrdinal(a, -1, arg1, -1, FALSE) == CSTR_EQUAL
					    && (!data[0] || !expand(u + 8, tmp, MAXCMD) || !any_match(tmp)))
						return 0;
				}
			} else if (wstarts(d, L"env ")) {
				wchar_t *eq = d + 4;
				while (*eq && *eq != L'=') eq++;
				if (*eq) {
					*eq = 0;
					if (expand(eq + 1, tmp, MAXCMD)) SetEnvironmentVariableW(d + 4, tmp);
				}
			}
		}
		if (!keep) break;
		line = end + 1;
	}
	if (!run) return 0;

	/* First word of the run line: the program. */
	const wchar_t *rest = run;
	while (*rest && *rest != L' ') rest++;
	size_t plen = (size_t)(rest - run);
	if (plen >= MAX_PATH) return 0;
	wchar_t word[MAX_PATH];
	for (size_t i = 0; i < plen; i++) word[i] = run[i];
	word[plen] = 0;
	while (*rest == L' ') rest++;

	cmd[0] = 0;
	if (wstarts(word, L"python") && plen == 6) {
		SetEnvironmentVariableW(L"PYTHONUTF8", L"1");
		if (find_on_path(L"python3.exe", program) || find_on_path(L"python.exe", program)) {
			add_arg(cmd, MAXCMD, program);
		} else if (find_on_path(L"py.exe", program)) {
			add_arg(cmd, MAXCMD, program);
			add_arg(cmd, MAXCMD, L"-3");
		} else {
			return 0;
		}
	} else if (wstarts(word, L"node") && plen == 4) {
		if (!find_on_path(L"node.exe", program)) return 0;
		add_arg(cmd, MAXCMD, program);
	} else {
		program[0] = 0;
		if (!wcat(program, MAX_PATH * 2, root) || !wcat(program, MAX_PATH * 2, L"\\")
		    || !wcat(program, MAX_PATH * 2, word)) return 0;
		add_arg(cmd, MAXCMD, program);
	}

	/* The rest of the run line, word by word, then our own arguments verbatim. */
	while (*rest) {
		const wchar_t *e = rest;
		while (*e && *e != L' ') e++;
		size_t len = (size_t)(e - rest);
		if (len >= MAXCMD) return 0;
		for (size_t i = 0; i < len; i++) tmp[i] = rest[i];
		tmp[len] = 0;
		static wchar_t arg[MAXCMD];
		if (!expand(tmp, arg, MAXCMD) || !add_arg(cmd, MAXCMD, arg)) return 0;
		rest = e;
		while (*rest == L' ') rest++;
	}
	const wchar_t *own = GetCommandLineW();
	if (*own == L'"') { own++; while (*own && *own != L'"') own++; if (*own) own++; }
	else { while (*own && *own != L' ' && *own != L'\t') own++; }
	while (*own == L' ' || *own == L'\t') own++;
	if (*own && (!wcat(cmd, MAXCMD, L" ") || !wcat(cmd, MAXCMD, own))) return 0;

	STARTUPINFOW si;
	PROCESS_INFORMATION pi;
	ZeroMemory(&si, sizeof si);
	si.cb = sizeof si;
	si.dwFlags = STARTF_USESTDHANDLES;
	si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
	si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
	si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
	if (!CreateProcessW(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) return 0;
	CloseHandle(pi.hThread);
	WaitForSingleObject(pi.hProcess, INFINITE);
	DWORD code = 0;
	GetExitCodeProcess(pi.hProcess, &code);
	CloseHandle(pi.hProcess);
	return (int)code;
}
