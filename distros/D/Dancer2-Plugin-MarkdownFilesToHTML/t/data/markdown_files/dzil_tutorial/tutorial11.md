# Testing Tutorial Part III: Useful Test Plugins

As we saw, the `[@Starter]` bundle includes test plugins to find potential
problems with your code. For example, the `[PodSyntaxTests]` warns you when your
documentation has an error.

You can add additional plugins to your distirubiton that similarly "coach" you
and make recommendations for code improvement. This is a quick overview of some
the more common ones that you may want to include in your `dist.ini` file.

Note that many of the code quality tests below can be integrated with advanced
text editors like vim. Instead of tests, you may prefer to lean on your
your text editor to help fix any code issues on the fly.

## Installing and Updating Plugins

Before we get to the topic on hand, this is an excellent opportunity to
sidetrack things with some tips on installing and updating plugins used by your
distribution.

### Installing Plugins

Installing plugins is an easy process. First, add the plugin into your
`dist.ini` file using the usual square-bracketed notation. You can then quickly
add any module dependencies for that plugin with the following command:

```

dzil authordeps --missing | cpanm

```

Here we introduce a `Dist::Zilla` built-in utility, `authordeps`. It scans your
`dist.ini` for plugins and determines the CPAN modules needed by the plugins it
finds. The `--missing` switch will produce a list of missing modules. In the
command above, we pipe that list into the `cpanm` cammand to install them.
Obviously, you'll need `cpanm` installed to take advantage of this shortcut.

Let's test out the shortcut. In the `App::sayhi` work area, add the following
test plugins to the end of the `dist.ini` file:

```

[Test::Kwalitee]
[MojibakeTests]
[Test::Perl::Critic]
[Test::EOL]

```

Now run `dzil authodeps --missing | cpanm` to install all the necessary modules
in a single whack.

To make your life even easier, you can extend `Dist::Zilla` with the
`installdeps` subcommand which will take care of installing not only modules
needed by plugins in `dist.ini` but by the module in your distribution as well.
Install the `installdeps` subcommand with:

`cpanm Dist::Zilla::App::Command::installdeps`

Now you can run `dzil installdeps` to install all necessary modules across your
entire `Dist::Zilla` distribution.

