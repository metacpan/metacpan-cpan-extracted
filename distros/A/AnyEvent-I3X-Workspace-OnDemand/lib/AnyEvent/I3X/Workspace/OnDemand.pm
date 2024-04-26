package AnyEvent::I3X::Workspace::OnDemand;
our $VERSION = '0.003';
use v5.26;
use Object::Pad;

# ABSTRACT: An I3 workspace loader

class AnyEvent::I3X::Workspace::OnDemand;
use Carp qw(croak);

use AnyEvent::I3          qw(:all);
use List::Util            qw(first any);
use File::Spec::Functions qw(catfile);
use Data::Compare;
use Data::Dumper;

field $i3;
field $layout_path : param = catfile($ENV{HOME}, qw(.config i3));

field @groups;
field $starting_group :param = undef;
field $starting_workspace :param = undef;
field $debug :param          = 0;

field $log_all_events :param = undef;

field $socket :param = undef;

field %workspace;
field %tick;
field %shutdown;

field @swallows;
field $c;

field $current_group;
field $current_workspace;

ADJUSTPARAMS {
  my $args = shift;

  $debug = 1 if $log_all_events;

  if (ref $args->{workspace} eq 'HASH') {
    %workspace = %{ delete $args->{workspace} };
  }
  if (ref $args->{swallows} eq 'ARRAY') {
    @swallows = @{ delete $args->{swallows} };
  }
  if (ref $args->{tick} eq 'HASH') {
    %tick = %{ delete $args->{tick} };
  }
  if (ref $args->{shutdown} eq 'HASH') {
    %shutdown = @{ delete $args->{shutdown} };
  }
  if (ref $args->{groups} eq 'ARRAY') {
    @groups = @{ delete $args->{groups} };
  }

}

method log_all_events($event) {
    return unless $log_all_events;

    my $e;
    if ($debug) {
        $e = Dumper $event;
    }
    elsif ($event->{payload}) {
        $e = "Processing tick with payload $event->{payload}";
    }
    elsif ($event->{container}) {
        $e = "Processing window with payload $event->{change}";
    }
    elsif ($event->{change}) {
        $e = "Processing shutdown with payload $event->{change}";
    }
    else {
        $e = "Processing event $event->{change} on $event->{current}{name}";
    }

    $self->log($e);
    open my $fh, '>>', $log_all_events;
    print $fh $e;
    print $fh $/;
    close($fh);
}

ADJUST {

  $i3 = $socket ? i3($socket) : i3();
  $i3->connect->recv or die "Error connecting to i3";

  if ($log_all_events) {
      use Data::Dumper;
  }

  $c = Data::Compare->new();

  $current_group     = $groups[0];
  $current_workspace = "__EMPTY__";

  my $name;

  $self->subscribe(
    workspace => sub {

      my $event = shift;
      my $type  = $event->{change};

      $current_workspace = $event->{current}{name};
      $name              = $current_workspace;

      $self->log("Processing event $type for $name");

      $self->log_all_events($event);

      # It doesn't have anything, skip skip next;
      return if $type eq 'reload';

      return unless %workspace;
      # Don't allow access to workspace which aren't part of the current group
      if (exists $workspace{$name}{group}
        && !$self->_is_in_group($name, $current_group)) {
        if ($event->{old}{name}) {
          $self->workspace($event->{old}{name});
          return;
        }

        # it is strange that we don't have an old workspace here...
        warn
          "Unable to determine old workspace, but group hasn't defined a workspace",
          $/;
      }

      my $layout = $workspace{$name}{layout};
      if ($layout) {
        if ($type eq 'init') {
          $layout = $self->_get_layout($name, $current_group);
          if ($layout) {
            $self->append_layout($name, $layout_path, $layout);
            $self->start_apps_of_layout($name);
          }


        }
        elsif ($type eq 'focus') {
          $self->start_apps_of_layout($name);
        }
      }

      if (my $sub = $workspace{$name}{$type}) {
        $sub->($self, $i3, $event);
      }
    }
  );

  $self->subscribe(
    tick => sub {

      my $event   = shift;
      my $payload = $event->{payload};

      $payload = "__EMPTY__" unless length($payload);
      $event->{payload} = $payload;

      $self->log("Processing tick event $payload");
      $self->log_all_events($event);

      if ($payload =~ /^group:([[:word:]]+)$/) {

        # Skip if we have no groups
        return unless any { $_ eq $1 } @groups;
        $self->switch_to_group($1);
        return;
      }

      return unless %tick;

      if (my $sub = $tick{$payload}) {
        $sub->($self, $i3, $event);
      }
    }
  );

  $self->subscribe(
    shutdown => sub {
      my $event   = shift;

      my $payload = $event->{change};
      $self->log("Processing shutdown event $payload");

      $self->log_all_events($event);

      if (my $sub = $shutdown{$payload}) {
        $sub->($self, $i3, $event);
      }
    }
  );

}

