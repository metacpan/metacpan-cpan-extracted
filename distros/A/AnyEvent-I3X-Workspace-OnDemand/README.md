# DESCRIPTION

Workspace switcher for i3.

This module listens to tick events which are named `group:$name` where the
name corresponds to the workspace groups you have defined. When you send a tick
event the current workspaces get renamed to `$former_group:$workspace_name` and leaves new workspaces for the ones you have defined.

In your `.config/i3/config` you can set something like this to switch
groups:

    bindsym $mod+w mode "Activities"
    mode "Activities" {
      bindsym 0 exec i3-msg -t send_tick group:foo; mode default
      bindsym 9 exec i3-msg -t send_tick group:bar; mode default
      bindsym 8 exec i3-msg -t send_tick group:baz; mode default
      bindsym Return mode "default"
      bindsym Escape mode "default"
    }

# SYNOPSIS

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

# METHODS

## $self->subscribe

See ["subscribe" in AnyEvent::I3](https://metacpan.org/pod/AnyEvent%3A%3AI3#subscribe)

## $self->get\_i3

Get the [AnyEvent::I3](https://metacpan.org/pod/AnyEvent%3A%3AI3) instance

## $self->command(@args)

Execute a command, the command can be in scalar or list context.

See also ["command" in AnyEvent::I3](https://metacpan.org/pod/AnyEvent%3A%3AI3#command).

## $self->debug(1)

Enable or disable debug

## $self->log($msg)

Print warns when debug is enabled

## $self->on\_tick($payload, $sub)

Subscribe to a tick event with `$payload` and perform the action. Your sub
needs to support the following prototype:

    sub foo($self, $i3, $event) {
        print "Yay processed foo tick";
    }

    $self->on_tick('foo', \&foo);

## $self->on\_workspace($name, $type, $sub)

Subscribe to a workspace event for workspace `$name` of `$type` with
`$sub`.

`$type` can be any of the following events from i3 plus `any` or `*`

    $i3->on_workspace(
      'www', 'init',
      sub {
        my $self  = shift;
        my $i3    = shift;
        my $event = shift;
        $self->append_layout($event->{current}{name}, '/path/to/layout.json');
      }
    );

## $self->add\_swallow($match, $cmd, $on)

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

## $self->workspace($name, @cmds)

Runs commands on workspace by name. Without a command you only switch
workspaces
