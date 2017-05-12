=head1 NAME

App::SimpleScan::Cookbook

=head1 DESCRIPTION

This is a documentation-only module that describes how to use C<simple_scan>,
and outlines some techniques you can use for some common Web testing problems.

=head1 BASICS

C<simple_scan> reads I<test specifications> from standard input and generates
Perl code based on these specifications. It can either

=over 4

=item * execute them immediately,

=item * print them on standard output without executing them,

=item * or do both: execute them and then print the generated code on standard output.

=back

=head1 TEST SPECS

Test specifications describe

=over 4

=item * I<where> the page is that you want to check,

=item * some I<content> (in the form of a Perl regular expression) that you want look for

=item * a "success code", which defines whether or not the regex should match, and optionally allows you to run the test as a TODO, or skip it altogether.

=over

=item Y - The regular expression should match.

=item N - The regular expression should I<not> match.

=item TY - This a "TODO" test; eventually the regular expression should match, but isn't expected to now. (If it does, C<simple_report> will not that a test "UNEXPECTEDLY SUCCEEDED".)

=item TN - This "TODO" test is expected to match now, but eventually should not. (If it fails to match, this is also an "unexpected success".)

=item S - This test is to be skipped. Useful for putting in a placeholder test tht you don't currently want to run. This is usually useful when you have a test which is expensive or slow to run, and which you know currently will not pass.

=back

=item * and a comment about why you care

=back

 C<simple_scan> always uses an HTTP GET to access the URL; if you need to do stuff like log in, or other setup that requires any other HTTP action, you'll need to use a plugin (see below).

Note that TODO tests get run whether or not they will pass; we just mind if
they currently fail. Skipped tests are not run at all. Use skipped tests if you
want to save time; use TODO tests if you want to be alerted of a change (from
passing to failing or vice versa).

Some example test specs:

   http://foobar.com?q=zorch&xx=yy /\d+ foobars found/ Y Check zorch query
   http://perl.org/                /Perl/              Y Perl mentioned here
   http://python.org/              /Perl/              N Not mentioned here

=head1 PRAGMAS

You can use pragmas to control how tests are executed. Pragmas start with '%%'
at the beginning of the line, followed by a pragma name and arguments if the
pragma takes any. C<simple_scan> itself provides 3 pragmas:

=over

=item agent

This tells C<simple_scan> what User-Agent string to use. Because remembering
all the fiddly bits is a pain, you can simply use shortcut names, like
"Safari", "Mozilla", or "IE"; the actual list is the one supported by
X<WWW::Mechanize>'s agent_alias() method.

=item cache

Stacks a call to cache() in the tests built by C<simple_scan>. This tells
C<simple_scan> to hang onto the last copy of the page fetched from every URL;
if the URL is hit multiple times during a test, C<simple_scan> fetches it only
once and then reuses the cached copy for further tests.

=item nocache

Turns off caching by stacking a nocache() call in the tests built.
C<simple_scan> will always refetch every URL when nocache() is in force.

=back

Here's a sample test using the base pragmas:

  %%agent Safari
  http://apple.com/html5 /download Safar/ N No Safari warning with Safari
  %%cache
  %%agent IE
  http://apple.com/html5 /download Safar/ Y Safari warning with IE
  http://apple.com/html5 /HTML5 Showcase/ Y uses cached copy
  %%nocache
  http://apple.com/html5 /takes a few/    Y uses a new copy

=head1 VARIABLE SUBSITUTION

You can define substitutions much like you'd use a pragma:

  %%site apple
  %%subsite html5
  http://<site>.com/<subsite> /HTML5 Showcase/ Y Apple's HTML5 showcase

The twist with C<simple_scan> variables is that they can have multiple values:

  %%query foo bar baz
  http://foobar.com/q=<query> /<query> found/ Y Found <query>

This causes C<simple_scan> to generate code to run three tests, one for each of
the values of the 'query' variable. Notice that we can substitute into any
part of the test specification; in this case we didn't substitute into the
test type, but it's as valid as any other part of the line.

If you have multiple variables with multiple values, C<simple_scan> will
generate the Cartesian product of them:

  %%foo one two three four
  %%bar alpha beta gamma delta epsilon
  %%baz now is the time for all good men
  http://sample-site.org?q=<foo><bar>baz> /Found:/ Y Looking for <foo>, <bar>, <baz>

This generates 4 * 5 * 8 = 160 tests in just 4 lines.

Pragmas may expand into other pragmas; the previous example could have been
written as

  %%foo one two three four
  %%bar alpha beta gamma delta epsilon
  %%baz now is the time for all good men
  %%query <foo><bar><baz>
  http://sample-site.org?q=<query> ...