Consult the [official
documentation](https://metacpan.org/pod/Dist::Zilla::App::Command::installdeps)
for more details.

### Updating Plugins

Along with the `installdeps` power tool, you might also want to consider adding
the `stale` subcommand to your repertoire with:

`cpanm Dist::Zilla::App::Command::stale`

Like the `installdeps` subcommand, it affects not only the modules needed by
plugins, but modules needed by the code across your entire distribution.

This command ensures all the modules related to your distribution are the latest
and the greatest. To update all the modules related to your distribution, issue
this command:

`dzil stale --all | cpanm`

It's a great time saver. As always, consult the [official
documentation](https://metacpan.org/pod/Dist::Zilla::App::Command::stale) for
more details.

Alright, with those tips out of the way, let's get to what we came here for.

First, to keep your test output manageable, comment out all the test plugins
added to you `dist.ini` file by adding a semicolon before each test plugin.
You'll uncomment them as we discuss each module.

## POD Coverage Tests - [Official documenation](https://metacpan.org/pod/Dist::Zilla::Plugin::PodCoverageTests)

Hop over to the `Greetings` work area and modify the `dist.ini` file to add the
following plugin:

`[PodCoverageTests]`

This plugin ships with `Dist::Zilla` so you don't need to run the module
installation commands dscussed above.

Run `dzil test` to see a failed test for two `naked subroutines`, `hw` and
`hw_shout`. "Naked" means that your documentation does not properly document how
these functions work. Update the inline documentation in your module to get
those tests to pass. If you are new to plain old documentation, there are many
tutorials just a search away. And, of course, there is always the  [official
documentation](https://perldoc.perl.org/perlpod.html).

## Kwalitee Tests - [Official documenation](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::Kwalitee)

A Kwalitee Test judges the overall quality of your distribution. Instead of
describing what it does, let's see it in action.

Make sure you are still in the `App::sayhi` work area and uncomment out the
`[Test::Kwalitee]` test from your dist.ini file. The `[Test::Kwalitee]` plugin
is executed only when the `release` subcommand is issued. So to run its tests,
do:

`dzil test --release`

You should see the following errors within your test output:

```

xt/release/kwalitee.t ..... 1/?
#   Failed test 'has_changelog'
#   at xt/release/kwalitee.t line 7.
# Error: The distribution hasn't got a Changelog (named something like m/^chang(es?|log)|history$/i. A Changelog helps people decide if they want to upgrade to a new version.
# Details:
# Any Changelog file was not found.
# Remedy: Add a Changelog (best named 'Changes') to the distribution. It should list at least major changes implemented in newer versions.

#   Failed test 'has_license_in_source_file'
#   at xt/release/kwalitee.t line 7.
# Error: Does not have license information in any of its source files
# Details:
# LICENSE section was not found in the pod.
# Remedy: Add =head1 LICENSE and the text of the license to the main module in your code.
# Looks like you failed 2 tests of 17.
xt/release/kwalitee.t ..... Dubious, test returned 2 (wstat 512, 0x200)
Failed 2/17 subtests

Test Summary Report
-------------------
xt/release/kwalitee.t   (Wstat: 512 Tests: 17 Failed: 2)
  Failed tests:  6, 15
  Non-zero exit status: 2
Files=4, Tests=23,  0 wallclock secs ( 0.02 usr  0.02 sys +  0.48 cusr  0.02 csys =  0.54 CPU)
Result: FAIL

```

`Test::Harness` says we failed two tests: `has_changelog` and
`has_license_in_source_file`. We will address these issues later.

Comment the `[Test::Kwalitee]` plugin back out for now.

## Mojibake Tests - [Official documetnation](https://metacpan.org/pod/Dist::Zilla::Plugin::MojibakeTests)

If you work a lot with improving older CPAN modules, the `[MojibakeTests]`
module may can help you spot UTF-8 encoding problems in the code.

## Perl Critic Tests - [Official documentation](https://metacpan.org/pod/Test::Perl::Critic)

To see if your code is following coding best practices, you can use
`[Test::Perl::Critic]`:

Uncomment the plugin in your `dist.ini` and run `dzil test` and you'll see a new error:

```

xt/author/critic.t ........ 2/?
#   Failed test 'Test::Perl::Critic for "blib/script/sayhi"'
#   at /usr/local/share/perl/5.20.2/Test/Perl/Critic.pm line 104.
#
#   Code before strictures are enabled at line 4, column 1.  See page 429 of PBP.  (Severity: 5)
xt/author/critic.t ........ Dubious, test returned 1 (wstat 256, 0x100)
Failed 1/2 subtests

```

This cryptic error is telling us there is no `use strict` pragma in our `sayhi`
command. Slap that in and you'll be good to go.

Note that Perl Critic has a reputation for being quite opinionated. You can
change the behavior of Perl Critic to your liking by supplying configuratoin
file parameters to the plugin with something like:

`critic_config = perlcritic.rc`

The plugin will look for the configuration file in the default location, the
root of your source tree.

There is a lot to the Perl Critic tests and you should definitely [read the
documentation](https://metacpan.org/pod/Test::Perl::Critic) to get the most out
of it. We also note that there is some controvery over the value of the Perl
Critic module as a tool for improving code quality. Some recommend an
alternative,
[Perl::Critic::Freenode](https://metacpan.org/pod/Perl::Critic::Freenode) which
has a [Dist::Zilla wrapper
plugin](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::Perl::Critic::Freenode)
you may want to experiment with.

For now, we recommend commenting this plugin out until you take some time to
evaluate its usefulness.

## Trailing Whitespace Tests - [Official documenation](https://metacpan.org/pod/Dist::Zilla::Plugin::Test::EOL)

If you want to be able to bounce a coin off your code, you'll be interested in
the `[Test::EOL]` plugin which will find trailing whitespace at the
end of lines or files.

## More Tests

Needless to say, there are many, many more plugins out there for helping you
improve your code. Hopefully the small sampling we've offered here whets your
appetite for exploring other useful test plugins on CPAN.

The easiest way to find them is with a [CPAN
search](https://metacpan.org/search?q=dist%3A%3AZilla%3A%3ATest).
