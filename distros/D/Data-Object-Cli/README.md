# NAME

Data::Object::Cli - Simple CLIs

# ABSTRACT

Command-line Interface Abstraction for Perl 5

# SYNOPSIS

    package Command;

    use parent 'Data::Object::Cli';

    sub main {
      my ($self) = @_;

      return $self->help;
    }

    my $command = run Command;

# DESCRIPTION

This package provides an abstract base class for defining command-line
interface classes, which can be run as scripts or passed as objects in a more
complex system.

# LIBRARIES

This package uses type constraints from:

[Data::Object::Types](https://metacpan.org/pod/Data::Object::Types)

# ATTRIBUTES

This package has the following attributes:

## args

    args(ArgsObject)

This attribute is read-only, accepts `(ArgsObject)` values, and is optional.

## data

    data(DataObject)

This attribute is read-only, accepts `(DataObject)` values, and is optional.

## opts

    opts(OptsObject)

This attribute is read-only, accepts `(OptsObject)` values, and is optional.

## vars

    vars(VarsObject)

This attribute is read-only, accepts `(VarsObject)` values, and is optional.

# METHODS

This package implements the following methods:

## auto

    auto(Any %args) : HashRef

The auto method is expected to be overridden by the subclass and should return
a hashref where the keys represent a subcommand at `$ARGV[0]` and the value
represents the subroutine to be dispatched to using the `handle` method. To
enable this functionality, the command name be declare a "command" token.

- auto example #1

        package Todo;

        use parent 'Data::Object::Cli';

        our $name = 'todo <{command}>';

        sub auto {
          {
            init => '_handle_init'
          }
        }

        sub _handle_init {
          1234567890
        }

        my $todo = run Todo;

## exit

    exit(Int $code, Maybe[Str] $name, Any %args) : Any

The exit method exits the program using the exit code provided. The exit code
defaults to `0`. Optionally, you can call a handler before exiting by
providing a method name with arguments. The handler will be called using the
`handle` method so the arguments should be key/value pairs.

- exit example #1

        # given: synopsis

        $command->exit(0);

        # $command->exit($code, $method_name, %args);
        # $command->exit($code, $method_name);
        # $command->exit($code);

- exit example #2

        # given: synopsis

        $command->exit(1);

        # $command->exit($code, $method_name, %args);
        # $command->exit($code, $method_name);
        # $command->exit($code);

## fail

    fail(Maybe[Str] $name, Any %args) : Any

The fail method exits the program with a `1` exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the `handle` method so the arguments should be
key/value pairs.

- fail example #1

        # given: synopsis

        $command->fail;

        # $command->fail($method_name, %args);
        # $command->fail($method_name);

## handle

    handle(Str $name, Any %args) : Any

The handle method dispatches to the method whose name is provided as the first
argument. The forwarded method will receive arguments as key/value pairs. This
method injects the `args`, `data`, `vars`, and `opts` attributes as
arguments for convenience of use in the forwarded method. Any additional
arguments should be passed as key/value pairs.

- handle example #1

        # given: synopsis

        $command->handle('main');

        # $command->handle($method_name, %args);
        # $command->handle($method_name);

## help

    help() : Str

The help method returns the help text documented in POD if available.

- help example #1

        package Todolist;

        use parent 'Data::Object::Cli';

        my $todolist = run Todolist;

        # $todolist->help

- help example #2

        package Todolist;

        use parent 'Data::Object::Cli';

        our $name = 'todolist';

        my $todolist = run Todolist;

        # $todolist->help

- help example #3

        package Todolist;

        use parent 'Data::Object::Cli';

        sub name {
          'todolist'
        }

        my $todolist = run Todolist;

        # $todolist->help

- help example #4

        package Todolist;

        use parent 'Data::Object::Cli';

        our $name = 'todolist';
        our $info = 'manage your todo list';

        my $todolist = run Todolist;

        # $todolist->help

- help example #5

        package Todolist;

        use parent 'Data::Object::Cli';

        sub name {
          'todolist'
        }

        sub info {
          'manage your todo list'
        }

        my $todolist = run Todolist;

        # $todolist->help

- help example #6

        package Todolist::Command::Show;

        use parent 'Data::Object::Cli';

        sub name {
          'todolist show [<{priority}>]'
        }

        sub info {
          'show your todo list tasks by priority levels'
        }

        my $command = run Todolist::Command::Show;

        # $command->help

## main

    main(Any %args) : Any

The main method is the "main method" and entrypoint into the program. It's
called automatically by the `run` method if your package is configured as
recommended. This method accepts arguments as key/value pairs, and if called
by `run` will receive the `args`, `data`, `opts`, and `vars` objects.

- main example #1

        package Todolist;

        use parent 'Data::Object::Cli';

        sub main {
          my ($self, %args) = @_;

          return {%args} # no args
        }

        my $todolist = run Todolist;

        $todolist->main;

- main example #2

        package Todolist;

        use parent 'Data::Object::Cli';

        sub main {
          my ($self, %args) = @_;

          # has $args{args}
          # has $args{data}
          # has $args{opts}
          # has $args{vars}

          return {%args}
        }

        # $args{args} = $self->args; # isa <Data::Object::Args>
        # represents @ARGV

        # $args{data} = $self->data; # isa <Data::Object::Data>
        # represents __DATA__

        # $args{opts} = $self->opts; # isa <Data::Object::Opts>
        # represents Getopt::Long

        # $args{vars} = $self->vars; # isa <Data::Object::Vars>
        # represents %ENV

        my $todolist = run Todolist;

        $todolist->handle('main'); # called automatically by run

## okay

    okay(Maybe[Str] $name, Any %args) : Any

The okay method exits the program with a `0` exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the `handle` method so the arguments should be
key/value pairs.

- okay example #1

        # given: synopsis

        $command->okay;

        # $command->okay($method_name, %args);
        # $command->okay($method_name);

## run

    run() : Object

The run method is designed to bootstrap the program. It detects whether the
package is being invoked as a script or class and behaves accordingly. It will
be called automatically when the package is looaded if your package is
configured as recommended. This method will, if invoked as a script, call the
main method passing the `args`, `data`, `opts`, and `vars` objects.

- run example #1

        package Todolist;

        use parent 'Data::Object::Cli';

        run Todolist;

## spec

    spec() : HashRef[HashRef]

The spec method returns a hashref of flag definitions used to configure
[Getopt::Long](https://metacpan.org/pod/Getopt::Long). These options are accessible as methods on the
[Data::Object::Opts](https://metacpan.org/pod/Data::Object::Opts) object through the `opts` attribute. Each flag
definition can optionally declare `args`, `flag`, and `type` values as
follows. The `args` property denotes that multiple flags are permitted and its
value can be any valid [Getopt::Long](https://metacpan.org/pod/Getopt::Long) _repeat_ specifier. The `type`
property denotes the type of data allowed and defaults to type _flag_.
Allowed values are `string`, `integer`, `number`, `float`, or `flag`. The
`flag` property denotes the flag aliases and should be a pipe-delimited
string, e.g. `userid|id|u`, if multiple aliases are used.

- spec example #1

        package Todolist::Task;

        use parent 'Data::Object::Cli';

        our $name = 'todotask {id}';

        # id accessible as $self->args->id; alias of $ARGV[0]

        sub spec {
          {
            #
            # represented in Getopt::Long as
            # title|t=s
            #
            # title is accessible as $self->opts->title
            #
            title => {
              type => 'string',
              flag => 't'
            },
            #
            # represented in Getopt::Long as
            # content=s
            #
            # content is accessible as $self->opts->content
            #
            content => {
              type => 'string',
            },
            #
            # represented in Getopt::Long as
            # attach|a=s@
            #
            # attach is accessible as $self->opts->attach
            #
            attach => {
              flag => 'a',
              args => '@' # allow multiple options
            },
            #
            # represented in Getopt::Long as
            # publish|p
            #
            # publish is accessible as $self->opts->publish
            #
            publish => {
              flag => 'p',
              type => 'flag'
            },
            #
            # represented in Getopt::Long as
            # unpublish|u
            #
            # unpublish is accessible as $self->opts->unpublish
            #
            unpublish => {
              flag => 'u'
              # defaults to type: flag
            }
          }
        }

        my $todotask = run Todolist::Task;

        # $todotask->spec

## subs

    subs(Any %args) : HashRef

The subs method works in tandem with the ["auto"](#auto) method and is expected to be
overridden by the subclass and should return a hashref where the keys represent
a subcommand at `$ARGV[0]` and the value represents the description of the
corresponding action (i.e. _command_).

- subs example #1

        package Todo::Admin;

        use parent 'Data::Object::Cli';

        our $name = 'todo <action>';

        sub auto {
          {
            add_user => '_handle_add_user',
            del_user => '_handle_del_user'
          }
        }

        sub subs {
          {
            add_user => 'Add a new user to the system',
            del_user => 'Remove a user to the system'
          }
        }

        my $admin = run Todo::Admin;

        __DATA__

        Usage: {name}

        Commands:

        {commands}

        Options:

        {options}

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-cli/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-cli/wiki)

[Project](https://github.com/iamalnewkirk/data-object-cli)

[Initiatives](https://github.com/iamalnewkirk/data-object-cli/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-cli/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-cli/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-cli/issues)
