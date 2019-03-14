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

=head2 args

  args() : ArrayRef

The args method returns the ordered arguments passed to the constructor or cli.

=over 4

=item args example

  # given $cli

  $cli->args;

=back

=cut

=head2 env

  env() : HashRef

The env method returns the environment variables in the running process.

=over 4

=item env example

  # given $cli

  $cli->env;

=back

=cut

=head2 main

  main(HashRef :$env, ArrayRef :$args, HashRef :$opts) : Any

The main method is (by convention) the starting point for an automatically
executed subclass, i.e. this method is run by default if the subclass is run as
a script. This method should be overriden by the subclass. This method is
called with the named arguments C<env>, C<args> and C<opts>.

=over 4

=item main example

  # given $cli

  $cli->main(%args);

=back

=cut

=head2 opts

  opts() : HashRef

The opts method returns the parsed options passed to the constructor or cli,
based on the specifications defined in the specs method.

=over 4

=item opts example

  # given $cli

  $cli->opts;

=back

=cut

=head2 parse

  parse(ArrayRef $arg1, ArrayRef $arg2, ArrayRef $arg3) : HashRef

The parse method parses command-line options using L<Getopt::Long> and does not
mutate C<@ARGV>. The first argument should be an arrayref containing the data
to be parsed; E.g. C<[@ARGV]>. The second argument should be an arrayref of
Getopt::Long option specifications. The third argument (optionally) should be
additional options to be passed along to
L<Getopt::Long::Configure|Getopt::Long/Configuring-Getopt::Long>.

=over 4

=item parse example

  # given $cli

  $cli->parse($data, $specs, $meta);

=back

=cut

=head2 run

  run() : Any

The run method automatically executes the subclass unless it's being imported
by another package.

=over 4

=item run example

  # given $cli

  $cli->run;

=back

=cut

=head2 specs

  specs() : (Str)

The specs method (if present) returns a list of L<Getopt::Long> option
specifications. This method should be overriden by the subclass.

=over 4

=item specs example

  # given $cli

  $cli->specs;

=back

=cut
