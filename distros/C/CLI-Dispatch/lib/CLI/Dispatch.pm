package CLI::Dispatch;

use strict;
use warnings;
use Carp;
use Getopt::Long ();
use String::CamelCase;
use Try::Tiny;

our $VERSION = '0.21';

# you may want to override these three methods.

sub options {qw( help|h|? verbose|v debug logfilter=s )}

sub default_command { 'help' }

sub get_command {
  my $self = shift;

  my $command = shift @ARGV || $self->default_command;
  return $self->convert_command($command);
}

sub convert_command {
  my ($self, $command) = @_;

  $command = String::CamelCase::camelize( $command );
  $command =~ tr/a-zA-Z0-9_//cd;
  return $command;
}

# you usually don't need to care below.

sub new {
  my ($class, %opts) = @_;
  bless \%opts, $class;
}

sub get_options {
  my ($self, @specs) = @_;

  my $parser = Getopt::Long::Parser->new(
    config => [qw( bundling ignore_case pass_through )]
  );

  $parser->getoptions( \my %hash => @specs );

  return %hash;
}

sub load_command {
  my ($self, $namespaces, $help) = @_;

  my $command = $self->get_command;

  if ( $help ) {
    unshift @ARGV, $command;
    $command = 'Help';
  }

  my $instance = $self->_load_command($namespaces, $command);
  return $instance if $instance;

  # fallback to help (maybe the command is just a pod)
  unshift @ARGV, $command;
  $instance = $self->_load_command($namespaces, 'Help');
  return $instance if $instance;

  # this shouldn't happen
  print STDERR "Help command is missing or broken.\n";
  print STDERR "Prerequisite modules may not be installed.\n";
  print STDERR "Please check your installation.\n";
  exit;
}

sub _load_command {
  my ($self, $namespaces, $command) = @_;

  foreach my $namespace (@$namespaces) {
    my $package = $namespace.'::'.$command;
    return $package->new if $package->can('new');

    my $error;
    try   { eval "require $package" or die }
    catch { $error = $_ || 'Obscure error' };
    return $package->new unless $error;

    my $file = _package_file($package);
    next if $error =~ /Can't locate $file/;
    croak $error;
  }

  if ($command eq 'Help') {
    require CLI::Dispatch::Help;
    return CLI::Dispatch::Help->new;
  }
  return;
}

sub _package_file {
  my $package = shift;

  $package =~ s{::}{/}g;
  $package .= '\.(?:pm|pod)';
  $package;
}

sub run {
  my ($self, @namespaces) = @_;

  my $class;
  unless ($class = ref $self) {
    $class = $self;
    $self = $self->new;
  }

  if (!grep { $_ ne $class } @namespaces) {
    push @namespaces, $class;
  }

  my %global  = $self->get_options( $self->options );
  my $command = $self->load_command( \@namespaces, $global{help} );
  my %local   = $self->get_options( $command->options );

  $command->set_options( %$self, %global, %local, _namespaces => \@namespaces );

  if ( $command->isa('CLI::Dispatch::Help') and @ARGV ) {
    $ARGV[0] = $self->convert_command($ARGV[0]);
  }

  $command->check if $command->can('check');

  $command->run(@ARGV);
}

sub run_directly {
  my ($self, $package) = @_;

  unless ($package->can('new')) {
    my $error;
    try   { eval "require $package" or die }
    catch { $error = $_ || 'Obscure error' };
    croak $error if $error;
  }

  my $class;
  unless ($class = ref $self) {
    $class = $self;
    $self = $self->new;
  }

  my %global  = $self->get_options( $self->options );
  my $command = $package->new;
  if ($global{help}) {
    require CLI::Dispatch::Help;
    $command = CLI::Dispatch::Help->new;
    unshift @ARGV, "+$package";
  }
  my %local   = $self->get_options( $command->options );

  $command->set_options( %global, %local );

  $command->check if $command->can('check');

  $command->run(@ARGV);
}

1;

__END__

=head1 NAME

CLI::Dispatch - simple CLI dispatcher

