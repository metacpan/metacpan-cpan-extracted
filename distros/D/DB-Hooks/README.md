# Perl Debugger

> [!IMPORTANT]
> Free evaluation is permitted. Production and commercial use require a paid
> license. Redistribution is not permitted.
>
> [**Buy Perl Debugger — CA$170, one-time payment →**](https://buy.stripe.com/8x2aEW3Z97pp7aV15o7Zu01)

## Support Perl Debugger

**I hope Perl Debugger makes your work easier and saves you time tracking down bugs.**

If you support this product, you also support the Perl community. **Ten percent of Perl Debugger revenue will be donated to [The Perl & Raku Foundation](https://perlfoundation.org/donate.html).**

The source is available for free evaluation, investigation, learning,
teaching, and educational use. Regular, ongoing, production, or commercial
use requires a paid license. See [LICENSE](LICENSE) for the complete terms.

## How to run

DB::Hooks runs through Perl's normal debugger interface. It stops at a
`DBG>` prompt, where you can step through code, inspect variables, and view
the call stack without adding `print` statements to the program.

### Requirements

- Perl 5.12 or later
- [`cpanm`](https://metacpan.org/pod/App::cpanminus) to install the module

### Try the debugger

Install the module into a local directory without changing your system Perl:

```sh
cpanm -L local DB::Hooks
```

Start a small debugging session with the local installation:

```sh
PERL5DB="use DB::Hooks qw'::Terminal'" \
PERL5LIB=local/lib/perl5 \
PERLDB_OPTS="white_box" \
perl -d -e 0
```

`PERL5DB` loads the debugger and its terminal interface. `PERLDB_OPTS` passes
debugger options, and `PERL5LIB` lets Perl find the local installation.

`-e 0` tells Perl to run the expression `0`. The debugger stops before it:

```text
-e
    0: use DB::Hooks qw'::Terminal';
  >>1: 0


DBG> n
```

At `DBG>`, begin with `n` to execute the current statement and stop at the
next one. Use `s` to step into a subroutine call, `r` to return from the
current subroutine, `T` to view the call stack, and `q` to quit.

To debug your own program, run the same command with your script in place of
`-e 0`:

```sh
PERL5DB="use DB::Hooks qw'::Terminal'" \
PERL5LIB=local/lib/perl5 \
PERLDB_OPTS="white_box" \
perl -d script.pl
```

### Debug a Mojolicious application

Start the application's `morbo` process under the debugger:

```sh
cd <your-mojolicious-app>
PERLDB_OPTS="white_box" \
PERL5DB="use DB::Hooks qw'::Terminal ::TraceVariable NonStop'" \
perl -d "$(which morbo)" script/mojo_app
```

The `::TraceVariable` extension enables variable-access tracing. `NonStop`
skips the initial debugger stop so the server can start normally. Add `DB::x;`
where you want execution to stop, or set a breakpoint after connecting a
debugger client.

### Establish remote debugging session

Use two terminals when the program being debugged cannot share the same
terminal as the debugger client.

In the first terminal, start the program and the remote debugger listener.
`DB::x` creates a debugger stop:

```sh
PERL5LIB=local/lib/perl5 \
PERL5DB="use DB::Hooks qw'::Terminal ::Remote ::TraceVariable NonStop'" \
perl -d -e 'DB::x; 1'
```

In the second terminal, connect the debugger client to the default local
listener:

```sh
dclient.pl 127.0.0.1 9001
```

If `dclient.pl` is not on your `PATH`, run the copy installed under
`local/bin/` instead. Set `DBG_PORT` in the first terminal to use a port other
than `9001`.

## Quick guide to commands

	s - step into the next statement
	n - step over the next statement
	r - return from a subroutine
	go - run the script until the end or the next trap
	go N - run the script to line N
	q - quit debugger
	R - restart debugging. Works only while remotely debugging a script run under uWSGI

	f - list all files
	f regex - list all files that match the regex
	f N - set file N as current

	l . - list source at the current step
	l - list next source page
	l $coderef - deparse the subroutine
	l -N - list source for frame N
	l &N - deparse the subroutine for frame N

	vars - show variables visible from the current step
	vars N - show variables visible from frame N
	vars N $var - show the value of $var at frame N

	t [$x|@x|%x] - trace access to the given variable and log it to 'vars.log'

	T - show stack trace
	T N - show only the last N frames
	NOTICE: stack trace also shows GOTO frames

	b - list all traps
	b . - set trap at current step
	b . condition - set a conditional trap
	b [+|-][file:|M:]N - set trap at the given file:line
		+ - enable trap
		- - disable trap
		file - absolute path to the file
		M - number from the 'f' command output
		N - line number in the file
	save|load - save/load trap information in the ~/.dbginit file

	a expr - set action
	A expr - remove action
	w expr - set watch
	W expr - remove watch

	expr - evaluate 'expr' from the user's script perspective
	e expr - evaluate 'expr' from the user's script perspective and show Data::Dump::pp results

	ge - run the editor for the current file
	ge file:N - run the editor for the given file

## More materials

- [Short presentation of the new Perl debugger](https://blogs.perl.org/users/eugen_konkov/2016/09/short-presentation-of-the-new-perl-debugger.html)
- [Perl Debugger presentation (YouTube)](https://www.youtube.com/watch?v=UlPTDyRL7fg)
- [Debugging with Perl presentation (YouTube)](https://www.youtube.com/watch?v=AyyFQJjk7Lw)