method _is_in_group ($name, $group) {
  my $ws = $workspace{$name};
  return 0 unless $ws;
  return 0 unless exists $ws->{group};
  return 1 if exists $ws->{group}{$group};
  return 1 if exists $ws->{group}{all};
}

method _get_layout ($name, $group) {
  my $ws = $workspace{$name};

  return unless $ws;

  return $ws->{layout} unless exists $ws->{group};
  return               unless $self->_is_in_group($name, $group);
  return $ws->{group}{$group}{layout} // $ws->{group}{all}{layout}
    // $ws->{layout};
}

method switch_to_group ($group) {

  my $cur = $current_workspace;
  return if $current_group eq $group && $cur ne '__EMPTY__';

  $i3->get_workspaces->cb(
    sub {
      my $y = shift;
      my $x = $y->recv;
      my @current_workspaces = @$x;

      if ($cur eq '__EMPTY__') {
        ($cur) = map { $_->{name} } grep { $_->{focused} } @current_workspaces;
        $current_workspace = $cur;
        return if $current_group eq $group;
      }

      my $qr        = qr/^$group\:.+/;
      my @available = grep { /^$qr/ } map { $_->{name} } @$x;

      foreach my $name (keys %workspace) {
        my $ws = $workspace{$name};
        next unless exists $ws->{group};

        if (any { $name eq $_->{name}} @current_workspaces) {
          if ($self->_is_in_group($name, $current_group)) {
            $self->workspace($name, "rename workspace to $current_group:$name");
          }
        }

        if (any { "$group:$name" eq $_ } @available) {
          $self->workspace("$group:$name", "rename workspace to $name");
        }
      }

      $current_group = $group;
      $self->workspace($cur);
    }
  );


}

method log ($msg) {
  return unless $debug;
  warn $msg, $/;
  return;
}

method debug ($d = undef) {
  return $debug unless defined $d;
  $debug = $d;
}

my @any = qw(any *);

method on_workspace ($name, $type, $sub) {

  if (ref $sub ne 'CODE') {
    croak("Please supply a code ref!");
  }

  state @actions = qw(init focus empty urgent reload rename restored move);

  if (any { $_ eq $type } @any) {
    $workspace{$name}{$_} = $sub for @actions;
  }
  elsif (any { $_ eq $type } @actions) {
    $workspace{$name}{$type} = $sub;
  }
  else {
    croak("Unsupported action '$type', please use any of the following:"
        . join(", ", @actions));
  }
}

method on_shutdown ($payload, $sub) {
  if (ref $sub ne 'CODE') {
    croak("Please supply a code ref!");
  }
  state @payloads = qw(exit restart);
  if (any { $_ eq $payload } @any) {
    $shutdown{$_} = $sub for @payloads;
  }
  elsif (any { $_ eq $payload } @payloads) {
    $shutdown{$payload} = $sub;
  }
  else {
    croak("Unsupported action '$payload', please use any of the following:"
        . join(", ", @payloads));
  }
}

method on_tick ($payload, $sub) {
  if (ref $sub ne 'CODE') {
    croak("Please supply a code ref!");
  }
  $tick{$payload} = $sub;
}

method add_swallow ($match, $cmd, $on = undef) {
  push(
    @swallows,
    {
      match => $match,
      cmd   => $cmd,
      defined $on ? (on => $on) : (),
    }
  );
}

method subscribe ($action, $sub) {
  my $answer = $i3->subscribe({ $action => $sub });
  $answer->send;
  return;
}

method get_i3() {
  return $i3;
}

method command (@args) {
  $i3->command(join(" ", @args));
}

method append_layout ($name, @layout) {
  my $layout = catfile(@layout);
  $self->workspace($name, "append_layout $layout");
}

method workspace ($workspace, @rest) {
  $self->command(join(";", "workspace $workspace", @rest));
}

