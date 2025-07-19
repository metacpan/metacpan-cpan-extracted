# NAME

CLI::Helpers - Subroutines for making simple command line scripts

# VERSION

version 2.2

# SYNOPSIS

This module provides a library of useful functions for constructing simple command
line interfaces.  It is able to extract information from the environment and your
~/.gitconfig to display data in a reasonable manner.

    use CLI::Helpers;

    ...
    output({color=>"green"}, "Hello, world!");
    debug({color=>"yellow"}, "Debug output!");

Using this module adds argument parsing using [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) to your script.  It
enables pass-through, so you can still use your own argument parsing routines or
[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) in your script.

# EXPORT

This module exports the `:all` group by default.

## Export Groups

Optionally, you can specify the groups you prefer:

- **:output**

        output()
        verbose()
        debug()
        debug_var()

- **:input**

        menu()
        text_input()
        confirm()
        prompt()
        pwprompt()

- **:all**

        :output
        :input

All groups include these functions:

    cli_helpers_initialize()
    options_description()

## Configuration

It's possible to change the behavior of the import process.

- **copy\_argv**

    Instead of messing with `@ARGV`, operate on a copy of `@ARGV`.

        use CLI::Helpers qw( :output copy_argv );

- **preprocess\_argv**

    This causes the `@ARGV` processing to happen during the `INIT` phase, after
    import but before runtime. This is usually OK for scripts, but for use in
    libraries, it may be undesirable. This is the default when `CLI::Helpers` is
    imported from the `main` package.

        use CLI::Helpers qw( :output preprocess_argv );

- **delay\_argv**

    This causes the `@ARGV` processing to happen when the first call to a function
    needing it run, usually an `output()` call. This is the default when import
    from any other package other than `main`.

        use CLI::Helpers qw( :output delay_argv );

# OUTPUT FUNCTIONS

## output( \\%opts, @messages )

Exported.  Takes an optional hash reference and a list of
messages to be output.

Any data references in the the `@messages` list will automatically be converted to JSON. You may also pass

    { yaml => 1 }

In the options to output in YAML format.

## verbose( \\%opts, @messages )

Exported.  Takes an optional hash reference of formatting options.  Automatically
overrides the **level** parameter to 1 if it's not set.

## debug( \\%opts, @messages )

Exported.  Takes an optional hash reference of formatting options.
Does not output anything unless DEBUG is set.

## debug\_var( \\%opts, \\%Variable )

Exported.  Takes an optional hash reference of formatting options.
Does not output anything unless DEBUG is set.

Passing:

    { json => 1 }

in `\%opts` will format the output as JSON

# OUTPUT OPTIONS

Every output function takes an optional HASH reference containing options for
that output.  The hash may contain the following options:

- **tag**

    Add a keyword to tag output with.  The user may then specify `--tags
    keyword1,keyword2` to only view output at the appropriate level.  This option
    will affect `data-file` and `syslog` output.  The output filter requires both
    the presence of the `tag` in the output options **and** the user to specify
    `--tags` on the command line.

    Consider a script, `status.pl`:

        output("System Status: Normal")
        output({tag=>'foo'}, "Component Foo: OK");
        output({tag=>'bar'}, "Component Bar: OK");

    If an operator runs:

        $ status.pl
        System Status: Normal
        Component Foo: OK
        Component Bar: OK

        $ status.pl --tags bar
        System Status: Normal
        Component Bar: OK

        $ status.pl --tags foo
        System Status: Normal
        Component Foo: OK

    This could be helpful for selecting one or more pertinent tags to display.

- **sticky**

    Any lines tagged with 'sticky' will be replayed at the end program's end.  This
    is to allow a developer to ensure message are seen at the termination of the program.

- **color**

    String. Using Term::ANSIColor for output, use the color designated, i.e.:

        red,blue,green,yellow,cyan,magenta,white,black, etc..

- **level**

    Integer. For verbose output, this is basically the number of -v's necessary to see
    this output.

- **syslog\_level**

    String.  Can be any valid syslog\_level as a string: debug, info, notice, warning, err, crit,
    alert, emerg.

- **no\_syslog**

    Bool.  Even if the user specifies --syslog, these lines will not go to the syslog destination.
    alert, emerg.

- **IMPORTANT**

    Bool. Even if --quiet is specified, output this message.  Use sparingly, and yes,
    it is case sensitive.  You need to yell at it for it to yell at your users.

- **stderr**

    Bool. Use STDERR for this message instead of STDOUT.  The advantage to using this is the
    "quiet" option will silence these messages as well.

