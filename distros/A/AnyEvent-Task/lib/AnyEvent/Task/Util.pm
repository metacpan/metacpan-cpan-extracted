package AnyEvent::Task::Util;

use common::sense;

use AnyEvent::Util;


our @children_sockets;

sub fork_anyevent_subprocess {
  my ($code, %args) = @_;

  my ($socka, $sockb) = AnyEvent::Util::portable_socketpair;

  die "No AnyEvent watchers should be created prior to forking (AE model: $AnyEvent::MODEL)" if defined $AnyEvent::MODEL;
  my $pid = fork;

  die "couldn't fork: $!" if !defined $pid;

  if (!$pid) {
    close($socka);

    AnyEvent::Util::close_all_fds_except 0, 1, 2, fileno($sockb), @{$args{dont_close_fds}};

    ## If parent closes its side of the socket we should exit
    my $watcher = AE::io $sockb, 0, sub { exit };

    $code->();

    die "AnyEvent::Task::Server->run should never return";
  }

  close $sockb;

  return ($socka, $pid) if wantarray;

  push @children_sockets, $socka; # keep reference alive
  return;
}



1;
