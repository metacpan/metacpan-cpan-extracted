## Overview

This project is a perl XS module for the purpose of keeping "secret" data from getting copied
unintentionally or lingering in memory after it is no longer needed, and preventing those
secrets from being accidentally dumped into logs or debug output.

## Components

### Crypt::SecretBuffer

This is a blessed object which has a secret_buffer struct attached via perl MAGIC.  It has lots
of convenient methods for getting data into and out of the buffer, and searching / comparing the
bytes in the buffer.

### Crypt::SecretBuffer::Span

A Crypt::SecretBuffer:Span object holds a reference to a SecretBuffer along with `pos` and `lim`
markers and an optional `encoding` for advanced character parsing or transcoding.  It has lots
of methods for parsing spans of a buffer.

### Crypt::SecretBuffer::AsyncResult

Perhaps overkill, but SecretBuffer has the ability to "pump" a pipe from a background thread.
This object represents the state of that operation so that the user can wait for it to complete.

### Crypt::SecretBuffer::ConsoleState

This abstracts the ability to turn off terminal echo and enable raw key input handling between
the POSIX and Win32 APIs.

### Crypt::SecretBuffer::INI

Secret files aren't much use if they can't be parsed, so I wrote Crypt::SecretBuffer::INI as an
example of how to parse an ini file using the methods of Span.

### Crypt::SecretBuffer::PEM

OpenSSL PEM is a common format for secrets, so I wrote a parser for that, too.

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

## TESTING

This is an XS module, so it needs to be built before tests can be run.  While it is normally
built with Dist::Zilla, the generated Makefile.PL has been added to the repo so that you can
run `perl Makefile.PL` and `make` and `prove -lvb` without needing all the dependencies of dzil.

Any common functions useful in more than one test can be added to t/lib/Test2AndUtils.pm

Perl doesn't enable C warnings by default.  If you want to look for C compiler warnings, you
need to edit the `Makefile` and add `-Wall` to the `CCFLAGS` variable, then compile and observe
the warnings.