- **indent**

    Integer.  This will indent by 2 times the specified integer the next string.  Useful
    for creating nested output in a script.

- **clear**

    Integer.  The number of newlines before this output.

- **kv**

    Bool.  The array of messages is actually a key/value pair, this implements special coloring and
    expects the number of messages to be even.

        output(qw(a 1 b 2));
        # a
        # 1
        # b
        # 2

    Using kv, the output will look like this:

        output({kv=>1}, qw(a 1 b 2));
        # a: 1
        # b: 2
        #

- **data**

    Bool.  Lines tagged with "data => 1" will be output to the data-file if a user specifies it.  This allows
    you to provide header/footers and inline context for the main CLI, but output just the data to a file for
    piping elsewhere.

# INPUT FUNCTIONS

## confirm("prompt")

Exported.  Creates a Yes/No Prompt which accepts y/n or yes/no case insensitively
but requires one or the other.

Returns 1 for 'yes' and 0 for 'no'

## text\_input("prompt", validate => { "too short" => sub { length $\_ > 10 } })

Exported.  Provides a prompt to the user for input.  If validate is passed, it should be a hash reference
containing keys of error messages and values which are subroutines to validate the input available as $\_.
If a validator fails, it's error message will be displayed, and the user will be re-prompted.

Valid options are:

- **default**

    Any string which will be used as the default value if the user just presses enter.

- **validate**

    A hashref, keys are error messages, values are sub routines that return true when the value meets the criteria.

- **noecho**

    Set as a key with any value and the prompt will turn off echoing responses as well as disabling all
    ReadLine magic.  See also **pwprompt**.

- **clear\_line**

    After prompting for and receiving input, remove that line from the terminal.
    This only works on interactive terminals, and is useful for things like
    password prompts.

Returns the text that has passed all validators.

## menu("prompt", $ArrayOrHashRef)

Exported.  Used to create a menu of options from a list.  Can be either a hash or array reference
as the second argument.  In the case of a hash reference, the values will be displayed as options while
the selected key is returned.  In the case of an array reference, each element in the list is displayed
the selected element will be returned.

Returns selected element (HashRef -> Key, ArrayRef -> The Element)

## pwprompt("Prompt", options )

Exported.  Synonym for text\_input("Password: ", noecho => 1);  Also requires the password to be longer than 0 characters.

## prompt("Prompt", options )

Exported.  Wrapper function with rudimentary mimicry of IO::Prompt(er).
Uses:

    # Mapping back to confirm();
    my $value = prompt "Are you sure?", yn => 1;

    # Mapping back to text_input();
    my $value = prompt "Enter something:";

    # With Validator
    my $value = prompt "Enter an integer:", validate => { "not a number" => sub { /^\d+$/ } }

    # Pass to menu();
    my $value = prompt "Select your favorite animal:", menu => [qw(dog cat pig fish otter)];

    # If you request a password, autodisable echo:
    my $passwd = prompt "Password: ";  # sets noecho => 1, disables ReadLine history.

See also: **text\_input**

# OTHER FUNCTIONS

## cli\_helpers\_initialize()

This is called automatically when `preprocess_argv` is set. By default, it'll
be run the first time a definition is needed, usually the first call to
`output()`.  If called automatically, it will operate on `@ARGV`.  You can
optionally pass an array reference to this function and it'll operate that
instead.

In most cases, you don't need to call this function directly.

    #!perl
    # Normal use from main package in a script
    use v5.42;
    use CLI::Helpers qw( :output );

    ...
    # CLI::Helpers has already stripped its args from @ARGV
    my %opts = get_important_things_from(\@ARGV);

    output("ready");

This is the same as specifying `preprocess_argv` from the `main` package.

    use CLI::Helpers qw( :output preprocess_argv );

    ...
    # Since CLI::Helpers opts are stripped from @ARGV,
    #  Getopt::Long::Descriptive won't complain about extra args
    my ($opt,$usage) = describe_option( ... );

    # Now, let CLI::Helpers take the rest, implicit
    #   call to cli_helpers_initialize()
    output("ready");

Or if you'd prefer not to touch `@ARGV` at all, you pass in an array ref:

    use CLI::Helpers qw( :output delay_argv );

    my ($opt,$usage) = describe_option( ... );

    cli_helpers_initialize([ qw( --verbose ) ]);

    output("ready?");
    verbose("you bet I am");

## options\_description()

Returns an array of arrayrefs to use with [Getopt::Long::Descriptive](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ADescriptive).

    use CLI::Helpers qw( option_description );
    use Getopt::Long::Descriptive qw( describe_options );

    my ($opt,$usage) = describe_options("%c %o",
        # Your opts here
        options_description(),
    );