In this case, the 'query' variable would have been assigned all 160 values, and
anything that used the 'query' variable would be expanded with all of them.

Caution is urged in creating complex nested expansions; making these too
complicated can make your generated scripts very hard to debug, as there's
currently no easy way to track the expansions and debug them.

=head2 Matching non-ASCII Latin-1 characters

First: be sure that the non-ASCII character you're seeing on the screen is actually
present in the HTML source. You could be looking at an HTML entity that gets rendered
as the character in question. For instance a degree symbol is actually C<&xB0;>. 

You can match a specific entity with its actual text:

  /&x[bB]0;/

(Note that we've made sure that it will work whether the hex "digits" are upper or
lowercase.) Or you can match an arbitrary entity:

  /&.*?;/

This one will also match things like C<&amp;> and C<&brkbar;> - with great power
comes relative imprecision. There's a handy table of Latin-1 entities at
L<http://www.ramsch.org/martin/uni/fmi-hp/iso8859-1.html>.

In some cases (e.g., Yahoo!'s fr.search search results), there will actually be
non-Latin1 characters that are not HTML encoded. This is probably not good 
practice, but it still exists here and there. To deal with pages like this,
copy and paste the exact text from a "view source" into the regex you want 
to use.

Newer versions of simple_scan handle data smoothly without any special
action on your part, even if the encoding's off a bit.

=head1 PLUGINS

Plugins are Perl modules that extend C<simple_scan>'s abilities without modification of the core code.

=head2 Installing a new pragma

Create a C<pragmas> method in your plugin that returns pairs of pragma names and
methods to be called to process the pragma.

  sub pragmas {
    return (['mypragma' => \&do_my_pragma],
            ['another'  => \&another]);
  }

  sub do_my_pragma {
    my ($app, $args);
    # Parse the arguments. You have access to
    # all of the methods in App::SimpleScan as
    # well as any subs defined here. You may 
    # want to export methods to the App::SimpleScan
    # namespace in your import() method.
  }

  ...

=head2 Installing new command-line options

Create an C<options> method in your plugin that returns a hash of options and
variables to capture their values in. You will also want to export accessors
for these variables to the C<App::SimpleScan> namespace in your C<import>.

  sub import {
    no strict 'refs';
    *{caller() . '::myoption} = \&myoption;
  }

  sub options {
    return ('myoption' => \$myoption);
  }

  sub myoption {
    my ($self, $value) = @_;
    $myoption = $value if defined $value;
    $myoption;
  }

=head2 Installing other modules via plugins

Create a C<test_modules> method that returns a list of module names
to be C<use>d by the generated test program.

  sub test_modules {
    return ('Test::Foo', 'Blortch::Zonk');
  }

=head2 Adding extra code to the test output stack in a plugin

Create a C<per_test> subroutine. This method gets called with the
current C<App::SimpleScan::TestSpec> object.

  sub per_test {
    $self->app->_stack_test(qw(fail "forced failure accessing bad.com";\n))
     if $self->uri =~ /bad.com/;
  }

=head2 Altering code/inserting code for every test stacked

Create a C<filter> subroutine. This will get called with an array of strings
corresponding to the code that's about to be stacked; you can do whatever 
additions or alterations you like. Just return your altered code as an array
of strings; if you've added any tests to it, use the test_count() method in the
app() object to up the test count appropriately.

=head2 Current plugins available

Currently, there are six C<simple_scan> plugins available on CPAN:

=over 

=item Cache - the cache plugin extends C<simple_scan>'s caching to actually store the cached pages on disk. This allows subsequent runs to (if they choose) reuse pages that were fetched by previous runs. This is most useful in situations where you want to explore a number of different tests on a page, and you want to minimize the impact of your fetching the page to test it.

=item Forget - lets you drop a substitution from the substitutions you've defined during a test run.

=item LinkCheck - Lets you set up a set of named links that will be checked for on every page you fetch. Very useful whrn checking to make sure that (say) header and footer sections of pages are being generated correctly and consistently. You can test for the links either being there (via %%has_link) or not there (via %%no_link), and you may drop a link you've beed searching for via %%drop_link.

=item Plaintext - lets you match vs. the plain text of a page, with the markup removed. Allows you to check content without worry if ot how it has been marked up.

=item Retry - lets you automatically retry a URL up to a set number of times before giving up. (It also adds a --retry command-line option which does the same.)

=item Snaphot - lets you set up to be able to automatically (either for every get, or only when there are errors) snapshot the page as it was when the GET request was made. This can be very useful in visually debugging problems with C<simple_scan> tests. See C<App::SimpleScan::Plugin::Snapshot> for detailed usage information.

=back
