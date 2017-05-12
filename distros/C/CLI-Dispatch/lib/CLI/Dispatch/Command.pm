package CLI::Dispatch::Command;

use strict;
use warnings;

sub new {
  my $class = shift;
  my $self  = bless {}, $class;
  $self->set_options(@_) if @_;

  if (!$self->can('log')) {
    require Log::Dump; Log::Dump->import;
  }

  $self;
}

sub set_options {
  my $self = shift;

  my %args = @_;
  for (keys %args) {
      die "override $_ by a command argument" if defined $self->{$_};
      $self->{$_} = $args{$_};
  }

  if ($self->can('logger')) {
    $self->logger( $self->{verbose} || $self->{debug} || $self->{logfilter} ? 1 : 0 );
  }
  if ($self->can('logfilter')) {
    my @filters = $self->{logfilter} ? split ',', $self->{logfilter} : ();
    push @filters, '!debug' unless $self->{debug};
    $self->logfilter(@filters);
  }

  $self;
}

sub options { return () }

sub option {
  my ($self, $name) = @_;

  defined $self->{$name} ? $self->{$name} : '';
}

sub run {
  my ($self, @args) = @_;

  return;
}

sub run_directly {
  my $self = shift;
  my $class = ref $self || $self;
  require CLI::Dispatch;
  CLI::Dispatch->run_directly($class);
}

sub usage {
  my ($self, $no_print) = @_;

  my $class = ref $self;
  $class =~ s{::}{/}g;
  $class .= '.pm';

  my $file = $INC{$class} || $0 or return;
  my $content = do { local $/; open my $fh, '<', $file; <$fh> };

  require CLI::Dispatch::Help;
  my $help = CLI::Dispatch::Help->new(%$self);

  my $pod = $help->_parse_pod($content);
  $pod = $help->extract_pod_body($pod);

  $pod =~ /^(\S+\s+.+?)\n(?=\S)/s; # extract first paragraph
  $help->output( $1 || '', $no_print );
}

1;

__END__

=head1 NAME

CLI::Dispatch::Command

=head1 SYNOPSIS

    package MyScript::Convert;

    use strict;
    use base 'CLI::Dispatch::Command';
    use Encode;

    sub options {qw( from=s to=s )}

    sub run {
      my ($self, @args) = @_;

      die $self->usage(1) unless @args;

      # this message will be printed when "verbose" option is set
      $self->log( info => 'going to convert encoding' );

      # debug message will be printed only when "debug" option is set
      $self->log( debug => 'going to convert encoding' );

      my $decoded = decode( $self->option('from'), $args[0] );
      print encode( $self->option('to'), $decoded );
    }

    1;

    __END__

    =head1 NAME

    MyScript::Convert - this will be shown in a command list

    =head1 SYNOPSIS

    the following will be shown when you run the script
    with a "help" option/command.

=head1 DESCRIPTION

L<CLI::Dispatch::Command> is a base class for an actual command. Basically, all
you need to do is override the C<run> method to let it do what you want, and
optionally override the C<options> method to provide option specifications for
the command. Also, you are expected to write a decent pod for the command,
which will be shown when you run a script with C<help> option/command, or when
you run it without any command.

=head1 METHODS

=head2 run

this is where you are expected to write what you want the command to do.

=head2 options

this is where you are expected to write an array of command-specific option
specifications.

=head2 option

is a read-only accessor to the option of the name (returns an empty string if
the option is not defined).

=head2 log, logger, logfile, logfilter

L<CLI::Dispatch> uses L<Log::Dump> as a logger, and the logger is enabled when
the C<verbose> option is set.

C<log> takes a label and arbitrary messages (strings, references and objects),
and dumps them to stderr by default.

  $self->log( label => @messages );

If you want to dump to a file, pass the file name to C<logfile>, and if you
want to dump only messages with selected labels, use C<logfilter>.

See L<Log::Dump> for detailed instrution.

If you want to use other loggers, write your own C<log> method, and L<Log::Dump>
will not be loaded (since 0.15).

=head2 check (since 0.05)

will be executed before C<run>, mainly to see if the command is really
available for the user. If the command happens to die there, the dying message
will also be shown in the commands list.

    package MyScript::UnportableCommand;

    use strict;
    use base 'CLI::Dispatch::Command';

    sub check {
      my $self = shift;

      eval "require Module::For::Unix::Only";
      die "Unsupported OS" if $@;  # for a better message in the list
    }

    sub run { ... }

=head2 usage (since 0.07)

will print the first section of the pod for the command. If you pass a true value as the first argument, it just returns the usage text instead without printing.

=head2 run_directly (since 0.09)

loads L<CLI::Dispatch> to dispatch directly back to the command. This is handy if you prefer writing a set of independent scripts to writing one dispatcher script. 

=head2 new

creates a command object. It may take a hash of options.

=head2 set_options

takes a hash of options from the dispatcher, and set them into the command
object.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
