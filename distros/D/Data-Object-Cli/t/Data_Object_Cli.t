use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;
use Test::Trap;

=name

Data::Object::Cli

=cut

=tagline

Simple CLIs

=cut

=abstract

Command-line Interface Abstraction for Perl 5

=cut

=includes

method: auto
method: exit
method: fail
method: handle
method: help
method: main
method: okay
method: run
method: spec

=cut

=synopsis

  package Command;

  use parent 'Data::Object::Cli';

  sub main {
    my ($self) = @_;

    return $self->help;
  }

  my $command = run Command;

=cut

=libraries

Data::Object::Types

=cut

=attributes

args: ro, opt, ArgsObject
data: ro, opt, DataObject
opts: ro, opt, OptsObject
vars: ro, opt, VarsObject

=cut

=description

This package provides an abstract base class for defining command-line
interface classes, which can be run as scripts or passed as objects in a more
complex system.

=cut

=method auto

The auto method is expected to be overridden by the subclass and should return
a hashref where the keys represent a subcommand at C<$ARGV[0]> and the value
represents the subroutine to be dispatched to using the C<handle> method. To
enable this functionality, the command name be declare a "command" token.

=signature auto

auto(Any %args) : HashRef

=example-1 auto

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

=cut

=method exit

The exit method exits the program using the exit code provided. The exit code
defaults to C<0>. Optionally, you can call a handler before exiting by
providing a method name with arguments. The handler will be called using the
C<handle> method so the arguments should be key/value pairs.

=signature exit

exit(Int $code, Maybe[Str] $name, Any %args) : Any

=example-1 exit

  # given: synopsis

  $command->exit(0);

  # $command->exit($code, $method_name, %args);
  # $command->exit($code, $method_name);
  # $command->exit($code);

=example-2 exit

  # given: synopsis

  $command->exit(1);

  # $command->exit($code, $method_name, %args);
  # $command->exit($code, $method_name);
  # $command->exit($code);

=cut

=method fail

The fail method exits the program with a C<1> exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the C<handle> method so the arguments should be
key/value pairs.

=signature fail

fail(Maybe[Str] $name, Any %args) : Any

=example-1 fail

  # given: synopsis

  $command->fail;

  # $command->fail($method_name, %args);
  # $command->fail($method_name);

=cut

=method handle

The handle method dispatches to the method whose name is provided as the first
argument. The forwarded method will receive arguments as key/value pairs. This
method injects the C<args>, C<data>, C<vars>, and C<opts> attributes as
arguments for convenience of use in the forwarded method. Any additional
arguments should be passed as key/value pairs.

=signature handle

handle(Str $name, Any %args) : Any

=example-1 handle

  # given: synopsis

  $command->handle('main');

  # $command->handle($method_name, %args);
  # $command->handle($method_name);

=cut

=method help

The help method returns the help text documented in POD if available.

=signature help

help() : Str

=example-1 help

  package Todolist;

  use parent 'Data::Object::Cli';

  my $todolist = run Todolist;

  # $todolist->help

=example-2 help

  package Todolist;

  use parent 'Data::Object::Cli';

  our $name = 'todolist';

  my $todolist = run Todolist;

  # $todolist->help

=example-3 help

  package Todolist;

  use parent 'Data::Object::Cli';

  sub name {
    'todolist'
  }

  my $todolist = run Todolist;

  # $todolist->help

=example-4 help

  package Todolist;

  use parent 'Data::Object::Cli';

  our $name = 'todolist';
  our $info = 'manage your todo list';

  my $todolist = run Todolist;

  # $todolist->help

=example-5 help

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

=example-6 help

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

=cut

=method main

The main method is the "main method" and entrypoint into the program. It's
called automatically by the C<run> method if your package is configured as
recommended. This method accepts arguments as key/value pairs, and if called
by C<run> will receive the C<args>, C<data>, C<opts>, and C<vars> objects.

=signature main

main(Any %args) : Any

=example-1 main

  package Todolist;

  use parent 'Data::Object::Cli';

  sub main {
    my ($self, %args) = @_;

    return {%args} # no args
  }

  my $todolist = run Todolist;

  $todolist->main;

=example-2 main

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

=cut

=method okay

The okay method exits the program with a C<0> exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the C<handle> method so the arguments should be
key/value pairs.

=signature okay

okay(Maybe[Str] $name, Any %args) : Any

=example-1 okay

  # given: synopsis

  $command->okay;

  # $command->okay($method_name, %args);
  # $command->okay($method_name);

