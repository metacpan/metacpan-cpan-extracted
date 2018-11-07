# Testing Tutorial Part II: Writing and Running Tests with `Dist::Zilla`

Before proceeding make sure all the `sayhi` module tests pass. If not, do you
what you can to get them to pass. Let's also declutter our source tree so we can
focus on the files we care about.

`dzil clean`

Off to the races, we go.

## Fixing Failed Tests

To see what a failed test looks like, we are going to purposeflly introduce some
badly formed documentation. Edit the `lib/App/sayhi.pm` module and add the
following lines to the end of the file:

```

=hea1 SYNOPSIS

From the command line:

    sayhi          # Prints "Hello, World!" followed by a newline
    sayhi --shout  # Shouts it

```

From the source tree directory, run `dzil test` and look toward the bottom of
the output for the following:

```

...

xt/author/pod-syntax.t .. 1/2
#   Failed test 'POD test for blib/lib/App/sayhi.pm'
#   at /home/steve/perl5/lib/perl5/Test/Pod.pm line 184.
# blib/lib/App/sayhi.pm (36): Unknown directive: =hea1
# Looks like you failed 1 test of 2.
xt/author/pod-syntax.t .. Dubious, test returned 1 (wstat 256, 0x100)
Failed 1/2 subtests

Test Summary Report
-------------------
xt/author/pod-syntax.t (Wstat: 256 Tests: 2 Failed: 1)
  Failed test:  2
  Non-zero exit status: 1
Files=2, Tests=5,  0 wallclock secs ( 0.03 usr  0.00 sys +  0.15 cusr  0.02 csys =  0.20 CPU)
Result: FAIL
[@Starter/RunExtraTests] Fatal errors in xt tests
[@Starter/RunExtraTests] Fatal errors in xt tests at /usr/lib/x86_64-linux-gnu/perl5/5.24/Moose/Meta/Method/Delegation.pm line 110.


```

The test report says one of the `pod-syntax.t` tests failed and tells us exactly
what went wrong:

`blib/lib/App/sayhi.pm (36): Unknown directive: =hea1`

Silly us, looks like we made a typo in our pod on line 36 of the
`blib/lib/sayhi.pm` file. Note that your line number might be different from the
line reported here.

But wait, what is the `blib/lib/App` directory and what is our `sayhi.pm` file
doing in there? The tldr; version is you can ignore the `blib` portion of the
filepath and pretend it's not there.

But if you are curious to know, think back to last tutorial when we mentioned that
the `test` subcommand created a temporary build. That build is located in a
hidden `.build` directory in our source tree. Look inside of it with:

`cd .build; ls`.

In here, you'll see one or more randomly named directories along with a `latest`
and possibly a `previous` symbolic link. These are symbolic links to the
`latest` and  `previous` failed builds located in one of the randomly named
directories. Drop into the `latest` build and you'll see our the mysterious
`blib` directory containing our `lib/App/sayhi.pm` file. So this is why it says
the error is in the `blib` directory.

Let's jump out of the `.build` directory and back to the root of the source
tree. Open up the `lib/App/sayhi.pm` file and change `hea1` to `head1`. Run your
tests again to make sure everything is kosher:

`dzil test`

Looking good again? Great. We also have a new `SYNOPSIS` section in our
documentation to boot. Now that our toes are wet, let's dive all in and write
some new tests for our module. Where do we begin?

## Writing Your Own Tests

Follow these basic steps to write your tests.

### Step 1: Determine What Test to Write

Figuring out what tests to write can be daunting when you are new to testing.
Our task is harder because, contrary to good **test-driven development**
practices which we'll talk more about soon, we've already written the code we
want to test. Fortunately our module is very simple and we can easily make up
lost ground.

To determine which test to write, it helps to keep in mind that a test
determines if your code has certain characteristics or does what you expect it
to. If your code agrees with the tests expectations, the test passes. If not,
the test fails. Your tests should answer very basic questions. For example:

* Does the module throw the proper error if we give it bad input?
* Does the module give us the output we expect when we input X? How about if we
  input Y? How about Z?
* Does our module not throw any warnings?

With that in mind, let's ask: "What do we expect our sayhi module to do?" Well,
when we type `sayhi` on the command line, we want it to output `Hello, World!\n`
and when we type `sayhi --shout` we want the same thing but in upper case.

OK, so now how do we actually write the tests that will do that?

### Step 2: Determining How to Write the Test

Fortuantely, we don't have to put much effort into writing our tests beyond
finding and installing any of the hundreds of Perl modules that have done the
hard work of writing off-the-shelf test functions for us.

In this case, we are going to bust out the
[`App::Cmd::Tester`](https://metacpan.org/pod/App::Cmd::Tester) module available
on CPAN which contains functions that do exactly what we need. We will put them
to work for us shortly.

### Step 3: Determining Where to Put the Test

Next we need to figure out where to put our tests by first asking: "Is this a
test end users should run?" The answer is not always obvious but in this case it
is. End users needs to be sure they will get correct output when running
the `sayhi` command. Therefore, our test is a standard test and should go in the
`t` directory.

But which file should the tests go in? It's up to the developer to figure out
how to best organize the test files in the `t` directory. Typically, a test
file's name starts with a double digits and that count upward.  Those digits are
followed by a dash, followed by a name. The test functions inside each
file are usually related somehow. For example, you might have a group of tests
for making sure a new feature works.

Following this convention we will name our test file `01-stdout_tests.t`. Tests
within the same directory are run in alphabetical order so the
`00-report-prereqs.t` test file, which begins with `00`, will run before the
`01-stdout_tests.t` file.

### Step 4: Writing the Tests

OK, with all that thinking and planning out of the way, we can write our tests.
First, install the `Test::Command` module:

`cpanm Test::Command`

Next, since our source tree doesn't yet have a `t` directory, let's create it:

`mkdir t`

Any tests we place in the source tree will be automatically moved into the
build's `t` directory.

Edit a new file `t/01-stdout_tests.t` and add the following test code to it:

```prettyprint

use Test::More tests => 2;
use App::Cmd::Tester;
use App::sayhi;

# execute some commands and store the resultant objects
my $normal = test_app('App::sayhi' => []);
my $shout  = test_app('App::sayhi' => [ '--shout' ]);

# test the output of the commands
is ($normal->stdout, "Hello, World!\n", 'can give normal greeting');
is ($shout->stdout,  "HELLO, WORLD!\n", 'can shout greeting');

```

Our test file runs two `is` tests, which are functions supplied by the
`Test::More` module. The `is` tests match the first argument, the stdout from
with the string in our second argument, the output from our commands. The third
argument is the name of our tests. The test names appear in our test output to
help identify a failed test.

The `tests => 2` bit in the first line is called the **plan** and tells the
`Test::Harness` module how many tests it should expect to run in this file.
Including a plan helps improve the clarity of the `Test::Harness` reports and
quiets pesky warnings from `Test::Harness`.

Constult the `App::Cmd::Tester` module for more information on the `test_app`
function used to generate the objects used by our tests.

Let's see if our tests pass:

`dzil test`

If you see errors, look closely at your test code and make sure it has no
mistakes. If that looks good, study the error messages closely and try to
pinoint where things went wrong and try to fix the issue.

Even if we have success with our new tests, we still have a problem. Our
`lib/App/sayhi.pm` module relies on the `Greetings` module to generate the
output.  What if the `Greetings` module isn't generating the proper output? Our
tests will fail.

So if we are going to be thorough, we should go back and add tests to the
`Greetings` module. We'll assign that to you for homework. Hint: Use tests
found in the `Test::Simple` module. We also highly recommend checking out this
[basic
tutorial](https://metacpan.org/pod/release/EXODIST/Test-Simple-1.302140/lib/Test/Tutorial.pod)
on testing Perl code for many more basic test examples.

## Test-Driven Development

As mentioned, writing tests first and then the code to get the test to pass,
known as test-driven development, is a recommended approach to testing. To show
how this process works, add a new test to see if `sayhi` command will output
"HELLO, WORLD!\n" if we issue a `sayhi --yell` command by adding two new lines
to our `t/01-stdout_tests.t` file:

```

my $yell  = test_app('App::sayhi' => [ '--yell' ]);
is ($yell->stdout,  "HELLO, WORLD!\n", 'can yell greeting');

```

Don't forget to increment the plan to "3" while you're editing the file. Save
the file and run the tests:

`dzil test`

You should see the following in your tests:

```

t/01-stdout_tests.t .... 1/3
#   Failed test 'can yell greeting'
#   at t/01-stdout_tests.t line 13.
#          got: ''
#     expected: 'HELLO, WORLD!
# '
# Looks like you failed 1 test of 3.
t/01-stdout_tests.t .... Dubious, test returned 1 (wstat 256, 0x100)
Failed 1/3 subtests

```

The test failure reports says it "expected" `HELLO, WORLD!\n` but "got" an
empty string instead. No surprise here, we haven't programmed our module to
exhibit this behavior. To fix the error we first update the `if` conditional in
our module's `execute` command so it will not what to do if it encounters the
`yell` option:

`if ($opt->{shout} || $opt->{yell}) {`

To the `opt_spec` function, we add the following anonymous array to the return
value to register the new option with our app:

`[ "yell|y", "same as shout" ],`

Once the changes are made, you should see that all tests pass again. The nice
side-effect of test-driven development process is that it helps prove that new
features or major code refacotring don't break older code. Of course, they will
prove it only if our tests are thorough enough. Like anything, writing
efficient, thorough test code is learned with practice.

To gain more practice, try adding two more tests for the shorthand options,
`-s` and `-y`, to ensure our test suite is thorough. Then, using test-driven
development practices, add a new `--goodbye` option which prints `Goodbye,
World!\n` to standard out. Rinse and repeat until the `sayhi` command of your
dreams is complete.

## Changing the Types of Tests `dzil test` Runs

By default, the `dzil test` command runs the standard tests and the `[@Starter]`
bundle also causes it to run the author tests, too. The `test` subcommand gives
you options for changing this behavior:

* `dzil test --no-author` - skips author tests.
* `dzil test --release` - runs all the tests that run during when the `dzil
  realease` command is given. More on this later.
* `dzil test --extended` - this is an advanced option for running tests that run only
  when the $ENV{EXTENDED_TESTING} is set to true. Extended tests typically take
  a long time to run and so developers code these tests to run only when the
  EXTENDED_TESTING flag is set to help cut development time down.
* `dzil test --automated` - used to run "smoke tests" which we won't cover here.
* `dzil test --all` - runs all the different kinds of tests

### Running Test Files More Selctively with the `prove` Command

As your project gets more complex, you'll accumulate more and more tests which
can slow things down a great deal. To speed up testing while you add new
features, you can selectively run which test files to run with the `prove`
command supplied by the Perl core. To run just the output tests, we can issue
the following `prove` command:

`prove -l t/01-stdout_tests.t`

Once you are done writing your new feature and testing it with `prove`, run all
the tests with `dzil test` to make sure your older code still works.

The `-l` option in the command above tells the prove command to look in the
`lib` directory for the module. You should read over `prove`'s documentation to
get more familiar with it and its other options.

Note that if we use `Dist::Zilla` to generate module code needed by the tests,
you'll have to issue a `dist build` command and run the `prove` command from
inside the build tree. We don't need to do that in this case since all the code
we need is in our source tree. If you are running `XS` modules with c code in
them, you'll need to seek another tutorial out for how to get around that with
the `prove` command.

This concludes our very basic tutorial on testing with `Dist::Zilla`. Our last
tutorial on testing will show you how to add useful test plugins to your
distribution to help you write good quality code.
