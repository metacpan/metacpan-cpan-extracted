# DESCRIPTION

Workspace switcher for i3.

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

# METHODS

## subscribe

See ["subscribe" in AnyEvent::I3](https://metacpan.org/pod/AnyEvent%3A%3AI3#subscribe)

## get\_i3

Get the [AnyEvent::I3](https://metacpan.org/pod/AnyEvent%3A%3AI3) instance

## command(@args)

Execute a command, the command can be in scalar or list context.

## debug(1)

Enable or disable debug

## log($msg)

Print warns when debug is enabled

## on\_tick($payload, $sub)

Subscribe to a tick event with `$payload` and perform the action. Your sub
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

## on\_workspace($name, $type, $sub)

Subscribe to a workspace event for workspace `$name` of `$type` with
`$sub`.

`$type` can be any of the following events from i3 plus `any` or `*`

    on_workspace(
      'www', 'init',
      sub {
        my $self  = shift;
        my $i3    = shift;
        my $event = shift;
        $self->append_layout($event->{current}{name}, '/path/to/layout.json');
      }
    );

## add\_swallow($match, $cmd, $on)

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

## workspace($name, @cmds)

Runs commands on workspace by name

## command
