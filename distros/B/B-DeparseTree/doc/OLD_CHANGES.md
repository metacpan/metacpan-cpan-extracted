# Ancient history

In the good old days before revision control systems were in place (and even after they were),
people noted a list of high-level changes inside the code, instead of, or in addition to
version-control commit messages. I have removed them from the code.


## Changes between 0.50 and 0.51:

* fixed nulled leave with live enter in `sort { }`
* fixed reference constants (`\"str"`)
* handle empty programs gracefully
* handle infinite loops, e.g. `for (;;) {}, while (1) {}`
* differentiate between 'for `my $x ...' and 'my $x; for $x ...'`
* various minor cleanups
* moved globals into an object
* added `-u` options, like `B::C`
* package declarations using `cop_stash()`
* `sub`'s, `format`'s and code sorted by `cop_seq()`

# Changes between 0.51 and 0.52:

* added `pp_threadsv` (special variables under `USE_5005THREADS`)
* added documentation

# Changes between 0.52 and 0.53:

* many changes adding precedence contexts and associativity
* added `-p` and `-s` output style options
* various other minor fixes

# Changes between 0.53 and 0.54:

* added support for new `for (1..100)` optimization,

thanks to Gisle Aas

# Changes between 0.54 and 0.55:

* added support for new `qr//` construct
* added support for new `pp_regcreset` OP

# Changes between 0.55 and 0.56:

* tested on `base/*.t`, `cmd/*.t`, `comp/*.t`, `io/*.t`
* fixed `$#` on non-lexicals broken in last big rewrite
* added temporary fix for change in opcode of OP_STRINGIFY
* fixed problem in 0.54's `for()` patch in `for (@ary)`
* fixed precedence in conditional of `?:`
* tweaked list paren elimination in `my($x) = @_`
* made continue-block detection trickier wrt. null ops
* fixed various prototype problems in pp_entersub
* added support for sub prototypes that never get GVs
* added unquoting for special filehandle first arg in truncate
* print doubled `rv2gv` (a bug) as '*{*GV}' instead of illegal `**GV`
* added semicolons at the ends of blocks
* added -l '#line' declaration option -- fixes cmd/subval.t 27,28

# Changes between 0.56 and 0.561:

* fixed multiply-declared my var in `pp_truncate` (thanks to Sarathy)
* used new `B.pm` symbolic constants (done by Nick Ing-Simmons)

# Changes between 0.561 and 0.57:

* stylistic changes to symbolic constant stuff
* handled scope in `s///e` replacement code
* added unquote option for expanding `""` into concats, etc.
* split method and proto parts of `pp_entersub` into separate functions
* various minor cleanups

# Changes after 0.57:

* added parens in `\&foo` (patch by Albert Dvornik)

# Changes between 0.57 and 0.58:

* fixed '0' statements that weren't being printed
* added methods for use from other programs (based on patches from James Duncan and Hugo van der Sanden)

* added `-si` and `-sT` to control indenting (also based on a patch from Hugo)
* added `-sv` to print something else instead of `???`
* preliminary version of utf8 `tr///` handling

# Changes after 0.58:

* uses of `$op->ppaddr` changed to new `$op->name` (done by Sarathy)
* added support for Hugo's new `OP_SETSTATE` (like nextstate)

# Changes between 0.58 and 0.59

* added support for Chip's `OP_METHOD_NAMED`
* added support for Ilya's `OPpTARGET_MY` optimization
* elided arrows before `()` subscripts when possible

# Changes between 0.59 and 0.60

* support for method attributes was added
* some warnings fixed
* separate recognition of constant subs
* rewrote continue block handling, now recognizing for loops
* added more control of expanding control structures

# Changes between 0.60 and 0.61 (mostly by Robin Houston)

* many bug-fixes
* support for pragmas and 'use'
* support for the little-used $[ variable
* support for `__DATA__` sections
* UTF-8 support
* `BEGIN`, `CHECK`, `INIT` and `END` blocks
* scoping of subroutine declarations fixed
* compile-time output from the input program can be suppressed, so that the  output is just the deparsed code. (a change to O.pm in fact)
* `our()` declarations
* *all* the known bugs are now listed in the BUGS section
* comprehensive test mechanism (TEST -deparse)

# Changes between 0.62 and 0.63 (mostly by Rafael Garcia-Suarez)

* bug-fixes
* new switch `-P`
* support for command-line switches (`-l`, `-0`, etc.)

# Changes between 0.63 and 0.64

* support for `//`, `CHECK` blocks, and assertions
* improved handling of `foreach` loops and lexicals
* option to use `Data::Dumper` for constants
* more bug fixes
* discovered lots more bugs not yet fixed

...

# Changes between 0.72 and 0.73
* support new `switch` constructs