=head1 SYNOPSIS

  * Basic usage

  In your script file (e.g. script.pl):

    #!/usr/bin/perl
    use strict;
    use lib 'lib';
    use CLI::Dispatch;
    CLI::Dispatch->run('MyScript');

  And in your "command" file (e.g. lib/MyScript/DumpMe.pm):

    package MyScript::DumpMe;
    use strict;
    use base 'CLI::Dispatch::Command';
    use Data::Dump;

    sub run {
      my ($self, @args) = @_;

      @args = $self unless @args;

      # do something
      print $self->{verbose} ? Data::Dump::dump(@args) : @args;
    }
    1;

  From the shell:

    > perl script.pl dump_me "some args" --verbose

    # will dump "some args"

  * Advanced usage

  In your script file (e.g. script.pl):

    #!/usr/bin/perl
    use strict;
    use lib 'lib';
    use MyScript;
    MyScript->run;

  And in your "dispatcher" file (e.g. lib/MyScript.pm):

    package MyScript;
    use strict;
    use base 'CLI::Dispatch';

    sub options {qw( help|h|? verbose|v stderr )}
    sub get_command { shift @ARGV || 'Help' }  # no camelization

    1;

  And in your "command" file (e.g. lib/MyScript/escape.pm):

    package MyScript::escape;
    use strict;
    use base 'CLI::Dispatch::Command';

    sub options {qw( uri )}

    sub run {
      my ($self, @args) = @_;

      if ( $self->{uri} ) {
        require URI::Escape;
        print URI::Escape::uri_escape($args[0]);
      }
      else {
        require HTML::Entities;
        print HTML::Entities::encode_entities($args[0]);
      }
    }
    1;

  From the shell:

    > perl script.pl escape "query=some string!?" --uri

    # will print a uri-escaped string

  * Lazy way

  In your script file (e.g. inline.pl):

    use strict;
    MyScript::Inline->run_directly;

    package MyScript::Inline;
    use base 'CLI::Dispatch::Command';
    sub run {
      my ($self, @args) = @_;

      # do something...
    }

  From the shell:

    > perl inline.pl -v

  * Using subcommands

  In your script file (e.g. script.pl):

    #!/usr/bin/perl
    use strict;
    use lib 'lib';
    use CLI::Dispatch;
    CLI::Dispatch->run('MyScript');

  And in your "command" file (e.g. lib/MyScript/Command.pm):

    package MyScript::Command;
    use strict;
    use CLI::Dispatch;
    use base 'CLI::Dispatch::Command';

    sub run {
      my ($self, @args) = @_;

      # create a dispatcher object configured with the same options
      # as this command
      my $dispatcher = CLI::Dispatch->new(%$self);

      $dispatcher->run('MyScript::Command');
    }

    1;

  And in your "subcommand" file (e.g. lib/MyScript/Command/Subcommand'):

    package MyScript::Command::Subcommand;
    use strict;
    use base 'CLI::Dispatch::Command';

    sub run {
      my ($self, @args) = @_;

      # do something useful
    }

    1;

  From the shell:

    > perl script.pl command subcommand "some args" --verbose

    # will do something useful


=head1 DESCRIPTION

L<CLI::Dispatch> is a simple CLI dispatcher. Basic usage is almost the same as
the one of L<App::CLI>, but you can omit a dispatcher class if you don't need
to customize. Command/class mapping is slightly different, too (ucfirst for
L<App::CLI>, and camelize for L<CLI::Dispatch>). And unlike L<App::Cmd>,
L<CLI::Dispatch> dispatcher works even when some of the subordinate commands
are broken for various reasons (unsupported OS, lack of dependencies, etc).
Those are the main reasons why I reinvent the wheel.

See L<CLI::Dispatch::Command> to know how to write an actual command class.

=head1 METHODS

=head2 run

takes optional namespaces, and parses @ARGV to load an appropriate command
class, and runs it with options that are also parsed from @ARGV. As shown in the
SYNOPSIS, you don't need to pass anything when you create a dispatcher
subclass, and vice versa.

=head2 options

specifies an array of global options every command should have. By default,
C<help> and C<verbose> (and their short forms) are registered. Command-specific
options should be placed in each command class.

=head2 default_command

specifies a default command that will run when you don't specify any command
(when you run a script without any arguments). C<help> by default.

=head2 get_command

usually looks for a command from @ARGV (after global options are parsed),
transforms it if necessary (camelize by default), and returns the result.

If you have only one command, and you don't want to specify it every time when
you run a script, let this just return the command:

  sub get_command { 'JustDoThis' }

Then, when you run the script, C<YourScript::JustDoThis> command will always be
executed (and the first argument won't be considered as a command).

=head2 convert_command

takes a command name, transforms it if necessary (camelize by default), and
returns the result. You may also want to override this to convert short aliases
for long command names.

  sub convert_command {
    my $command = shift->SUPER::convert_command(@_);
    return ($command eq 'Fcgi') ? 'FastCGI' : $command;
  }

=head2 get_options

takes an array of option specifications and returns a hash of parsed options.
See L<Getopt::Long> for option specifications.

=head2 load_command

takes a namespace, and a flag to tell if the C<help> option is set or not, and
loads an appropriate command class to return its instance.

=head2 run_directly

takes a fully qualified package name, and loads it if necessary, and run it with
options parsed from @ARGV. This is mainly used to run a command directly (without
configuring a dispatcher), which makes writing a simple command easier. You usually
don't need to use this directly. This is called internally when you run a command
(based on L<CLI::Dispatch::Command>) directly, without instantiation.

=head2 new (since 0.17)

creates a dispatcher object. You usually don't need to use this
(because CLI::Dispatch creates this internally). If you need to copy
options from a command to its subcommand, this may help.

=head1 SEE ALSO

L<App::CLI>, L<App::Cmd>, L<Getopt::Long>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