## colorize( $color => 'message to be output' )

Not exported by default.  Checks if color is enabled and applies
the specified color to the string.

## git\_color\_check()

Not exported by default.  Returns 1 if git is configured to output
using color of 0 if color is not enabled.

## def($key)

Not exported by default, returns the setting defined.

## override( variable => 1 )

Exported.  Allows a block of code to override the debug or verbose level.  This
can be used during development to enable/disable the DEBUG/VERBOSE settings.

# ARGS

From CLI::Helpers:

    --data-file         Path to a file to write lines tagged with 'data => 1'
    --tags              A comma separated list of tags to display
    --color             Boolean, enable/disable color, default use git settings
    --verbose           Incremental, increase verbosity (Alias is -v)
    --debug             Show developer output
    --debug-class       Show debug messages originating from a specific package, default: main
    --quiet             Show no output (for cron)
    --syslog            Generate messages to syslog as well
    --syslog-facility   Default "local0"
    --syslog-tag        The program name, default is the script name
    --syslog-debug      Enable debug messages to syslog if in use, default false
    --nopaste           Use App::Nopaste to paste output to configured paste service
    --nopaste-public    Defaults to false, specify to use public paste services
    --nopaste-service   Comma-separated App::Nopaste service, defaults to Shadowcat

# EXAMPLE

A simple example of how to use this module and what it does.

## Script

    #!/usr/bin/env perl
    use CLI::Helpers qw(:all);

    output({color=>'green'}, "Hello, World!");
    verbose({indent=>1,color=>'yellow'}, "Shiny, happy people!");
    verbose({level=>2,kv=>1,color=>'red'}, a => 1, b => 2);
    debug_var({ c => 3, d => 4});

    # Data
    output({data=>1}, join(',', qw(a b c d)));

    # Wait for confirmation
    die "ABORTING" unless confirm("Are you sure?");

    # Ask for a number
    my $integer = prompt "Enter an integer:", validate => { "not a number" => sub { /^\d+$/ } }

    # Ask for next move
    my %menu = (
        north => "Go north.",
        south => "Go south.",
    );
    my $dir = prompt "Where to, adventurous explorer?", menu => \%menu;

    # Ask for a favorite animal
    my $favorite = menu("Select your favorite animal:", [qw(dog cat pig fish otter)]);

## Usage

    $ ./test.pl
    Hello, World!
    a,b,c,d
    $ ./test.pl --verbose
    Hello, World!
      Shiny, Happy people!
    a,b,c,d
    $ ./test.pl -vv
    Hello, World!
      Shiny, Happy people!
      a: 1
      b: 2
    a,b,c,d
    $ ./test.pl --debug
    Hello, World!
      Shiny, Happy people!
      a: 1
      b: 2
    ---
    c: 3
    d: 4
    a,b,c,d

    $ ./test.pl --data-file=output.csv
    Hello, World!
    a,b,c,d
    $ cat output.csv
    a,b,c,d

Colors would be automatically enabled based on the user's ~/.gitconfig

# NOPASTE

This is optional and will only work if you have [App::Nopaste](https://metacpan.org/pod/App%3A%3ANopaste) installed.  If
you just specify `--nopaste`, any output that would be displayed to the screen
is submitted to the [App::Nopaste::Service::Shadowcat](https://metacpan.org/pod/App%3A%3ANopaste%3A%3AService%3A%3AShadowcat) paste bin.  This
paste service is pretty simple, but works reliably.

During the `END` block, the output is submitted and the URL of the paste is
returned to the user.

# AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

# CONTRIBUTORS

- Kang-min Liu <gugod@gugod.org>
- Kevin M. Goess <kgoess@craigslist.org>
- Mohammad S Anwar <mohammad.anwar@yahoo.com>

# SUPPORT

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [https://metacpan.org/release/CLI-Helpers](https://metacpan.org/release/CLI-Helpers)

- CPAN Testers

    The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/C/CLI-Helpers](http://www.cpantesters.org/distro/C/CLI-Helpers)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=CLI-Helpers](http://matrix.cpantesters.org/?dist=CLI-Helpers)

## Bugs / Feature Requests

This module uses the GitHub Issue Tracker: [https://github.com/reyjrar/CLI-Helpers/issues](https://github.com/reyjrar/CLI-Helpers/issues)

## Source Code

This module's source code is available by visiting:
[https://github.com/reyjrar/CLI-Helpers](https://github.com/reyjrar/CLI-Helpers)