=cut

=method run

The run method is designed to bootstrap the program. It detects whether the
package is being invoked as a script or class and behaves accordingly. It will
be called automatically when the package is looaded if your package is
configured as recommended. This method will, if invoked as a script, call the
main method passing the C<args>, C<data>, C<opts>, and C<vars> objects.

=signature run

run() : Object

=example-1 run

  package Todolist;

  use parent 'Data::Object::Cli';

  run Todolist;

=cut

=method spec

The spec method returns a hashref of flag definitions used to configure
L<Getopt::Long>. These options are accessible as methods on the
L<Data::Object::Opts> object through the C<opts> attribute. Each flag
definition can optionally declare C<args>, C<flag>, and C<type> values as
follows. The C<args> property denotes that multiple flags are permitted and its
value can be any valid L<Getopt::Long> I<repeat> specifier. The C<type>
property denotes the type of data allowed and defaults to type I<flag>.
Allowed values are C<string>, C<integer>, C<number>, C<float>, or C<flag>. The
C<flag> property denotes the flag aliases and should be a pipe-delimited
string, e.g. C<userid|id|u>, if multiple aliases are used.

=signature spec

spec() : HashRef[HashRef]

=example-1 spec

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

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Command');

  ok $result->args;
  ok $result->opts;
  ok $result->data;
  ok $result->vars;

  my $returned = $result->main;

  like $returned, qr/usage:/;

  $result
});

$subs->example(-1, 'auto', 'method', fun($tryable) {
  local @ARGV;

  $ARGV[0] = 'init';

  ok my $result = $tryable->result;
  ok my $returned = $result->main;
  is $returned, 1234567890;

  $result->auto
});

$subs->example(-1, 'exit', 'method', fun($tryable) {
  ok !(my $result = trap { $tryable->result });
  is $trap->exit, 0;

  $result
});

$subs->example(-2, 'exit', 'method', fun($tryable) {
  ok !(my $result = trap { $tryable->result });
  is $trap->exit, 1;

  $result
});

$subs->example(-1, 'fail', 'method', fun($tryable) {
  ok !(my $result = trap { $tryable->result });
  is $trap->exit, 1;

  $result
});

$subs->example(-1, 'handle', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/usage:/;

  $result
});

$subs->example(-1, 'help', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, __FILE__;
  ok !$result->info;

  $result->help
});

$subs->example(-2, 'help', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'todolist';
  ok !$result->info;

  $result->help
});

$subs->example(-3, 'help', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'todolist';
  ok !$result->info;

  $result->help
});

$subs->example(-4, 'help', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'todolist';
  is $result->info, 'manage your todo list';

  $result->help
});

$subs->example(-5, 'help', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'todolist';
  is $result->info, 'manage your todo list';

  $result->help
});

$subs->example(-6, 'help', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->name, 'todolist show [<{priority}>]';
  is $result->info, 'show your todo list tasks by priority levels';

  my $help = $result->help;
  like $help, qr/todolist show \[\<priority\>\]/;
  is $result->args->named->{priority}, 1;

  $help
});

$subs->example(-1, 'main', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

$subs->example(-2, 'main', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->{args};
  ok $result->{args}->isa('Data::Object::Args');
  ok $result->{data};
  ok $result->{data}->isa('Data::Object::Data');
  ok $result->{opts};
  ok $result->{opts}->isa('Data::Object::Opts');
  ok $result->{vars};
  ok $result->{vars}->isa('Data::Object::Vars');

  $result
});

$subs->example(-1, 'okay', 'method', fun($tryable) {
  ok !(my $result = trap { $tryable->result });
  is $trap->exit, 0;

  $result
});

$subs->example(-1, 'run', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Todolist');

  $result
});

$subs->example(-1, 'spec', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Todolist::Task');

  my $spec = $result->spec;

  is_deeply $spec, {
    title => {
      type => 'string',
      flag => 't'
    },
    content => {
      type => 'string',
    },
    attach => {
      flag => 'a',
      args => '@'
    },
    publish => {
      flag => 'p',
      type => 'flag'
    },
    unpublish => {
      flag => 'u'
    }
  };

  my $args = $result->args;
  ok exists $args->named->{id};

  my $opts = $result->opts;
  ok exists $opts->named->{attach};
  ok exists $opts->named->{content};
  ok exists $opts->named->{publish};
  ok exists $opts->named->{title};
  ok exists $opts->named->{unpublish};

  $spec;
});

ok 1 and done_testing;
