I will be giving a talk on `B::DeparseTree` and its use
in a debugger `Devel::Trepan` at the upcoming YAPC 2018
in Glasgow. As a result I have been working quote a bit
on `B::DeparseTree` and have a number of thoughts.

Here are some of them. This is the first part. The
second part if I get around to writing it will be about the
cool features of B::DeparseTree from an application.

This part focuses on some of the issues of `B::Deparse` and how it
could be (or in a sense _is_ being rewritten in `B::DeparseTree`.


# Introduction

As someone who make a lot of mistakes, I've long wanted to improve the
precision of debugging and error reporting. Through Perlmonks, I was
directed upon the idea of using the OP address as means to get more
detailed information of where the program is. I was also pointed to
`B::Deparse`.

At the time, I was elated. Perl5 uses a tree interpreter to run your
Perl script. So what a decompiler does here to recreate the source
code, and in in particular what `B::Deparse` does, is walk the `B::OP`
tree, building up strings as it traverses. If you start from the root
of the tree, you get everything. If instead you start from some other
node, you get the text that this portion is responsible for. So I
thought all I need to do is augment `B::Deparse` a little bit. True,
but...


# Deparse problems

The biggest issue with `B::Deparse` is it is one 6.5K file. There are
three test files, of which two of them are significant.  The sheer
*number* of tests are huge too - hundreds of tests in one, and a
couple thousand in the other. The reason for the large number of tests
in the latter test is a result of Perl having so many builtin
functions - over 100 of them. Each of these is an opcode; and each
function can be tried several times in different ways.

That there is such extensive testing is great, but given Perl
testing's default behavior of running all tests unconditionally, the
slightest error meant that I'd see a spew of error of hundreds to
thousands of line. (Does `prove` or `Test::More` have simple way to
stop on the first failure?)

So it was important to get tests under control, I mean starting with
some quick little unit tests, and bailing if those fail. Unit tests
and B::Deparse?

When a program is big and monolithic, it is often not modular. When it
is not modular, it's hard to test it. That is most likely why both
tests for `B::Deparse` that require a lot of setup.

The tests are also frail in the face of the formatting changes to
`B::Deparse`. and can cause many if not all of the hundreds of tests
to fail.

How we do better? I've mentioned unit tests. Later I'll describe
something else that eliminates the frailness of testing against a
particular kind of formatting.

# Testing

When `B::Deparse fails`, it's can take a little bit of study to
understand what it is talking about:

Here is an example:

```
#   Failed test 'Constants in a block'
#   at t/20-deparse-small.t line 114.
# {
#      {
#         '??';
#         2
# }
# }'
#     doesn't match '(?^:^\s*\{\s*\s+\{\s+\'\?\?\?\'\;\s+2\s+)'
```

Is this clear to you what's wrong? Line 114 is the line number of
code that is reading data. What you really want to know is the line
number of the data that it is reading. The best it does is give
'Constants in a block' so you can search for that.

I have split out the test data from the code so that I can reuse the
code for different Perl versions.

The way I currently address the above is to show in addition to the
above message, a diff of two compared texts:

```
# ***************
# *** 1,7 ****
#
#   {
# !      {
# !         '??';
# !         2
# ! }
# ! }
# \ No newline at end of file
# --- 1,4 ----
#
#   {
# !     '???';
# !     2
#
```

Visually, it is easily to ignore differences in spacing to see
what's wrong.

Going future, when I hit an error, the test program that failed is written
out to disk. This way that test can be run in isolation to the other tests.

What is further needed though is to start grouping simple tests that
trigger the use of a `B::Deparse` function and to split that those
tests into a separate data file. For example there might be a test
data file of tests for the method `binop` which handles for binary
operators, another test data file for `listop`, which handles the
list-like operators and so on.

## Round trip tests

I have ameliorated somewhat of the difficulty in figuring out what
went wrong when a test fails by improving the error message and
writing out the test. However, there still is the problem that the
tests are frail, even though a regular expression is used in
comparison. We have this conundrum: if you want something that a
person can easily detect difference you would compare using a string
or a very simple regular expressions. But as you move to making tests
less fragile and less subject to the whim of how `B::Deparse` format
Perls, you move onto more complicated regular expressions. But this is
harder to suss when there is a difference. So how do we do better?

We can avoid all of the frailty associated comparisons or pattern
matching by doing round trip testing. In the Perl source code
distribution there already are a number of Perl programs that check
themselves when run. These are in Perl's `t` directory. Some files in
that are `t/base/cond.t`, or `t/base.if.t`.

So all that is needed is have `B::Deparse` compile and decompile these
programs (the somewhat magical invocation is `perl -MO=Deparse,sC
...`), and write the decompiled result to file. When we can then run
Perl on the decompiled code and Perl will indicate whether the result
is invalid. Edsgar Dijkstra's quip about a test not proving
correctness, but only demonstrating failure applies here. If the code
doesn't fail that doesn't mean that it was deparsed correctly. Just
that the running the program couldn't find an error.

But when there is an error, Perl error message is often helpful in
suggesting what decompiled incorrectly, especially when the error is a
problem in Perl syntax. Even when the error is not a syntax error, the
the decompilation error and the run-time error are generally close.

By inspecting the resulting file, I can usually see what's wrong. And
I have original source to compare against if the problem was not
apparent.


# The need for modularity


## Tracking changes across Perl Versions

Currently `B::Deparse` is bundled with Perl and that means that the
code that comes with Perl only needs to be concerned with that version.

Although it is true that you'll find tests on the Perl versions like
this:

    $self->{'hints'} &= 0xFF if $] < 5.009;

