package Data::Object::Cli;

use Getopt::Long ();

use Data::Object::Class;

use parent 'Data::Object::Kind';

# BUILD

sub BUILD {
  my ($self, $data) = @_;

  my @attrs = qw(env args opts);

  for my $attr (grep { defined $data->{$_} } @attrs) {
    $self->{$attr} = $data->{$attr};
  }

  unless (defined $self->{env}) {
    $self->{env} = \%ENV;
  }

  unless (defined $self->{args}) {
    $self->{args} = \@ARGV;
  }

  unless (defined $self->{opts}) {
    $self->{opts} = parse($self->{args}, [$self->specs()]);
  }

  # (optionally) use getopts primary-name for attributes
  for my $name (map +((split(/\|/, $_, 2))[0]), $self->specs()) {
    $self->{$name} = $self->{opts}{$name} if defined $self->{opts}{$name};
  }

  return $self;
}

# METHODS

sub env {
  my ($self) = @_;

  return $self->{env};
}

sub args {
  my ($self) = @_;

  return $self->{args};
}

sub opts {
  my ($self) = @_;

  return $self->{opts};
}

sub run {
  my ($class, @args) = @_;

  unless (caller(1)) {
    my $self = $class->new(@args);

    $self->main(env => $self->env, args => $self->args, opts => $self->opts);
  }

  return time;
}

sub parse {
  my ($data, $specs, $opts) = @_;

  my $vars = {};

  my @config = qw(
    default
    no_auto_abbrev
    no_ignore_case
  );

  $opts = [] if !$opts;

  Getopt::Long::GetOptionsFromArray($data, $vars, @$specs);
  Getopt::Long::Configure(Getopt::Long::Configure(@config, @$opts));

  return $vars;
}

sub main {
  return;
}

sub specs {
  return;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Cli

=cut

=head1 ABSTRACT

Data-Object Cli Class

=cut

=head1 SYNOPSIS

  package Cli;

  use Data::Object::Class;

  extends 'Data::Object::Cli';

  method main(:$args) {
    # do something with $args, $opts, $env
  }

  run Cli;

=cut

=head1 DESCRIPTION

Data::Object::Cli provides an abstract base class for defining command-line
interface classes, which can be run as scripts or passed as objects in a more
complex system.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 env

  # given $cli

  $cli->env;

The env method returns the environment variables in the running process.

=cut

=head2 args

  # given $cli

  $cli->args;

The args method returns the ordered arguments passed to the constructor or cli.

=cut

=head2 opts

  # given $cli

  $cli->opts;

The opts method returns the parsed options passed to the constructor or cli,
based on the specifications defined in the specs method.

=cut

=head2 run

  # given $cli

  $cli->run;

The run method automatically executes the subclass unless it's being imported
by another package.

=cut

=head2 parse

  # given $cli

  $cli->parse($data, $specs, $meta);

The parse method parses command-line options using L<Getopt::Long> and does not
mutate C<@ARGV>. The first argument should be an arrayref containing the data
to be parsed; E.g. C<[@ARGV]>. The second argument should be an arrayref of
Getopt::Long option specifications. The third argument (optionally) should be
additional options to be passed along to
L<Getopt::Long::Configure|Getopt::Long/Configuring-Getopt::Long>.

=cut

=head2 main

  # given $cli

  $cli->main(%args);

The main method is (by convention) the starting point for an automatically
executed subclass, i.e. this method is run by default if the subclass is run as
a script. This method should be overriden by the subclass. This method is
called with the named arguments C<env>, C<args> and C<opts>.

=cut

=head2 specs

  # given $cli

  $cli->specs;

The specs method (if present) returns a list of L<Getopt::Long> option
specifications. This method should be overriden by the subclass.

=cut
