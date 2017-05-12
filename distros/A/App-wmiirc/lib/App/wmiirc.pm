# ABSTRACT: An event loop for wmii (X11 window manager)
package App::wmiirc;
{
  $App::wmiirc::VERSION = '1.000';
}
use 5.014;
use App::wmiirc::Util;
use File::Which;
use IO::Async::Loop;
use IO::Async::Stream;
use Moo;
use Try::Tiny;

$SIG{PIPE} = 'IGNORE';

our $DEBUG = !!$ENV{WMIIP_DEBUG};

has loop => (
  is => 'ro',
  default => sub { IO::Async::Loop->new }
);

has main_config => (
  is => 'ro',
  default => sub {
    +{config("config", {
      modkey      => 'Mod4',
      normcolors  => '#999999 #151f3f #2a3f3f',
      focuscolors => '#ffffaa #5f77bf #2a3f8f',
      alertcolors => '#ffffff #aa2299 #ff44cc',
      font        => '-*-fixed-medium-r-*-*-12-*-*-*-*-*-*-*',
      terminal    => scalar(config('commands', 'terminal',
                       which('urxvt') || which('xterm'))),
    })}
  }
);

sub BUILD {
  my($self) = @_;

  $SIG{__WARN__} = sub {
    print STDERR @_;
    $self->dispatch("event_msg", @_);
  };

  # Munge defaults to wmii ctl form
  my %ctl_config = %{$self->main_config};
  $ctl_config{grabmod} ||= $self->main_config->{modkey};
  delete @ctl_config{qw(modkey terminal alertcolors)};
  wmiir "/ctl", map "$_ $ctl_config{$_}", keys %ctl_config;

  # Mirror various bits of config under .wmii to wmii's filesystem
  wmiir "/rules", scalar config("rules");
  wmiir "/colrules", scalar config("colrules");

  # Load configured modules
  my %modules = config("modules", { key => "", tag => "" });
  $self->load($_) for keys %modules;

  # Run configured external programs
  for(split /\n/, scalar config("startup") || "witray") {
    next if /^\s*#/;
    system "$_ &";
  }
}

sub run {
  my($self) = @_;

  $self->loop->add(IO::Async::Stream->new(
    read_handle => do {
      open my $event_fh, "-|", "wmiir", "read", "/event" or die $!; $event_fh;
    },
    on_read => sub {
      my(undef, $buffref, $eof) = @_;

      while($$buffref =~ s/^(.*\n)//) {
        my($event, @args) = split " ", $1;
        # CamelCase -> camel_case
        $event =~ s/(?<=[a-z])([A-Z])/_$1/g;
        try {
          $self->dispatch(lc "event_$event", @args);
        } catch {
          warn "Dispatch failed: $_";
        }
      }

      $self->loop->stop(1) if $eof;

      return 0;
    }
  ));

  try {
    $self->loop->run;
  } catch {
    warn "Runloop failed: $_";
  }
}

sub dispatch {
  my($self, $event, @args) = @_;

  for my $module(grep /::$/, keys %App::wmiirc::) {
    my $class = "App::wmiirc::" . $module =~ s/::$//r;
    if($class->can($event)) {
      warn "Dispatch: $event (@args) to $class\n" if $DEBUG;
      $self->{cache}{$class} ||= $self->load($class);
      $self->{cache}{$class}->$event(@args);
    }
  }
}

sub load {
  my($self, $class) = @_;
  $class = "App::wmiirc::" . ucfirst $class;
  warn "Loading $class\n" if $DEBUG;
  my $file = $class =~ s{::}{/}rg;
  $file .= ".pm";
  try {
    # Make it so a bad module doesn't kill the whole thing and can usually be
    # recovered from with a simple ^Awmiirc.
    require $file;
    $self->{cache}{$class} = $class->new(core => $self);
  } catch {
    warn "Failed to load $class: $_";
  }
}

1;


__END__
=pod

=head1 NAME

App::wmiirc - An event loop for wmii (X11 window manager)

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Please see the F<README> for details for now.

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

