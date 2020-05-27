package Data::Object::Cli;

use 5.014;

use strict;
use warnings;

use feature 'say';

use registry 'Data::Object::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

use Data::Object::Args;
use Data::Object::Data;
use Data::Object::Opts;
use Data::Object::Vars;

our $VERSION = '2.03'; # VERSION

our $DEFAULT_SPACE = 15;

# ATTRIBUTES

has 'args' => (
  is => 'ro',
  isa => 'ArgsObject',
  new => 1,
);

fun new_args($self) {
  Data::Object::Args->new($self->_args_spec)
}

has 'data' => (
  is => 'ro',
  isa => 'DataObject',
  new => 1,
);

fun new_data($self) {
  Data::Object::Data->new(from => ref $self)
}

has 'opts' => (
  is => 'ro',
  isa => 'OptsObject',
  new => 1,
);

fun new_opts($self) {
  Data::Object::Opts->new($self->_opts_spec)
}

has 'vars' => (
  is => 'ro',
  isa => 'VarsObject',
  new => 1,
);

fun new_vars($self) {
  Data::Object::Vars->new
}

# METHODS

sub auto {
  {}
}

sub main {
  my ($self) = shift;

  my $result;

  my $auto = $self->handle('auto');
  my $command = $self->args->command || $ARGV[0];
  my $goto = $auto->{$command} if $auto && $command;

  if ($goto) {
    $result = $self->handle($goto);
  }
  else {
    say $self->help;
  }

  return $result;
}

sub subs {
  {}
}

method exit($code, $handler, @args) {

  $self->handle($handler, @args) if $handler;

  $code ||= 0;

  exit $code;
}

method fail($handler, @args) {

  return $self->exit(1, $handler, @args);
}

method handle($method, %args) {

  my %meta;

  $meta{args} = $self->args;
  $meta{data} = $self->data;
  $meta{opts} = $self->opts;
  $meta{vars} = $self->vars;

  return $self->$method(%meta, %args);
}

method help() {

  my $space = Data::Object::Space->new(ref $self);

  my $name = $self->name =~ s/\{(\w+)\}/$1/gr;
  my $info = $self->info;
  my $subs = $self->_help_subs;
  my $opts = $self->_help_opts;

  my $data;

  if ($data =  $space->data) {
    if ($name && $data =~ /\{name\}/) {
      $data =~ s/\{name\}/$name/g;
    }

    if ($info && $data =~ /\{info\}/) {
      $data =~ s/\{info\}/$info/g;
    }

    if ($subs && $data =~ /\{subs\}/) {
      $data =~ s/\{subs\}/$subs/g;
    }

    if ($opts && $data =~ /\{opts\}/) {
      $data =~ s/\{opts\}/$opts/g;
    }

    if ($subs && $data =~ /\{commands\}/) {
      $data =~ s/\{commands\}/$subs/g;
    }

    if ($opts && $data =~ /\{options\}/) {
      $data =~ s/\{options\}/$opts/g;
    }

    $data =~ s/^\n//;
  }
  else {
    my @help;

    push @help, "usage: $name", "";
    push @help, $info, "" if $info;
    push @help, $subs, "" if $subs;
    push @help, $opts, "" if $opts;

    $data = join "\n", @help;
  }

  return $data;
}

method info() {

  my $class = ref $self;

  do { no strict 'refs'; ${"${class}::info"} };
}

method name() {

  my $class = ref $self;

  do { no strict 'refs'; ${"${class}::name"} } || $0;
}

method okay($handler, @args) {

  return $self->exit(0, $handler, @args);
}

method run($class: @args) {

  my $self = $class->new(@args);

  return $self->handle('main') unless caller(1);

  return $self;
}

method spec() {
  {}
}

method _args_spec() {

  my $args_spec = {named => {}};

  my $name = $self->name;
  my @args = split /\s+/, $name;

  shift @args;

  return $args_spec if !@args;

  for (my $i=0; $i < @args; $i++) {
    if (my ($token) = $args[$i] =~ /\{(\w+)\}/) {
      $args_spec->{named}{$token} = "$i";
    }
  }

  return $args_spec;
}

