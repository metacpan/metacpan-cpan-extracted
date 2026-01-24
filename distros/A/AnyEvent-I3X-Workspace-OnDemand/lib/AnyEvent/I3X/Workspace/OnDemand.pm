package AnyEvent::I3X::Workspace::OnDemand;
our $VERSION = '0.006';
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
use X11::Protocol;

field $i3;
field $layout_path : param = catfile($ENV{HOME}, qw(.config i3));

field @groups;
field $starting_group :param = undef;
field $starting_workspace :param = undef;
field $debug :param          = 0;

field $log_all_events :param = undef;

field $socket :param = undef;

field %workspace;
field %output;
field %mode;
field %window;
field %barconfig_update;
field %binding;
field %tick;
field %shutdown;

field @swallows;
field $c;

field $current_group;
field $current_workspace;

field $x11;
field $xroot;

ADJUSTPARAMS {
  my $args = shift;

  $debug = 1 if $log_all_events;

  # i3
  %workspace = %{ delete $args->{workspace} }
    if ref $args->{workspace} eq 'HASH';
  %barconfig_update = %{ delete $args->{barconfig_update} }
    if ref $args->{barconfig_update} eq 'HASH';

  %tick     = %{ delete $args->{tick} }     if ref $args->{tick} eq 'HASH';
  %shutdown = %{ delete $args->{shutdown} } if ref $args->{shutdown} eq 'HASH';
  %output   = %{ delete $args->{output} }   if ref $args->{output} eq 'HASH';
  %mode     = %{ delete $args->{mode} }     if ref $args->{mode} eq 'HASH';
  %window   = %{ delete $args->{window} }   if ref $args->{window} eq 'HASH';
  %binding  = %{ delete $args->{binding} }  if ref $args->{binding} eq 'HASH';

  # us
  @groups   = @{ delete $args->{groups} } if ref $args->{groups} eq 'ARRAY';
  @swallows = @{ delete $args->{swallows} }
    if ref $args->{swallows} eq 'ARRAY';

  $x11 = X11::Protocol->new();
  $xroot = $x11->root;
}

method log_event($type, $event) {

  my $msg;
  if ($type eq 'tick') {
    $msg = "Processing tick with payload $event->{payload}";
  }
  elsif ($type eq 'workspace') {
    $msg = "Processing workspace event $event->{change} on $event->{current}{name}";
  }
  else {
    $msg = "Processing $type with payload $event->{change}";
  }

  $self->log($msg);

  return unless $log_all_events;

  open my $fh, '>>', $log_all_events;
  print $fh join($/, $msg, Dumper $event, "");
  close($fh);
}

method _get_property_from_root_window($key) {
  my $prop = $x11->atom($key);
  my $utf8 = $x11->atom('UTF8_STRING');

  my ($value, $type, $format, $bytes_after)
      = $x11->GetProperty($xroot, $prop, $utf8, 0, 1024);

  return $value if $value;
  return;
}

method _set_property_on_root_window($key, $value) {
  my $prop = $x11->atom($key);
  my $utf8 = $x11->atom('UTF8_STRING');

  $x11->ChangeProperty($xroot, $prop, $utf8, 8, 'Replace', $value);
  $x11->flush;
}

method set_group_on_root_window($name) {
  $self->_set_property_on_root_window('_I3_WOD_GROUP', $name);
}

method get_group_from_root_window() {
  my $group = $self->_get_property_from_root_window('_I3_WOD_GROUP');
  return $group if $group;
  $self->set_group_on_root_window($groups[0]);
  return $groups[0];
}

method set_workspace_on_root_window($name) {
  $self->_set_property_on_root_window('_I3_WOD_WORKSPACE', $name);
}

method get_workspace_from_root_window() {
  my $ws = $self->_get_property_from_root_window('_I3_WOD_WORKSPACE');
  return $ws if $ws;
  $self->set_workspace_on_root_window('__EMPTY__');
  return '__EMPTY__';
}



ADJUST {

  $i3 = $socket ? i3($socket) : i3();
  $i3->connect->recv or die "Error connecting to i3";

  $c = Data::Compare->new();

  $current_group = $self->get_group_from_root_window();
  $current_workspace = $self->get_workspace_from_root_window();

  my $name;

  $self->subscribe(
    workspace => sub {

      my $event = shift;
      my $type  = $event->{change};

      $current_workspace = $event->{current}{name};
      $name              = $current_workspace;
      $self->set_workspace_on_root_window($name);

      $self->log_event('workspace', $event);

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

      $self->log_event('tick', $event);

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
      $self->log_event('shutdown', $event);

      my $payload = $event->{change};
      if (my $sub = $shutdown{$payload}) {
        $sub->($self, $i3, $event);
      }
    }
  );

  $self->subscribe(
    barconfig_update => sub {
      my $event   = shift;

      $self->log_event('barconfig_update', $event);

      # This event consists of a single serialized map reporting on options
      # from the barconfig of the specified bar_id that were updated in i3.
      # This event is the same as a GET_BAR_CONFIG reply for the bar with the
      # given id.
      warn "barconfig_update is currently not supported", $/
        if %barconfig_update;
    }
  );

  $self->subscribe(
    output => sub {
      my $event   = shift;
      $self->log_event('output', $event);

      my $payload = $event->{change};
      if (my $sub = $output{$payload}) {
        $sub->($self, $i3, $event);
      }
    }
  );
  $self->subscribe(
    mode => sub {
      my $event   = shift;
      $self->log_event('mode', $event);

      my $payload = $event->{change};
      if (my $sub = $mode{$payload}) {
        $sub->($self, $i3, $event);
      }
    }
  );
  $self->subscribe(
    window => sub {
      my $event   = shift;
      $self->log_event('window', $event);

      my $payload = $event->{change};
      if (my $sub = $window{$payload}) {
        $sub->($self, $i3, $event);
      }
    }
  );
  $self->subscribe(
    binding => sub {
      my $event   = shift;
      $self->log_event('binding', $event);
      my $payload = $event->{change};
      if (my $sub = $binding{$payload}) {
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
      $self->set_group_on_root_window($group);
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

  my @cmds;
  foreach (@swallows) {
      if (!exists $_->{on}) {
          push(@cmds, $_);
          next;
      }
      if (($_->{on}{workspace} // '') eq $current_workspace) {
          push(@cmds, $_);
          next;
      }
      if(($_->{on}{group} // '') eq $current_group) {
          push(@cmds, $_);
          next;
      }
  }

  $self->command("exec $_")
    for map { $_->{cmd} =~ s/^(?:exec\b\s+)//r; }
    grep    { $c->Cmp($targets[0], $_->{match}) } @cmds;
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

version 0.006

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

For the user guide please refer to
L<AnyEvent::I3X::Workspace::OnDemand::UserGuide>.

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
