# NAME

Applify - Write object oriented scripts with ease

# VERSION

0.20

# DESCRIPTION

This module should keep all the noise away and let you write scripts very
easily. These scripts can even be unit tested even though they are defined
directly in the script file and not in a module.

# SYNOPSIS

    #!/usr/bin/perl
    use Applify;

    option file => input_file => 'File to read from';
    option dir => output_dir => 'Directory to write files to';
    option flag => dry_run => 'Use --no-dry-run to actually do something', 1;

    documentation __FILE__;
    version 1.23;

    sub generate_exit_value {
      return int rand 100;
    }

    # app {...}; must be the last statement in the script
    app {
      my ($app, @extra) = @_;
      my $exit_value = 0;

      print "Extra arguments: @extra\n" if(@extra);
      print "Will read from: ", $app->input_file, "\n";
      print "Will write files to: ", $app->output_dir, "\n";

      if($app->dry_run) {
        die 'Will not run script';
      }

      return $app->generate_exit_value;
    };

# APPLICATION CLASS

This module will generate an application class, which `$app` inside the
["app"](#app) block is an instance of. The class will have these methods:

- `new()`

    An object constructor. This method will not be auto generated if any of
    the classes given to ["extends"](#extends) has the method `new()`.

- `run()`

    This method is basically the code block given to ["app"](#app).

- Other methods

    Other methods defined in the script file will be accesible from `$app`
    inside `app{}`.

- `_script()`

    This is an accessor which return the [Applify](https://metacpan.org/pod/Applify) object which
    is refered to as `$script` in this documentation.

    NOTE: This accessor starts with an underscore to prevent conflicts
    with ["options"](#options).

- Other accessors

    Any ["option"](#option) (application option) will be available as an accessor on the
    application object.

# EXPORTED FUNCTIONS

## option

    option $type => $name => $documentation;
    option $type => $name => $documentation, $default;
    option $type => $name => $documentation, $default, @args;
    option $type => $name => $documentation, @args;

This function is used to define options which can be given to this
application. See ["SYNOPSIS"](#synopsis) for example code. This function can also be
called as a method on `$script`. Additionally, similar to
[Moose attributes](https://metacpan.org/pod/Moose::Manual::Attributes#Predicate-and-clearer-methods), a
`has_$name` method will be generated, which can be called on `$app` to
determine if the ["option"](#option) has been set, either by a user or from the
`$default`.

- `$type`

    Used to define value types for this input. Can be:

        | $type | Example             | Attribute value |
        |-------|---------------------|-----------------|
        | bool  | --foo, --no-foo     | foo=1, foo=0    |
        | flag  | --foo, --no-foo     | foo=1, foo=0    |
        | inc   | --verbose --verbose | verbose=2       |
        | str   | --name batwoman     | name=batwoman   |
        | int   | --answer 42         | answer=42       |
        | num   | --pie 3.14          | pie=3.14        |

- `$name`

    The name of an application option. This name will also be used as accessor name
    inside the application. Example:

        # define an application option: 
        option file => some_file => '...';

        # call the application from command line:
        > myapp.pl --some-file /foo/bar

        # run the application code:
        app {
          my $app = shift;
          print $app->some_file # prints "/foo/bar"
          return 0;
        };

- `$documentation`

    Used as description text when printing the usage text.

- `$default`

    Either a plain value or a code ref that can be used to generate a value.

        option str => passwd => "Password file", "/etc/passwd";
        option str => passwd => "Password file", sub { "/etc/passwd" };

- `@args`
    - `alias`

        Used to define an alias for the option. Example:

            option inc => verbose => "Output debug information", alias => "v";

    - `required`

        The script will not start if a required field is omitted.

    - `n_of`

        Allow the option to hold a list of values. Examples: "@", "4", "1,3".
        See ["Options-with-multiple-values" in Getopt::Long](https://metacpan.org/pod/Getopt::Long#Options-with-multiple-values) for details.

    - `isa`

        Can be used to either specify a class that the value should be instantiated
        as, or a [Type::Tiny](https://metacpan.org/pod/Type::Tiny) object that will be used for coercion and/or type
        validation.

        Example using a class:

            option file => output => "output file", isa => "Mojo::File";

        The `output()` attribute will then later return an object of [Mojo::File](https://metacpan.org/pod/Mojo::File),
        instead of just a plain string.

        Example using [Type::Tiny](https://metacpan.org/pod/Type::Tiny):

            use Types::Standard "Int";
            option num => age => "Your age", isa => Int;

    - Other

        Any other [Moose](https://metacpan.org/pod/Moose) attribute argument may/will be supported in
        future release.

## documentation

    documentation __FILE__; # current file
    documentation '/path/to/file';
    documentation 'Some::Module';

Specifies where to retrieve documentaion from when giving the `--man` option
to your script.

## version

    version 'Some::Module';
    version $num;

Specifies where to retrieve the version number from when giving the
`--version` option to your script.

## extends

    extends @classes;

Specify which classes this application should inherit from. These
classes can be [Moose](https://metacpan.org/pod/Moose) based.

## hook

    hook before_exit            => sub { my ($script, $exit_value) = @_ };
    hook before_options_parsing => sub { my ($script, $argv) = @_ };

Defines a hook to run.

- before\_exit

    Called right before `exit($exit_value)` is called by [Applify](https://metacpan.org/pod/Applify). Note that
    this hook will not be called if an exception is thrown.

- before\_options\_parsing

    Called right before `$argv` is parsed by ["option\_parser"](#option_parser). `$argv` is an
    array-ref of the raw options given to your application. This hook allows you
    to modify ["option\_parser"](#option_parser). Example:

        hook before_options_parsing => sub {
          shift->option_parser->configure(bundling no_pass_through);
        };

## subcommand

    subcommand list => 'provide a listing objects' => sub {
      option flag => long => 'long listing';
      option flag => recursive => 'recursively list objects';
    };

    subcommand create => 'create a new object' => sub {
      option str => name => 'name of new object', required => 1;
      option str => description => 'description for the object', required => 1;
    };

    sub command_create {
      my ($app, @extra) = @_;
      ## do creating
      return 0;
    }

    sub command_list {
      my ($app, @extra) = @_;
      ## do listing
      return 0;
    }

    app {
      my ($app, @extra) = @_;
      ## fallback when no command given.
      $app->_script->print_help;
      return 0;
    };

This function allows for creating multiple related sub commands within the same
script in a similar fashion to `git`. The ["option"](#option), ["extends"](#extends) and
["documentation"](#documentation) exported functions may sensibly be called within the
subroutine. Calling the function with no arguments will return the running
subcommand, i.e. a valid `$ARGV[0]`. Non valid values for the subcommand given
on the command line will result in the help being displayed.

## app

    app CODE;

This function will define the code block which is called when the application
is started. See ["SYNOPSIS"](#synopsis) for example code. This function can also be
called as a method on `$script`.

IMPORTANT: This function must be the last function called in the script file
for unit tests to work. Reason for this is that this function runs the
application in void context (started from command line), but returns the
application object in list/scalar context (from ["do" in perlfunc](https://metacpan.org/pod/perlfunc#do)).

# ATTRIBUTES

## option\_parser

    $script = $script->option_parser(Getopt::Long::Parser->new);
    $parser = $script->option_parser;

You can specify your own option parser if you have special needs. The default
is:

    Getopt::Long::Parser->new(config => [qw(no_auto_help no_auto_version pass_through)]);

## options

    $array_ref = $script->options;

Holds the application options given to ["option"](#option).

# METHODS

## new

    $script = Applify->new({options => $array_ref, ...});

Object constructor. Creates a new object representing the script meta
information.

## print\_help

Will print ["options"](#options) to selected filehandle (STDOUT by default) in
a normalized matter. Example:

    Usage:
       --foo      Foo does this and that
     * --bar      Bar does something else

       --help     Print this help text
       --man      Display manual for this application
       --version  Print application name and version

## print\_version

Will print ["version"](#version) to selected filehandle (STDOUT by default) in
a normalized matter. Example:

    some-script.pl version 1.23

## import

Will export the functions listed under ["EXPORTED FUNCTIONS"](#exported-functions). The functions
will act on a [Applify](https://metacpan.org/pod/Applify) object created by this method.

# COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHORS

Jan Henning Thorsen - `jhthorsen@cpan.org`

Roy Storey - `kiwiroy@cpan.org`