method _help_opts() {

  my $spec = $self->spec;
  my $size = $DEFAULT_SPACE;

  my @opts;

  for my $name (keys %$spec) {
    my %seen;

    my $data = $spec->{$name};

    my $args = $data->{args};
    my $desc = $data->{desc};
    my $flag = $data->{flag} || $name;
    my $type = $data->{type};

    my $text = join ',',
      map {length > 1 ? "--$_" : "-$_"}
      grep !$seen{$_}++, sort $name, split /\|/, $flag;

    $text = "${text}, +1" if defined $args;
    $size = length $text if length $text > $size;

    push @opts, [$text, "[$type] $desc"];
  }

  @opts = sort {$a->[0]  cmp $b->[0]} @opts;

  return join "\n", map {sprintf "  %-*s  %s", $size, @$_} @opts;
}

method _help_subs() {

  my $spec = $self->subs;
  my $size = $DEFAULT_SPACE;

  my @opts;

  for my $name (sort keys %$spec) {
    my $text = $spec->{$name};

    $size = length $name if length $name > $size;

    push @opts, [$name, $text];
  }

  return join "\n", map {sprintf "  %-*s  %s", $size, @$_} @opts;
}

method _opts_spec() {

  my $opts_spec = {spec => []};

  my $spec = $self->spec;

  for my $name (keys %$spec) {
    my %seen;

    my $data = $spec->{$name};

    my $args = $data->{args};
    my $flag = $data->{flag} || $name;
    my $type = $data->{type} || 'flag';

    my $code = {
      float   => 'f',
      integer => 'i',
      number  => 'o',
      string  => 's',
    };

    $code = $code->{$type};

    my @flags = grep !$seen{$_}++, reverse sort $name, split /\|/, $flag;

    $opts_spec->{named}{$name} = $flags[0];

    $flag = join '|', @flags;

    push @{$opts_spec->{spec}}, sprintf '%s%s%s', $flag, ($code ? "=$code" : ''), $args || '';
  }

  return $opts_spec;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Cli - Simple CLIs

=cut

=head1 ABSTRACT

Command-line Interface Abstraction for Perl 5

=cut

=head1 SYNOPSIS

  package Command;

  use parent 'Data::Object::Cli';

  sub main {
    my ($self) = @_;

    return $self->help;
  }

  my $command = run Command;

=cut

=head1 DESCRIPTION

This package provides an abstract base class for defining command-line
interface classes, which can be run as scripts or passed as objects in a more
complex system.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 args

  args(ArgsObject)

This attribute is read-only, accepts C<(ArgsObject)> values, and is optional.

=cut

=head2 data

  data(DataObject)

This attribute is read-only, accepts C<(DataObject)> values, and is optional.

=cut

=head2 opts

  opts(OptsObject)

This attribute is read-only, accepts C<(OptsObject)> values, and is optional.

=cut

=head2 vars

  vars(VarsObject)

This attribute is read-only, accepts C<(VarsObject)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 auto

  auto(Any %args) : HashRef

The auto method is expected to be overridden by the subclass and should return
a hashref where the keys represent a subcommand at C<$ARGV[0]> and the value
represents the subroutine to be dispatched to using the C<handle> method. To
enable this functionality, the command name be declare a "command" token.

=over 4

=item auto example #1

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

=back

=cut

=head2 exit

  exit(Int $code, Maybe[Str] $name, Any %args) : Any

The exit method exits the program using the exit code provided. The exit code
defaults to C<0>. Optionally, you can call a handler before exiting by
providing a method name with arguments. The handler will be called using the
C<handle> method so the arguments should be key/value pairs.

=over 4

=item exit example #1

  # given: synopsis

  $command->exit(0);

  # $command->exit($code, $method_name, %args);
  # $command->exit($code, $method_name);
  # $command->exit($code);

=back

=over 4

=item exit example #2

  # given: synopsis

  $command->exit(1);

  # $command->exit($code, $method_name, %args);
  # $command->exit($code, $method_name);
  # $command->exit($code);

=back

=cut

=head2 fail

  fail(Maybe[Str] $name, Any %args) : Any

The fail method exits the program with a C<1> exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the C<handle> method so the arguments should be
key/value pairs.

=over 4

=item fail example #1

  # given: synopsis

  $command->fail;

  # $command->fail($method_name, %args);
  # $command->fail($method_name);

=back

=cut

=head2 handle

  handle(Str $name, Any %args) : Any

The handle method dispatches to the method whose name is provided as the first
argument. The forwarded method will receive arguments as key/value pairs. This
method injects the C<args>, C<data>, C<vars>, and C<opts> attributes as
arguments for convenience of use in the forwarded method. Any additional
arguments should be passed as key/value pairs.

=over 4

=item handle example #1

  # given: synopsis

  $command->handle('main');

  # $command->handle($method_name, %args);
  # $command->handle($method_name);

=back

=cut

=head2 help

  help() : Str

The help method returns the help text documented in POD if available.

=over 4

=item help example #1

  package Todolist;

  use parent 'Data::Object::Cli';

  my $todolist = run Todolist;

  # $todolist->help

=back

=over 4

=item help example #2

  package Todolist;

  use parent 'Data::Object::Cli';

  our $name = 'todolist';

  my $todolist = run Todolist;

  # $todolist->help

=back

=over 4

=item help example #3

  package Todolist;

  use parent 'Data::Object::Cli';

  sub name {
    'todolist'
  }

  my $todolist = run Todolist;

  # $todolist->help

=back

=over 4

=item help example #4

  package Todolist;

  use parent 'Data::Object::Cli';

  our $name = 'todolist';
  our $info = 'manage your todo list';

  my $todolist = run Todolist;

  # $todolist->help

=back

=over 4

=item help example #5

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

=back

=over 4

=item help example #6

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

=back

=cut

=head2 main

  main(Any %args) : Any

The main method is the "main method" and entrypoint into the program. It's
called automatically by the C<run> method if your package is configured as
recommended. This method accepts arguments as key/value pairs, and if called
by C<run> will receive the C<args>, C<data>, C<opts>, and C<vars> objects.

=over 4

=item main example #1

  package Todolist;

  use parent 'Data::Object::Cli';

  sub main {
    my ($self, %args) = @_;

    return {%args} # no args
  }

  my $todolist = run Todolist;

  $todolist->main;

=back

=over 4

=item main example #2

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

=back

=cut

=head2 okay

  okay(Maybe[Str] $name, Any %args) : Any

The okay method exits the program with a C<0> exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the C<handle> method so the arguments should be
key/value pairs.

=over 4

=item okay example #1

  # given: synopsis

  $command->okay;

  # $command->okay($method_name, %args);
  # $command->okay($method_name);

=back

=cut

=head2 run

  run() : Object

The run method is designed to bootstrap the program. It detects whether the
package is being invoked as a script or class and behaves accordingly. It will
be called automatically when the package is looaded if your package is
configured as recommended. This method will, if invoked as a script, call the
main method passing the C<args>, C<data>, C<opts>, and C<vars> objects.

=over 4

=item run example #1

  package Todolist;

  use parent 'Data::Object::Cli';

  run Todolist;

=back

=cut

=head2 spec

  spec() : HashRef[HashRef]

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

=over 4

=item spec example #1

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

=back

=cut

=head2 subs

  subs(Any %args) : HashRef

The subs method works in tandem with the L</auto> method and is expected to be
overridden by the subclass and should return a hashref where the keys represent
a subcommand at C<$ARGV[0]> and the value represents the description of the
corresponding action (i.e. I<command>).

=over 4

=item subs example #1

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

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-cli/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-cli/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-cli>

L<Initiatives|https://github.com/iamalnewkirk/data-object-cli/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-cli/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-cli/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-cli/issues>

=cut
