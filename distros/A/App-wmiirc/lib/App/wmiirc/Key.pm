package App::wmiirc::Key;
{
  $App::wmiirc::Key::VERSION = '1.000';
}
# ABSTRACT: Handle keys
use App::wmiirc::Plugin;
use Data::Dump qw(dump);
use IO::Async::Process;

{
  # Load external actions
  my $conf_dir = (split /:/, $ENV{WMII_CONFPATH})[0];
  for my $external(map s{.*/}{}r, grep -x $_, <$conf_dir/*>) {
    next if $external eq 'wmiirc';

    no strict 'refs';
    *{"action_$external"} = sub {
      my($self, @args) = @_;
      # FIXME, quoting
      system "$conf_dir/$external @args &";
    }
  }
}

with 'App::wmiirc::Role::Key';
with 'App::wmiirc::Role::Action';

sub BUILD {
  my($self) = @_;
  $self->action_rehash;
}

sub event_key {
  my($self, $key) = @_;

  if(exists $self->core->{keys}{$key}) {
    $self->core->{keys}{$key}->();
  }
}

sub key_select(Modkey-DIR) {
  my(undef, $dir) = @_;
  wmiir "/tag/sel/ctl", "select $dir";
}

sub key_select_move(Modkey-Shift-DIR) {
  my(undef, $dir) = @_;
  wmiir "/tag/sel/ctl", "send sel $dir";
}

sub key_floating(Modkey-space) {
  wmiir "/tag/sel/ctl", "select toggle";
}

sub key_floating_toggle(Modkey-Shift-space) {
  wmiir "/tag/sel/ctl", "send sel toggle";
}

sub key_colmode_default(Modkey-d) {
  wmiir "/tag/sel/ctl", "colmode sel default-max";
}

sub key_colmode_stack(Modkey-s) {
  wmiir "/tag/sel/ctl", "colmode sel stack-max";
}

sub key_colmode_max(Modkey-m) {
  wmiir "/tag/sel/ctl", "colmode sel stack+max";
}

sub key_fullscreen(Modkey-f) {
  wmiir "/client/sel/ctl", "fullscreen toggle";
}

sub key_terminal(Modkey-Return) {
  my($self) = @_;
  system "wmiir setsid " . $self->core->main_config->{terminal} . "&";
}

sub key_close(Modkey-Shift-c) {
  my($self) = @_;
  wmiir "/client/sel/ctl", "kill";
}

sub key_action(Modkey-a) {
  my($self) = @_;
  my($action, @args) = split / /,
    wimenu { name => "action:", history => "actions" },
      sort grep !/^default$/, keys $self->core->{actions};

  if($action) {
    if(exists $self->core->{actions}{$action}) {
      $self->core->{actions}{$action}->(@args);
    } elsif(exists $self->core->{actions}{default}) {
      $self->core->{actions}{default}->($action, @args);
    }
  }
}

my @progs;

sub key_run(Modkey-p) {
  my($self) = @_;
  if(!@progs) {
    $self->action_rehash(sub { $self->key_run });
    return;
  }

  if(my $run = wimenu { name => "run:", history => "progs" }, \@progs) {
    system "$run &";
  }
}

sub action_rehash {
  my($self, $finish) = @_;

  my @new_progs;
  $self->core->loop->add(IO::Async::Process->new(
    command => ['wmiir', 'proglist', split /:/, $ENV{PATH}],
    stdout => {
      on_read => sub {
        my($stream, $buffref) = @_;
        while($$buffref =~ s/^(.*)\n//) {
          push @new_progs, $1;
        }
      }
    },
    on_finish => sub {
      my %uniq_progs = map +($_, 1), @new_progs;
      @progs = sort keys %uniq_progs;
      $finish->() if $finish && ref $finish eq 'CODE';
    }
  ));
}

sub action_wmiirc {
  my($self, $cmd) = @_;
  exec $cmd || ($^X, $0);
}

sub action_quit {
  wmiir "/ctl", "quit";
  exit 0;
}

sub action_eval {
  my($self, @eval) = @_;
  # This is fugly.
  my $x;
  if(eval "\$x = do { @eval }; 1") {
    $self->core->dispatch("event_notice", dump $x);
  } else {
    $self->core->dispatch("event_msg", $@);
  }
}

sub action_env {
  my($self, $param, $value) = @_;
  if(!$param) {
    system 'export | xmessage -file -&';
  } elsif(!$value) {
    $self->core->dispatch("event_msg",
      exists $ENV{$param} ? $ENV{$param} : "[not set]");
  } else {
    $ENV{$param} = $value;
    $self->core->dispatch("event_notice", "Set $param=$value");
  }
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Key - Handle keys

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

