## CODE STYLE

Please use a 3-space indent throughout.

### C Code

Try to use C89 compatible syntax, with `/* */` comments, and declaring variables at the top of
a block.

When writing C code, look for opportunities to reduce the number of curly braces, for instance
writing

```
   if (test) {
      single_line_of_code;
   }
   else {
      single_line_of_code;
   }
```

as

```
   if (test)
      single_line_of_code;
   else
      single_line_of_code;
```

Add comments before any significant block of code, explaining what the next few lines
do, but don't document every single line.  Do add line comments for non-obvious API details like
when Windows functions take a bunch of true/false parameters that aren't explained by a variable
name.

Also look for ways to code defensively, so that unexpected behavior from the functions you call
still follows a sensible control path.

Feel free to use "goto" in the specific circumstance of having a lot of initialized variables
which need cleaned up, and having a "cleanup" block at the bottom of the function which checks
each variable and then cleans it if it was initialized.  This avoids redundant cleanup code
throughout the function.  Beware of any Perl API functions that might 'croak'.

I'm trying to keep this project Win32-compatible, so any solution based on POSIX APIs needs a
Win32 equivalent.

### XS Code

When writing XS code, take special care to make sure that if something dies with an exception,
the Perl temporaries system will take care of cleaning up allocations etc.  For example,
SAVEFREEPV can deallocate buffers automatically.  Use "croak" or "croak_with_syserror" in any
place that the user has obviously violated the API of a function.  Return false or NULL etc.
for common scenarios where a result can't be computed but there was a reasonable expectation a
user might supply those parameters.

Note the style of the functions used in the typemap that convert Perl objects into pointers to
C structs, like `secret_buffer* secret_buffer_from_magic(SV *obj, int flags);`.  The extension
MAGIC is a fast and foolproof way to tie C structures to perl objects, and ensure a proper
cleanup.

### Perl Code

Try to write code compatible with Perl 5.8.  Try to keep down the total number of dependencies
for the project, unless some non-core module provides a valuable function that can't easily be
substituted.  Try to keep the code "tight" but not terse or golfed.  Add a comment on any line
that isn't quickly obvious to a perl programmer.

Note that the unit testing is using Test2, and I augmented that module with an 'explain'
function so that difficult-to-diagnose test failures can dump data structures for quick
inspection.  If you want to inspect results, a nice idiom is
```
is( $actual, $expected )
  or note explain $actual;
```
You can choose whether to leave those diagnostics in the end result or not based on whether you
expect them to be useful in the future.

TESTING
-------

This is an XS module, so it needs to be built before tests can be run.  There is a helper
script `./dzil-prove` which compiles the module and then runs `prove`.  You can also pass a
test name to that like `./dzil-prove t/10-substr.t`.

This process is using `dzil build` to create a directory `./Crypt-SecretBuffer-$VERSION` and
then `perl Makefile.PL` inside that directory to build several source files including
`SecretBuffer.c`.  It then runs `make` to compile, and then `prove -lvb` to set up the perl
module path to include the generated .so file.

You can inspect those generated files, but remember that any changes need to be made to the
files in the root of the project, then regenerate the generated files per the recipe above.

Any common functions useful in more than one test can be added to t/lib/Test2AndUtils.pm

Perl doesn't enable C warnings by default.  If you want to look for C compiler warnings, you
need to `dzil build` to get the `./Crypt-SecretBuffer-(VERSION)` directory, then enter that
directory and `perl Makefile.PL`, then edit the `Makefile` and add `-Wall` to the `CCFLAGS`
variable, then compile and observe the warnings.
