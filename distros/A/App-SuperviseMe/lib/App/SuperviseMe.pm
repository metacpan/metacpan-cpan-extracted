package App::SuperviseMe;

# ABSTRACT: very simple command superviser
our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:MELO'; # AUTHORITY

use strict;
use warnings;
use Carp 'croak';
use AnyEvent;

##############
# Constructors

sub new {
  my ($class, %args) = @_;

  my $cmds = delete($args{cmds}) || [];
  $cmds = [$cmds] unless ref($cmds) eq 'ARRAY';
  for my $cmd (@$cmds) {
    $cmd = [$cmd] unless ref($cmd) eq 'ARRAY';
    $cmd = { cmd => $cmd };
  }

  croak(q{Missing 'cmds',}) unless @$cmds;

  return bless {
    cmds  => $cmds,
    debug => $ENV{SUPERVISE_ME_DEBUG} || $args{debug} || 0,
    progress => $args{progress} || 0,
  }, $class;
}

sub new_from_options {
  my ($class) = @_;

  _out('Enter commands to supervise, one per line');

  my @cmds;
  while (my $l = <STDIN>) {
    chomp $l;
    $l =~ s/^\s+|\s+$//g;
    next unless $l;
    next if $l =~ /^#/;

    push @cmds, $l;
  }

  return $class->new(cmds => \@cmds);
}


################
# Start the show

sub run {
  my $self = shift;
  my $sv   = AE::cv;

  my $int_s = AE::signal 'INT' => sub { $self->_signal_all_cmds('INT', $sv); };
  my $term_s = AE::signal 'TERM' => sub { $self->_signal_all_cmds('TERM'); $sv->send };

  for my $cmd (@{ $self->{cmds} }) {
    $self->_start_cmd($cmd);
  }

  $sv->recv;
}


##########
# Magic...

sub _start_cmd {
  my ($self, $cmd) = @_;
  $self->_progress("Starting '@{$cmd->{cmd}}'");

  my $pid = fork();
  if (!defined $pid) {
    $self->_error("fork() failed: $!");
    $self->_restart_cmd($cmd);
    return;
  }

  if ($pid == 0) {    ## Child
    $cmd = $cmd->{cmd};
    $self->_debug("Exec'ing '@$cmd'");
    exec(@$cmd);
    exit(1);
  }

  ## parent
  $self->_debug("Watching pid $pid for '@{$cmd->{cmd}}'");
  $cmd->{pid} = $pid;
  $cmd->{watcher} = AE::child $pid, sub { $self->_child_exited($cmd, @_) };

  return;
}

sub _child_exited {
  my ($self, $cmd, undef, $status) = @_;
  $self->_debug("Child $cmd->{pid} exited, status $status: '@{$cmd->{cmd}}'");

  delete $cmd->{watcher};
  delete $cmd->{pid};

  $cmd->{last_status} = $status >> 8;

  $self->_restart_cmd($cmd);
}

sub _restart_cmd {
  my ($self, $cmd) = @_;
  $self->_progress("Restarting cmd '@{$cmd->{cmd}}' in 1 second");

  my $t;
  $t = AE::timer 1, 0, sub { $self->_start_cmd($cmd); undef $t };
}

sub _signal_all_cmds {
  my ($self, $signal, $cv) = @_;
  $self->_debug("Received signal $signal");
  my $is_any_alive = 0;
  for my $cmd (@{ $self->{cmds} }) {
    next unless my $pid = $cmd->{pid};
    $self->_debug("... sent signal $signal to $pid");
    $is_any_alive++;
    kill($signal, $pid);
  }

  return if $cv and $is_any_alive;

  $self->_progress('Exiting...');
  $cv->send if $cv;
}


#########
# Loggers

sub _out {
  return unless -t \*STDOUT && -t \*STDIN;

  print @_, "\n";
}

sub _progress {
  my $self = shift;
  return unless $self->{progress};

  print @_, "\n";
  $self->_debug('progress msg: ', @_);
}

sub _debug {
  my $self = shift;
  return unless $self->{debug};

  print STDERR "DEBUG [$$] ", @_, "\n";
}

sub _error {
  shift;
  print "ERROR: ", @_, "\n";
  return;
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Pedro Melo ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

App::SuperviseMe - very simple command superviser

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    my $superviser = App::SuperviseMe->new(
        cmds => [
          'plackup -p 3010 ./sites/x/app.psgi',
          'plackup -p 3011 ./sites/y/app.psgi',
          ['bash', '-c', '... bash script ...'],
        ],
    );
    $superviser->run;

=head1 DESCRIPTION

This module implements a multi-process supervisor.

It takes a list of commands to execute and starts each one, and then monitors
their execution. If one of the program dies, the supervisor will restart it
after a small 1 second pause.

You can send SIGTERM to the supervisor process to kill all childs and exit.

You can also send SIGINT (Ctrl-C on your terminal) to restart the processes. If
a second SIGINT is received and no child process is currently running, the
supervisor will exit. This allows you to tap Ctrl- C twice in quick succession
in a terminal window to terminate the supervisor and all child processes

=encoding utf8

=head1 METHODS

=head2 new

    my $supervisor = App::SuperviseMe->new( cmds => [...], [debug => ...]);

Creates a supervisor instance with a list of commands to monitor.

It accepts a hash with the following options:

=over 4

=item cmds

A list reference with the commands to execute and monitor. Each command can be
a scalar, or a list reference.

=item progress

Print progress information if true. Disabled by default.

=item debug

Print debug information if true. ENV SUPERVISE_ME_DEBUG overrides this setting. Disabled by default.

=back

=head2 new_from_options

    my $supervisor = App::SuperviseMe->new_from_options;

Reads the list of commands to start and monitor from C<STDIN>. It strips
white-space from the beggining and end of the line, and skips lines that start
with a C<#>.

Returns the superviser object.

=head2 run

    $supervisor->run;

Starts the supervisor, start all the child processes and monitors each one.

This method returns when the supervisor is stopped with either a SIGINT or a
SIGTERM.

=head1 SEE ALSO

L<AnyEvent>

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::SuperviseMe

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/App-SuperviseMe>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-SuperviseMe>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-SuperviseMe>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::SuperviseMe>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-SuperviseMe>

=back

=head2 Email

You can email the author of this module at C<MELO at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at L<https://github.com/melo/App-SuperviseMe/issues>. You will be automatically notified of any progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/melo/App-SuperviseMe>

  git clone git://github.com/melo/App-SuperviseMe.git

=head1 AUTHOR

Pedro Melo <melo@simplicidade.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