in reality the code generally cannot be used by from another major Perl
version release.

Here are some of the error messages I got when I tried to use the Perl
5.26.2 version of `B::Deparse` from Perl 5.24.4:

    "OPpSPLIT_ASSIGN" is not exported by the B module
    "OPpSPLIT_LEX" is not exported by the B module

So how would you understand how the OP tree has changed between in
5.24.4 and 5.26.2 that requires changes in the way `B::Deparse` works?
Well, you could use either a file or git diff between two files in
each of the released versions. And/or you could use that with git
commits or ChangeLog entries. Depending on what changed, this might
not be so bad, but generally I find it tedious.

What you want is to separate each changes into one of three
categories:

1. Bug fixes in the newer version would also be beneficial in the older version
2. Nonfunctional, but stylistic changes
3. Changes that reflect real changes between versions and so the
   two sets of code need be kept separately


If the program were reorganized and modular though changes between
versions and why would be more apparent. As an example of how this
might look in Perl, I'll show how I've done this in Python. Suppose
you want to now which opcodes are different between Python 3.4 and
3.5. Well, look at:
https://github.com/rocky/python-xdis/blob/master/xdis/opcodes/opcode_35.py

And how does that effect decompilation? That's a harder question to
answer simply, but that too to some degree of success has been
isolated in code. For the semantic tree interpretation routines see:
https://github.com/rocky/python-uncompyle6/blob/master/uncompyle6/semantics/customize3.py#L258-L276.


## The how-to-extend problem?

I wanted to extend `B::Deparse` so I can use it at run time to
determine my position. So how do I do this?

Given that B::Deparse isn't all modular and is a single file, I
started out in the most obvious way by copying the file and modifying
it. Given my lack of understanding of how B::Deparse worked, this was
extremely expedient and probably unavoidable. However very quickly I
realized that it just doesn't scale, and that I'd *have *to modularize
the code.  have spent a good deal time trying to refactor the code at
least in the context of my new feature.

I'm close to having this finished. This code could be used as the
basis for a rewritten `B::Deparse`.

Next are some cool features of the new code that could be used in `B::Deparse`.

# Table-driven opcodes

In trying to use and modularize this code, I see there is
a lot of repetition in subroutine parsing routines.

Compare this:


    sub pp_die { listop(@_, "die") }
    sub pp_each { unop(@_, "each") }
    sub pp_egrent { baseop(@_, "endgrent") }

with

    'die'        => 'listop',
    'each'       => 'unop',
    'egrent'     => ['baseop', 'endgrent'],

Was it obvious to you when looking at the subroutine call, that the
name "egrent" got converted to "endgrent" which didn't happen in other
shown entries?

Having mappings from PP opcode to function makes it easier to
customize the entries as required as the Perl version varies.  In some
versions, some ops we need to surround an the text from an operation
with a "my", while in other versions that is not the case. It is
clearer and simpler just to change table entries than it is to muck
with OO lookup or doing subroutine assignments.

# Format-spec driven fragment creation

How `B::Deparse` works is conceptually simple: it walks the optree
building and combining string fragments at node from the nodes'
children. When you return from root or top node after walking the
tree, you have a string representing the entire function or module that
the root represents.

However understanding what goes on inside a given node, is very
haphazard. So if you have a bug somewhere, figuring out where there
was a problem and why is difficult.

This kind of thing you may have already encountered in a different
guise, and a good solution to that problem applies here. Imagine you
are trying to create a nicely formatted report with lots of data
values. You can try combining strings together interspersed with calls
to conversion routines to different data items.

But instead what most people do is use some sort of format specifiers
so that in a template you get a sense of what's going on, and then
just fill in the values. And that's a good solution here.

# Swapping out Node and Syntax tree for String-oriented routines.

The focus of code right now has been for handling this new fragment
deparsing feature. However I believe `B::DeparseTree` would be a good
replacement for `B::Deparse` because of its modularity, and ease with
which you can see what's going on.  The template specifiers assists
separation in traversing code from building string.
