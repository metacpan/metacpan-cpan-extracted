# NAME

Config::AutoConf - A module to implement some of AutoConf macros in pure perl.

# ABSTRACT

With this module I pretend to simulate some of the tasks AutoConf
macros do. To detect a command, to detect a library, etc.

# SYNOPSIS

    use Config::AutoConf;

    Config::AutoConf->check_prog("agrep");
    my $grep = Config::AutoConf->check_progs("agrep", "egrep", "grep");

    Config::AutoConf->check_header("ncurses.h");
    my $curses = Config::AutoConf->check_headers("ncurses.h","curses.h");

    Config::AutoConf->check_prog_awk;
    Config::AutoConf->check_prog_egrep;

    Config::AutoConf->check_cc();

    Config::AutoConf->check_lib("ncurses", "tgoto");

    Config::AutoConf->check_file("/etc/passwd"); # -f && -r

# DESCRIPTION

Config::AutoConf is intended to provide the same opportunities to Perl
developers as [GNU Autoconf](http://www.gnu.org/software/autoconf/)
does for Shell developers.

As Perl is the second most deployed language (mind: every Unix comes
with Perl, several mini-computers have Perl and even lot's of Windows
machines run Perl software - which requires deployed Perl there, too),
this gives wider support than Shell based probes.

The API is leaned against GNU Autoconf, but we try to make the API
(especially optional arguments) more Perl'ish than m4 abilities allow
to the original.

# CONSTRUCTOR

## new

This function instantiates a new instance of Config::AutoConf, eg. to
configure child components. The constructor adds also values set via
environment variable `PERL5_AUTOCONF_OPTS`.

# METHODS

## check\_file

This function checks if a file exists in the system and is readable by
the user. Returns a boolean. You can use '-f $file && -r $file' so you
don't need to use a function call.

## check\_files

This function checks if a set of files exist in the system and are
readable by the user. Returns a boolean.

## check\_prog( $prog, \\@dirlist?, \\%options? )

This function checks for a program with the supplied name. In success
returns the full path for the executable;

An optional array reference containing a list of directories to be searched
instead of $PATH is gracefully honored.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.

## check\_progs(progs, \[dirlist\])

This function takes a list of program names. Returns the full path for
the first found on the system. Returns undef if none was found.

An optional array reference containing a list of directories to be searched
instead of $PATH is gracefully honored.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively. The
name of the _$prog_ to check and the found full path are passed as first
and second argument to the _action\_on\_true_ callback.

## check\_prog\_yacc

From the autoconf documentation,

    If `bison' is found, set [...] `bison -y'.
    Otherwise, if `byacc' is found, set [...] `byacc'. 
    Otherwise set [...] `yacc'.  The result of this test can be influenced
    by setting the variable YACC or the cache variable ac_cv_prog_YACC.

Returns the full path, if found.

## check\_prog\_awk

From the autoconf documentation,

    Check for `gawk', `mawk', `nawk', and `awk', in that order, and
    set output [...] to the first one that is found.  It tries
    `gawk' first because that is reported to be the best implementation.
    The result can be overridden by setting the variable AWK or the
    cache variable ac_cv_prog_AWK.

Note that it returns the full path, if found.

## check\_prog\_egrep

From the autoconf documentation,

    Check for `grep -E' and `egrep', in that order, and [...] output
    [...] the first one that is found.  The result can be overridden by
    setting the EGREP variable and is cached in the ac_cv_path_EGREP
    variable. 

Note that it returns the full path, if found.

## check\_prog\_lex

From the autoconf documentation,

    If flex is found, set output [...] to ‘flex’ and [...] to -lfl, if that
    library is in a standard place. Otherwise set output [...] to ‘lex’ and
    [...] to -ll, if found. If [...] packages [...] ship the generated
    file.yy.c alongside the source file.l, this [...] allows users without a
    lexer generator to still build the package even if the timestamp for
    file.l is inadvertently changed.

Note that it returns the full path, if found.

The structure $self->{lex} is set with attributes

    prog => $LEX
    lib => $LEXLIB
    root => $lex_root

## check\_prog\_sed

From the autoconf documentation,

    Set output variable [...] to a Sed implementation that conforms to Posix
    and does not have arbitrary length limits. Report an error if no
    acceptable Sed is found. See Limitations of Usual Tools, for more
    information about portability problems with Sed.

    The result of this test can be overridden by setting the SED variable and
    is cached in the ac_cv_path_SED variable. 

Note that it returns the full path, if found.

## check\_prog\_pkg\_config

Checks for `pkg-config` program. No additional tests are made for it ...

## check\_prog\_cc

Determine a C compiler to use. Currently the probe is delegated to [ExtUtils::CBuilder](https://metacpan.org/pod/ExtUtils::CBuilder).

## check\_cc

(Deprecated) Old name of ["check\_prog\_cc"](#check_prog_cc).

## check\_valid\_compiler

This function checks for a valid compiler for the currently active language.
At the very moment only `C` is understood (corresponding to your compiler
default options, e.g. -std=gnu89).

## check\_valid\_compilers(;\\@)

Checks for valid compilers for each given language. When unspecified
defaults to `[ "C" ]`.

## msg\_checking

Prints "Checking @\_ ..."

## msg\_result

Prints result \\n

## msg\_notice

Prints "configure: " @\_ to stdout

## msg\_warn

Prints "configure: " @\_ to stderr

## msg\_error

Prints "configure: " @\_ to stderr and exits with exit code 0 (tells
toolchain to stop here and report unsupported environment)

## msg\_failure

Prints "configure: " @\_ to stderr and exits with exit code 0 (tells
toolchain to stop here and report unsupported environment). Additional
details are provides in config.log (probably more information in a
later stage).

## define\_var( $name, $value \[, $comment \] )

Defines a check variable for later use in further checks or code to compile.
Returns the value assigned value

## write\_config\_h( \[$target\] )

Writes the defined constants into given target:

    Config::AutoConf->write_config_h( "config.h" );

## push\_lang(lang \[, implementor \])

Puts the current used language on the stack and uses specified language
for subsequent operations until ending pop\_lang call.

## pop\_lang(\[ lang \])

Pops the currently used language from the stack and restores previously used
language. If _lang_ specified, it's asserted that the current used language
equals to specified language (helps finding control flow bugs).

## lang\_call( \[prologue\], function )

Builds program which simply calls given function.
When given, prologue is prepended otherwise, the default
includes are used.

## lang\_build\_program( prologue, body )

Builds program for current chosen language. If no prologue is given
(_undef_), the default headers are used. If body is missing, default
body is used.

Typical call of

    Config::AutoConf->lang_build_program( "const char hw[] = \"Hello, World\\n\";",
                                          "fputs (hw, stdout);" )

will create

    const char hw[] = "Hello, World\n";

    /* Override any gcc2 internal prototype to avoid an error.  */
    #ifdef __cplusplus
    extern "C" {
    #endif

    int
    main (int argc, char **argv)
    {
      (void)argc;
      (void)argv;
      fputs (hw, stdout);;
      return 0;
    }

    #ifdef __cplusplus
    }
    #endif

## lang\_build\_bool\_test (prologue, test, \[@decls\])

Builds a static test which will fail to compile when test
evaluates to false. If `@decls` is given, it's prepended
before the test code at the variable definition place.

## push\_includes

Adds given list of directories to preprocessor/compiler
invocation. This is not proved to allow adding directories
which might be created during the build.

## push\_preprocess\_flags

Adds given flags to the parameter list for preprocessor invocation.

## push\_compiler\_flags

Adds given flags to the parameter list for compiler invocation.

## push\_libraries

Adds given list of libraries to the parameter list for linker invocation.

## push\_library\_paths

Adds given list of library paths to the parameter list for linker invocation.

## push\_link\_flags

Adds given flags to the parameter list for linker invocation.

## compile\_if\_else( $src, \\%options? )

This function tries to compile specified code and returns a boolean value
containing check success state.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.

## link\_if\_else( $src, \\%options? )

This function tries to compile and link specified code and returns a boolean
value containing check success state.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.

## check\_cached( $cache-key, $check-title, \\&check-call, \\%options? )

Retrieves the result of a previous ["check\_cached"](#check_cached) invocation from
`cache-key`, or (when called for the first time) populates the cache
by invoking `\&check_call`. 

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed on **every** call
to check\_cached (not just the first cache-populating invocation), respectively.

## cache\_val

This function returns the value of a previously check\_cached call.

## check\_decl( $symbol, \\%options? )

This method actually tests whether symbol is defined as a macro or can be
used as an r-value, not whether it is really declared, because it is much
safer to avoid introducing extra declarations when they are not needed.
In order to facilitate use of C++ and overloaded function declarations, it
is possible to specify function argument types in parentheses for types
which can be zero-initialized:

    Config::AutoConf->check_decl("basename(char *)")

This method caches its result in the `ac_cv_decl_<set lang>`\_symbol
variable.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.

## check\_decls( symbols, \\%options? )

For each of the symbols (with optional function argument types for C++
overloads), run [check\_decl](https://metacpan.org/pod/check_decl).

Contrary to GNU autoconf, this method does not declare HAVE\_DECL\_symbol
macros for the resulting `confdefs.h`, because it differs as `check_decl`
between compiling languages.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.
Given callbacks for _action\_on\_symbol\_true_ or _action\_on\_symbol\_false_ are
called for each symbol checked using ["check\_decl"](#check_decl) receiving the symbol as
first argument.

## check\_func( $function, \\%options? )

This method actually tests whether _$funcion_ can be linked into a program
trying to call _$function_.  This method caches its result in the
ac\_cv\_func\_FUNCTION variable.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
If any of _action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined,
both callbacks are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or
_action\_on\_false_ to `check_cached`, respectively.

Returns: True if the function was found, false otherwise

## check\_funcs( \\@functions-list, $action-if-true?, $action-if-false? )

The same as check\_func, but takes a list of functions in _\\@functions-list_
to look for and checks for each in turn. Define HAVE\_FUNCTION for each
function that was found.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
If any of _action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined,
both callbacks are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or
_action\_on\_false_ to `check_cached`, respectively.  Given callbacks
for _action\_on\_function\_true_ or _action\_on\_function\_false_ are called for
each symbol checked using ["check\_func"](#check_func) receiving the symbol as first
argument.

## check\_type( $symbol, \\%options? )

Check whether type is defined. It may be a compiler builtin type or defined
by the includes.  In C, type must be a type-name, so that the expression
`sizeof (type)` is valid (but `sizeof ((type))` is not).

If _type_ type is defined, preprocessor macro HAVE\__type_ (in all
capitals, with "\*" replaced by "P" and spaces and dots replaced by
underscores) is defined.

This method caches its result in the `ac_cv_type_`type variable.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.

## check\_types( \\@type-list, \\%options? )

For each type in _@type-list_, call [check\_type](https://metacpan.org/pod/check_type) is called to check
for type and return the accumulated result (accumulation op is binary and).

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.
Given callbacks for _action\_on\_type\_true_ or _action\_on\_type\_false_ are
called for each symbol checked using ["check\_type"](#check_type) receiving the symbol as
first argument.

## compute\_int( $expression, @decls?, \\%options )

Returns the value of the integer _expression_. The value should fit in an
initializer in a C variable of type signed long.  It should be possible
to evaluate the expression at compile-time. If no includes are specified,
the default includes are used.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.

## check\_sizeof\_type( $type, \\%options? )

Checks for the size of the specified type by compiling and define
`SIZEOF_type` using the determined size.

In opposition to GNU AutoConf, this method can determine size of structure
members, eg.

    $ac->check_sizeof_type( "SV.sv_refcnt", { prologue => $include_perl } );
    # or
    $ac->check_sizeof_type( "struct utmpx.ut_id", { prologue => "#include <utmpx.h>" } );

This method caches its result in the `ac_cv_sizeof_<set lang>`\_type variable.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.

## check\_sizeof\_types( type, \\%options? )

For each type [check\_sizeof\_type](https://metacpan.org/pod/check_sizeof_type) is called to check for size of type.

If _action-if-found_ is given, it is additionally executed when all of the
sizes of the types could determined. If _action-if-not-found_ is given, it
is executed when one size of the types could not determined.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.
Given callbacks for _action\_on\_size\_true_ or _action\_on\_size\_false_ are
called for each symbol checked using ["check\_sizeof\_type"](#check_sizeof_type) receiving the
symbol as first argument.

## check\_alignof\_type( type, \\%options? )

Define ALIGNOF\_type to be the alignment in bytes of type. _type_ must
be valid as a structure member declaration or _type_ must be a structure
member itself.

This method caches its result in the `ac_cv_alignof_<set lang>`\_type
variable, with _\*_ mapped to `p` and other characters not suitable for a
variable name mapped to underscores.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.

## check\_alignof\_types (type, \[action-if-found\], \[action-if-not-found\], \[prologue = default includes\])

For each type [check\_alignof\_type](https://metacpan.org/pod/check_alignof_type) is called to check for align of type.

If _action-if-found_ is given, it is additionally executed when all of the
aligns of the types could determined. If _action-if-not-found_ is given, it
is executed when one align of the types could not determined.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.
Given callbacks for _action\_on\_align\_true_ or _action\_on\_align\_false_ are
called for each symbol checked using ["check\_alignof\_type"](#check_alignof_type) receiving the
symbol as first argument.

## check\_member( member, \\%options? )

Check whether _member_ is in form of _aggregate_._member_ and
_member_ is a member of the _aggregate_ aggregate.

which are used prior to the aggregate under test.

    Config::AutoConf->check_member(
      "struct STRUCT_SV.sv_refcnt",
      {
        action_on_false => sub { Config::AutoConf->msg_failure( "sv_refcnt member required for struct STRUCT_SV" ); },
        prologue => "#include <EXTERN.h>\n#include <perl.h>"
      }
    );

This function will return a true value (1) if the member is found.

If _aggregate_ aggregate has _member_ member, preprocessor
macro HAVE\__aggregate_\__MEMBER_ (in all capitals, with spaces
and dots replaced by underscores) is defined.

This macro caches its result in the `ac_cv_`aggr\_member variable.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.

## check\_members( members, \\%options? )

For each member [check\_member](https://metacpan.org/pod/check_member) is called to check for member of aggregate.

This function will return a true value (1) if at least one member is found.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be favoured
over `default includes` (represented by ["\_default\_includes"](#_default_includes)). If any of
_action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined, both callbacks
are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.
Given callbacks for _action\_on\_member\_true_ or _action\_on\_member\_false_ are
called for each symbol checked using ["check\_member"](#check_member) receiving the symbol as
first argument.

## check\_header( $header, \\%options? )

This function is used to check if a specific header file is present in
the system: if we detect it and if we can compile anything with that
header included. Note that normally you want to check for a header
first, and then check for the corresponding library (not all at once).

The standard usage for this module is:

    Config::AutoConf->check_header("ncurses.h");
    

This function will return a true value (1) on success, and a false value
if the header is not present or not available for common usage.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
When a _prologue_ exists in the optional hash at end, it will be prepended
to the tested header. If any of _action\_on\_cache\_true_,
_action\_on\_cache\_false_ is defined, both callbacks are passed to
["check\_cached"](#check_cached) as _action\_on\_true_ or _action\_on\_false_ to
`check_cached`, respectively.

## check\_headers

This function uses check\_header to check if a set of include files exist
in the system and can be included and compiled by the available compiler.
Returns the name of the first header file found.

Passes an optional \\%options hash to each ["check\_header"](#check_header) call.

## check\_all\_headers

This function checks each given header for usability and returns true
when each header can be used -- otherwise false.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
Each of existing key/value pairs using _prologue_, _action\_on\_cache\_true_
or _action\_on\_cache\_false_ as key are passed-through to each call of
["check\_header"](#check_header).
Given callbacks for _action\_on\_header\_true_ or _action\_on\_header\_false_ are
called for each symbol checked using ["check\_header"](#check_header) receiving the symbol as
first argument.

## check\_stdc\_headers

Checks for standard C89 headers, namely stdlib.h, stdarg.h, string.h and float.h.
If those are found, additional all remaining C89 headers are checked: assert.h,
ctype.h, errno.h, limits.h, locale.h, math.h, setjmp.h, signal.h, stddef.h,
stdio.h and time.h.

Returns a false value if it fails.

Passes an optional \\%options hash to each ["check\_all\_headers"](#check_all_headers) call.

## check\_default\_headers

This function checks for some default headers, the std c89 headers and
sys/types.h, sys/stat.h, memory.h, strings.h, inttypes.h, stdint.h and unistd.h

Passes an optional \\%options hash to each ["check\_all\_headers"](#check_all_headers) call.

## check\_dirent\_header

Check for the following header files. For the first one that is found and
defines 'DIR', define the listed C preprocessor macro:

    dirent.h      HAVE_DIRENT_H
    sys/ndir.h    HAVE_SYS_NDIR_H
    sys/dir.h     HAVE_SYS_DIR_H
    ndir.h        HAVE_NDIR_H

The directory-library declarations in your source code should look
something like the following:

    #include <sys/types.h>
    #ifdef HAVE_DIRENT_H
    # include <dirent.h>
    # define NAMLEN(dirent) strlen ((dirent)->d_name)
    #else
    # define dirent direct
    # define NAMLEN(dirent) ((dirent)->d_namlen)
    # ifdef HAVE_SYS_NDIR_H
    #  include <sys/ndir.h>
    # endif
    # ifdef HAVE_SYS_DIR_H
    #  include <sys/dir.h>
    # endif
    # ifdef HAVE_NDIR_H
    #  include <ndir.h>
    # endif
    #endif

Using the above declarations, the program would declare variables to be of
type `struct dirent`, not `struct direct`, and would access the length
of a directory entry name by passing a pointer to a `struct dirent` to
the `NAMLEN` macro.

This method might be obsolescent, as all current systems with directory
libraries have `<<dirent.h>`>. Programs supporting only newer OS
might not need to use this method.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
Each of existing key/value pairs using _prologue_, _action\_on\_header\_true_
(as _action\_on\_true_ having the name of the tested header as first argument)
or _action\_on\_header\_false_ (as _action\_on\_false_ having the name of the
tested header as first argument) as key are passed-through to each call of
["\_check\_header"](#_check_header).
Given callbacks for _action\_on\_cache\_true_ or _action\_on\_cache\_false_ are
passed to the call of ["check\_cached"](#check_cached).

## \_check\_perlapi\_program

This method provides the program source which is suitable to do basic
compile/link tests to prove perl development environment.

## \_check\_compile\_perlapi

This method can be used from other checks to prove whether we have a perl
development environment or not (perl.h, reasonable basic checks - types, etc.)

## check\_compile\_perlapi

This method can be used from other checks to prove whether we have a perl
development environment or not (perl.h, reasonable basic checks - types, etc.)

## check\_compile\_perlapi\_or\_die

Dies when not being able to compile using the Perl API

## check\_linkable\_xs\_so

Checks whether a dynamic loadable object containing an XS module can be
linked or not. Due the nature of the beast, this test currently always
succeed.

## check\_linkable\_xs\_so\_or\_die

Dies when ["check\_linkable\_xs\_so"](#check_linkable_xs_so) fails.

## check\_loadable\_xs\_so

Checks whether a dynamic loadable object containing an XS module can be
loaded or not. Due the nature of the beast, this test currently always
succeed.

## check\_loadable\_xs\_so\_or\_die

Dies when ["check\_loadable\_xs\_so"](#check_loadable_xs_so) fails.

## \_check\_link\_perlapi

This method can be used from other checks to prove whether we have a perl
development environment including a suitable libperl or not (perl.h,
reasonable basic checks - types, etc.)

Caller must ensure that the linker flags are set appropriate (`-lperl`
or similar).

## check\_link\_perlapi

This method can be used from other checks to prove whether we have a perl
development environment or not (perl.h, libperl.la, reasonable basic
checks - types, etc.)

## check\_lib( lib, func, @other-libs?, \\%options? )

This function is used to check if a specific library includes some
function. Call it with the library name (without the lib portion), and
the name of the function you want to test:

    Config::AutoConf->check_lib("z", "gzopen");

It returns 1 if the function exist, 0 otherwise.

In case of function found, the HAVE\_LIBlibrary (all in capitals)
preprocessor macro is defined with 1 and $lib together with @other\_libs
are added to the list of libraries to link with.

If linking with library results in unresolved symbols that would be
resolved by linking with additional libraries, give those libraries
as the _other-libs_ argument: e.g., `[qw(Xt X11)]`.
Otherwise, this routine may fail to detect that library is present,
because linking the test program can fail with unresolved symbols.
The other-libraries argument should be limited to cases where it is
desirable to test for one library in the presence of another that
is not already in LIBS. 

This method caches its result in the `ac_cv_lib_`lib\_func variable.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
If any of _action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined,
both callbacks are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or
_action\_on\_false_ to `check_cached`, respectively.

It's recommended to use [search\_libs](https://metacpan.org/pod/search_libs) instead of check\_lib these days.

## search\_libs( function, search-libs, @other-libs?, \\%options? )

Search for a library defining function if it's not already available.
This equates to calling

    Config::AutoConf->link_if_else(
        Config::AutoConf->lang_call( "", "$function" ) );

first with no libraries, then for each library listed in search-libs.
_search-libs_ must be specified as an array reference to avoid
confusion in argument order.

Prepend -llibrary to LIBS for the first library found to contain function.

If linking with library results in unresolved symbols that would be
resolved by linking with additional libraries, give those libraries as
the _other-libraries_ argument: e.g., `[qw(Xt X11)]`. Otherwise, this
method fails to detect that function is present, because linking the
test program always fails with unresolved symbols.

The result of this test is cached in the ac\_cv\_search\_function variable
as "none required" if function is already available, as `0` if no
library containing function was found, otherwise as the -llibrary option
that needs to be prepended to LIBS.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
If any of _action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined,
both callbacks are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or
_action\_on\_false_ to `check_cached`, respectively.  Given callbacks
for _action\_on\_lib\_true_ or _action\_on\_lib\_false_ are called for
each library checked using ["link\_if\_else"](#link_if_else) receiving the library as
first argument and all `@other_libs` subsequently.

## check\_lm( \\%options? )

This method is used to check if some common `math.h` functions are
available, and if `-lm` is needed. Returns the empty string if no
library is needed, or the "-lm" string if libm is needed.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
Each of existing key/value pairs using _action\_on\_func\_true_ (as
_action\_on\_true_ having the name of the tested functions as first argument),
_action\_on\_func\_false_ (as _action\_on\_false_ having the name of the tested
functions as first argument), _action\_on\_func\_lib\_true_ (as
_action\_on\_lib\_true_ having the name of the tested functions as first
argument), _action\_on\_func\_lib\_false_ (as _action\_on\_lib\_false_ having
the name of the tested functions as first argument) as key are passed-
through to each call of ["search\_libs"](#search_libs).
Given callbacks for _action\_on\_lib\_true_, _action\_on\_lib\_false_,
_action\_on\_cache\_true_ or _action\_on\_cache\_false_ are passed to the
call of ["search\_libs"](#search_libs).

**Note** that _action\_on\_lib\_true_ and _action\_on\_func\_lib\_true_ or
_action\_on\_lib\_false_ and _action\_on\_func\_lib\_false_ cannot be used
at the same time, respectively.

## pkg\_config\_package\_flags($package, \\%options?)

Search for pkg-config flags for package as specified. The flags which are
extracted are `--cflags` and `--libs`. The extracted flags are appended
to the global `extra_compile_flags` and `extra_link_flags`, respectively.

Call it with the package you're looking for and optional callback whether
found or not.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.
If any of _action\_on\_cache\_true_, _action\_on\_cache\_false_ is defined,
both callbacks are passed to ["check\_cached"](#check_cached) as _action\_on\_true_ or
_action\_on\_false_ to ["check\_cached"](#check_cached), respectively.

## \_check\_mm\_pureperl\_build\_wanted

This method proves the `_argv` attribute and (when set) the `PERL_MM_OPT`
whether they contain _PUREPERL\_ONLY=(0|1)_ or not. The attribute `_force_xs`
is set as appropriate, which allows a compile test to bail out when `Makefile.PL`
is called with _PUREPERL\_ONLY=0_.

## \_check\_mb\_pureperl\_build\_wanted

This method proves the `_argv` attribute and (when set) the `PERL_MB_OPT`
whether they contain _--pureperl-only_ or not.

## \_check\_pureperl\_required

This method calls `_check_mm_pureperl_build_wanted` when running under
[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker) (`Makefile.PL`) or `_check_mb_pureperl_build_wanted`
when running under a `Build.PL` ([Module::Build](https://metacpan.org/pod/Module::Build) compatible) environment.

When neither is found (`$0` contains neither `Makefile.PL` nor `Build.PL`),
simply 0 is returned.

## check\_pureperl\_required

This check method proves whether a pureperl build is wanted or not by
cached-checking `$self->_check_pureperl_required`.

## check\_produce\_xs\_build

This routine checks whether XS can be produced. Therefore it does
following checks in given order:

- check pureperl environment variables (["check\_pureperl\_required"](#check_pureperl_required)) or
command line arguments and return false when pure perl is requested
- check whether a compiler is available (["check\_valid\_compilers"](#check_valid_compilers)) and
return false if none found
- check whether a test program accessing Perl API can be compiled and
die with error if not

When all checks passed successfully, return a true value.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.

## check\_produce\_loadable\_xs\_build

This routine proves whether XS should be built and it's possible to create
a dynamic linked object which can be loaded using Perl's Dynaloader.

The extension over ["check\_produce\_xs\_build"](#check_produce_xs_build) can be avoided by adding the
`notest_loadable_xs` to `$ENV{PERL5_AC_OPTS}`.

If the very last parameter contains a hash reference, `CODE` references
to _action\_on\_true_ or _action\_on\_false_ are executed, respectively.

## \_set\_argv

Intended to act as a helper for evaluating given command line arguments.
Stores given arguments in instances `_argv` attribute.

Call once at very begin of `Makefile.PL` or `Build.PL`:

    Your::Pkg::Config::AutoConf->_set_args(@ARGV);

## \_default\_includes

returns a string containing default includes for program prologue taken
from autoconf/headers.m4:

    #include <stdio.h>
    #ifdef HAVE_SYS_TYPES_H
    # include <sys/types.h>
    #endif
    #ifdef HAVE_SYS_STAT_H
    # include <sys/stat.h>
    #endif
    #ifdef STDC_HEADERS
    # include <stdlib.h>
    # include <stddef.h>
    #else
    # ifdef HAVE_STDLIB_H
    #  include <stdlib.h>
    # endif
    #endif
    #ifdef HAVE_STRING_H
    # if !defined STDC_HEADERS && defined HAVE_MEMORY_H
    #  include <memory.h>
    # endif
    # include <string.h>
    #endif
    #ifdef HAVE_STRINGS_H
    # include <strings.h>
    #endif
    #ifdef HAVE_INTTYPES_H
    # include <inttypes.h>
    #endif
    #ifdef HAVE_STDINT_H
    # include <stdint.h>
    #endif
    #ifdef HAVE_UNISTD_H
    # include <unistd.h>
    #endif

## \_default\_includes\_with\_perl

returns a string containing default includes for program prologue containing
_\_default\_includes_ plus

    #include <EXTERN.h>
    #include <perl.h>

## add\_log\_fh

Push new file handles at end of log-handles to allow tee-ing log-output

## delete\_log\_fh

Removes specified log file handles. This method allows you to shoot
yourself in the foot - it doesn't prove whether the primary nor the last handle
is removed. Use with caution.

# AUTHOR

Alberto Simões, `<ambs@cpan.org>`

Jens Rehsack, `<rehsack@cpan.org>`

# NEXT STEPS

Although a lot of work needs to be done, these are the next steps I
intend to take.

    - detect flex/lex
    - detect yacc/bison/byacc
    - detect ranlib (not sure about its importance)

These are the ones I think not too much important, and will be
addressed later, or by request.

    - detect an 'install' command
    - detect a 'ln -s' command -- there should be a module doing
      this kind of task.

# BUGS

A lot. Portability is a pain. **<Patches welcome!**>.

Please report any bugs or feature requests to
`bug-Config-AutoConf@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-AutoConf](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-AutoConf).  We will
be notified, and then you'll automatically be notified of progress
on your bug as we make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::AutoConf

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Config-AutoConf](http://annocpan.org/dist/Config-AutoConf)

- CPAN Ratings

    [http://cpanratings.perl.org/dist/Config-AutoConf](http://cpanratings.perl.org/dist/Config-AutoConf)

- MetaCPAN

    [https://metacpan.org/release/Config-AutoConf](https://metacpan.org/release/Config-AutoConf)

- Git Repository

    [https://github.com/ambs/Config-AutoConf](https://github.com/ambs/Config-AutoConf)

# ACKNOWLEDGEMENTS

Michael Schwern for kind MacOS X help.

Ken Williams for ExtUtils::CBuilder

Peter Rabbitson for help on refactoring and making the API more Perl'ish

# COPYRIGHT & LICENSE

Copyright 2004-2016 by the Authors

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# SEE ALSO

ExtUtils::CBuilder(3)
