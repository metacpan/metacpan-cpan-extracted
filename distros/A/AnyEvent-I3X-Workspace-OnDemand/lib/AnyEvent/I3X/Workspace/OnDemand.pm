package AnyEvent::I3X::Workspace::OnDemand;
our $VERSION = '0.001';
use v5.26;
use Object::Pad;

# ABSTRACT: An I3 workspace loader

class AnyEvent::I3X::Workspace::OnDemand;
use Carp qw(croak);

use AnyEvent::I3 qw(:all);
use List::Util            qw(first any);
use File::Spec::Functions qw(catfile);
use Data::Compare;

field $i3;
field $layout_path :param = catfile($ENV{HOME}, qw(.config i3));

field @groups;
field $starting_group :param = undef;
field $debug :param          = 0;

field %workspace;
field %tick;
field @swallows;
field $c;

field $current_group;
field $current_workspace;

ADJUSTPARAMS {
  my $args = shift;

  if (ref $args->{workspace} eq 'HASH') {
    %workspace = %{ delete $args->{workspace} };
  }
  if (ref $args->{swallows} eq 'ARRAY') {
    @swallows = @{ delete $args->{swallows} };
  }
  if (ref $args->{tick} eq 'HASH') {
    %tick = %{ delete $args->{tick} };
  }
  if (ref $args->{groups} eq 'ARRAY') {
    @groups = @{ delete $args->{groups} };
  }

}

ADJUST {
  $i3 = i3();
  $i3->connect->recv or die "Error connecting to i3";

  $c = Data::Compare->new();

  $current_group     = $groups[0];
  $current_workspace = "__EMPTY__";

  my $name;

  $self->subscribe(
    workspace => sub {
      return unless %workspace;

      my $event = shift;
      my $type  = $event->{change};

      $current_workspace = $event->{current}{name};
      $name = $current_workspace;

      $self->log("Processing event $type for $name");

      # It doesn't have anything, skip skip next;
      return if $type eq 'reload';

      # Don't allow access to workspace which aren't part of the current group
      if (exists $workspace{$name}{group} && !$self->_is_in_group($name, $current_group)) {
          $self->workspace($event->{old}{name});
          return;
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

      $self->log("Processing tick event $payload");

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
  return unless $self->_is_in_group($name, $group);
  return $ws->{group}{$group}{layout} // $ws->{group}{all}{layout} // $ws->{layout};
}

method switch_to_group ($group) {

  my $cur = $current_workspace;
  return if $current_group eq $group && $cur ne '__EMPTY__';

  $i3->get_workspaces->cb(
    sub {
      my $y = shift;
      my $x = $y->recv;

      if ($cur eq '__EMPTY__') {
        ($cur) = map { $_->{name} } grep { $_->{focused} } @$x;
        $current_workspace = $cur;
        return if $current_group eq $group;
      }

      my $qr        = qr/^$group\:.+/;
      my @available = grep { /^$qr/ } map { $_->{name} } @$x;

      foreach my $name (keys %workspace) {
        my $ws = $workspace{$name};
        next unless exists $ws->{group};

        if ($self->_is_in_group($name, $current_group)) {
          $self->workspace($name, "rename workspace to $current_group:$name");
        }

        if ( any { "$group:$name" eq $_ } @available) {
          $self->workspace("$group:$name", "rename workspace to $name");
        }
      }

      $current_group = $group;
      $self->workspace($cur);
    }
  );


}

method log($msg) {
    return unless $debug;
    warn $msg, $/;
    return;
}

method debug ($d = undef) {
  return $debug unless defined $d;
  $debug = $d;
}

method on_workspace ($name, $type, $sub) {

  if (ref $sub ne 'CODE') {
    croak("Please supply a code ref!");
  }

  if ($type eq 'any' || $type eq '*') {
    $workspace{$name}{$_} = $sub for qw(init focus empty);
  }
  elsif ($type eq 'layout') {
    croak("You cannot set a layout via on_workspace");
  }
  else {
    $workspace{$name}{$type} = $sub;
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

  $self->command($_->{cmd})
    for grep { $c->Cmp($targets[0], $_->{match}) }
    grep {
         !exists $_->{on}
      || ($_->{on}{group}     // '') eq $current_group
      || ($_->{on}{workspace} // '') eq $current_workspace
    } @swallows;
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

version 0.001

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
                cmd => 'exec --no-startup-id kitty',
                match => {
                    class => '^kitty$',
                }
            },
            {
                # Start firefox on group bar
                cmd => 'exec --no-startup-id firefox',
                on => {
                    group => 'bar',
                }
                match => {
                    window_role => '^browser$',
                }
            },
            {
                cmd => 'exec --no-startup-id google-chrome',
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

=head1 METHODS

=head2 subscribe

See L<AnyEvent::I3/subscribe>

=head2 get_i3

Get the L<AnyEvent::I3> instance

=head2 command(@args)

Execute a command, the command can be in scalar or list context.

=head2 debug(1)

Enable or disable debug

=head2 log($msg)

Print warns when debug is enabled

=head2 on_tick($payload, $sub)

Subscribe to a tick event with C<< $payload >> and perform the action. Your sub
needs to support the following prototype:

    sub foo($self, $i3, $event)

    on_tick(
      'foo',
      sub {
        my $self  = shift;
        my $i3    = shift;
        my $event = shift;
        print "Yay processed foo tick";
      }
    );

=head2 on_workspace($name, $type, $sub)

Subscribe to a workspace event for workspace C<< $name >> of C<< $type >> with
C<< $sub >>.

C<< $type >> can be any of the following events from i3 plus C<any> or C<*>

    on_workspace(
      'www', 'init',
      sub {
        my $self  = shift;
        my $i3    = shift;
        my $event = shift;
        $self->append_layout($event->{current}{name}, '/path/to/layout.json');
      }
    );

=head2 add_swallow($match, $cmd, $on)

Add a command that can be used to start after a layout has been appended

    add_swallow({ class => '^kitty$' }, 'exec --no-startup-id kitty');

    # or only on this group
    add_swallow(
      { class => '^kitty$' },
      'exec --no-startup-id kitty',
      { group => 'foo' }
    );

    # or workspace
    add_swallow(
      { class => '^kitty$' },
      'exec --no-startup-id kitty',
      { workspace => 'foo' }
    );

=head2 workspace($name, @cmds)

Runs commands on workspace by name

=head2 command

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
