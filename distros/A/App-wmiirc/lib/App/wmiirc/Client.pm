package App::wmiirc::Client;
{
  $App::wmiirc::Client::VERSION = '1.000';
}
# ABSTRACT: Keep track of clients
use App::wmiirc::Plugin;
with 'App::wmiirc::Role::Key';

has clients => (
  is => 'ro',
  default => sub { {} },
);

has previous_id => (
  is => 'rw'
);

sub BUILD {
  my($self) = @_;

  for my $id(wmiir "/client/") {
    $id =~ s{/$}{};
    next if $id eq 'sel';
    $self->event_create_client($id);
  }
}

sub event_create_client {
  my($self, $id) = @_;
  my $props = wmiir "/client/$id/props";
  return unless $props;
  $self->clients->{$id} = [split /:/, $props, 3];
}

sub event_client_focus {
  my($self, $id) = @_;
  my $previous_id = $self->previous_id;
  if($self->previous_id && (my $props = wmiir "/client/$previous_id/props")) {
    @{$self->clients->{$previous_id}}[0..2] = split /:/, $props, 3;
  }
  $self->previous_id($id);
}

sub key_list_clients(Modkey-slash) {
  my($self) = @_;
  my @clients = map $self->clients->{$_}[2] . " ($_)",
    grep defined $self->clients->{$_}[2], keys $self->clients;

  # TODO: Stop showing the ID to the user somehow? Modify -S?
  if(my $win = wimenu @clients) {
    my($c) = $win =~ /\((0x[0-9a-f]+)\)$/;
    if($c) {
      my($tags) = wmiir "/client/$c/tags";
      if($tags) {
        wmiir "/ctl", "view $tags";
        wmiir "/tag/sel/ctl", "select client $c";
      }
    }
  }
}


sub event_shell_window_pid {
  my($self, $id, $pid) = @_;
  $self->clients->{$id}[3] = $pid;
}

sub event_destroy_client {
  my($self, $id) = @_;
  $self->previous_id(undef) if $self->previous_id && $self->previous_id eq $id;
  delete $self->clients->{$id};
}

# TODO: Fix SIGCHLD handling -- think about using IO::Async properly
# TODO: Maybe also a util function for running commands as it's done everywhere

sub key_terminal_here(Modkey-Control-Return) {
  my($self) = @_;

  my($cur_id) = wmiir "/client/sel/ctl";
  my $pid = $self->clients->{$cur_id // ""}[3] || $$;
  my $fork = fork;
  return if $fork || not defined $fork;
  if(-d "/proc/$pid/cwd") {
    chdir "/proc/$pid/cwd";
  } else {
    # No /proc, try lsof
    my($dir) = `lsof -p $pid -a -d cwd -a -u $ENV{USER} -Fn` =~ /^n(.*)/m;
    chdir $dir if $dir;
  }
  exec $self->core->main_config->{terminal};
  no warnings 'exec';
  warn "Exec failed: $?";
  exit 1;
}

sub key_goto_regex {
  my($self, $regex) = @_;

  for my $c(keys %{$self->clients}) {
    my $cl = $self->clients->{$c};
    # TODO: use lsof here for portability
    if(($cl->[3] && `ps --ppid=$cl->[3] ho cmd` =~ $regex)
      || ($cl->[0] && $cl->[0] =~ $regex)
      || ($cl->[2] && $cl->[2] =~ $regex)) {
      # TODO: multiple tag support
      my($tags) = wmiir "/client/$c/tags";
      wmiir "/ctl", "view $tags";
      wmiir "/tag/sel/ctl", "select client $c";
      last;
    }
  }
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Client - Keep track of clients

=head1 VERSION

version 1.000

=begin zshrc




=end zshrc

if [[ -n $WMII_CONFPATH ]]; then
  wmiir xwrite /event ShellWindowPid $(printf "0x%x" $WINDOWID) $$
fi

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

