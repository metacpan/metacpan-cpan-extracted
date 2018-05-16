Files in this directory are programs that a are used in
testing.

Each is in the format of a Perl module.

BEGIN FIXME: change this so that each can by syntax checked
for correctness just by running the perl interpreter over it.
For example:

    $ perl P520.pm

end FIXME

The beginning of the file include and before the first line that starts

    __DATA__

is skipped over.

The format of each subsequent test is as follows.

* Each test starts with:

         ####
* The line after that should start with `#` and is a description of the test. For example:

         # List of constants in void context
* Lines that start `# SKIP` have text after the `# SKIP` evaluated to determine if the test should be run or skipped
* Lines that start `# CONTEXT` give pragmas that should be run.
* Any remaining lines should be valid Perl code that is evaluated and deparsed.