method swallow_to_exec ($name, $node) {

  my @targets = @{ $node->{swallows} };

  if (!@targets) {
    $self->swallow_to_exec($name, $_) foreach @{ $node->{nodes} };
    return;
  }

  $self->command("exec $_")
    for map { $_->{cmd} =~ s/^exec (?:--no-startup-id )?//r; }
    grep    { $c->Cmp($targets[0], $_->{match}) } @swallows;

}

method start_apps_of_layout ($name) {
  $i3->get_tree->cb(
    sub {
      my $x     = shift;
      my $tree  = $x->recv;
      my $nodes = $tree->{nodes};
      foreach (@{$nodes}) {
        next if $_->{name} eq '__i3';
        my $node = first { $_->{name} eq 'content' } @{ $_->{nodes} };
        my $ws   = first { $_->{name} eq $name } @{ $node->{nodes} };
        next unless $ws;
        $self->swallow_to_exec($name, $_) foreach @{ $ws->{nodes} };
      }
    }
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::I3X::Workspace::OnDemand - An I3 workspace loader

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use AnyEvent::I3X::Workspace::OnDemand;

    my $i3 = AnyEvent::I3X::Workspace::OnDemand->new(
        debug => 0,
        layout_path => "$ENV{HOME}/.config/i3",
        workspaces => {
            foo => {
                layout => 'foo.json',
            },
            bar => {
                layout => 'bar.json',
                groups => {
                    foo => undef,
                    # Override the layout for group bar
                    bar => { layout => 'foo.json' },
                }
            },
            baz => {
                layout => 'baz.json',
                groups => {
                    all => undef,
                }
            }
        },
        groups => [
            qw(foo bar baz)
        ],
        swallows => [
            {
                cmd => 'kitty',
                match => {
                    class => '^kitty$',
                }
            },
            {
                # Start firefox on group bar
                cmd => 'firefox',
                on => {
                    group => 'bar',
                }
                match => {
                    window_role => '^browser$',
                }
            },
            {
                cmd => 'google-chrome',
                on => {
                    group => 'foo',
                }
                match => {
                    window_role => '^browser$',
                }
            }
        ],
    );

=head1 DESCRIPTION

Workspace switcher for i3.

This module listens to tick events which are named C<< group:$name >> where the
name corresponds to the workspace groups you have defined. When you send a tick
event the current workspaces get renamed to C<< $former_group:$workspace_name
>> and leaves new workspaces for the ones you have defined.

In your C<< .config/i3/config >> you can set something like this to switch
groups:

  bindsym $mod+w mode "Activities"
  mode "Activities" {
    bindsym 0 exec i3-msg -t send_tick group:foo; mode default
    bindsym 9 exec i3-msg -t send_tick group:bar; mode default
    bindsym 8 exec i3-msg -t send_tick group:baz; mode default
    bindsym Return mode "default"
    bindsym Escape mode "default"
  }

=head1 METHODS

=head2 $self->subscribe

See L<AnyEvent::I3/subscribe>

=head2 $self->get_i3

Get the L<AnyEvent::I3> instance

=head2 $self->command(@args)

Execute a command, the command can be in scalar or list context.

See also L<AnyEvent::I3/command>.

=head2 $self->debug(1)

Enable or disable debug

=head2 $self->log($msg)

Print warns when debug is enabled

=head2 $self->on_tick($payload, $sub)

Subscribe to a tick event with C<< $payload >> and perform the action. Your sub
needs to support the following prototype:

    sub foo($self, $i3, $event) {
        print "Yay processed foo tick";
    }

    $self->on_tick('foo', \&foo);

=head2 $self->on_workspace($name, $type, $sub)

Subscribe to a workspace event for workspace C<< $name >> of C<< $type >> with
C<< $sub >>.

C<< $type >> can be any of the following events from i3 plus C<any> or C<*>

    $i3->on_workspace(
      'www', 'init',
      sub {
        my $self  = shift;
        my $i3    = shift;
        my $event = shift;
        $self->append_layout($event->{current}{name}, '/path/to/layout.json');
      }
    );

=head2 $self->add_swallow($match, $cmd, $on)

Add a command that can be used to start after a layout has been appended

    $self->add_swallow({ class => '^kitty$' }, 'exec --no-startup-id kitty');

    # or only on this group
    $self->add_swallow(
      { class => '^kitty$' },
      'exec --no-startup-id kitty',
      { group => 'foo' }
    );

    # or workspace
    $self->add_swallow(
      { class => '^kitty$' },
      'exec --no-startup-id kitty',
      { workspace => 'foo' }
    );

=head2 $self->workspace($name, @cmds)

Runs commands on workspace by name. Without a command you only switch
workspaces

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
