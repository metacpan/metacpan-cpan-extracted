package App::RoboBot::Plugin::Core::Help;
$App::RoboBot::Plugin::Core::Help::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Text::Wrap qw( wrap );

extends 'App::RoboBot::Plugin';

=head1 core.help

Provids access to documentation and help-related functions and information for
modules, functions, and macros.

=cut

has '+name' => (
    default => 'Core::Help',
);

has '+description' => (
    default => 'Provides help and usage information for modules, functions, and macros.',
);

=head2 help

=head3 Description

With no arguments, displays general help information about the bot, including
instructions on how to access further help.

With the name of a function or a macro (only macros defined on the current
network), displays help tailored to the function or macro, including usage
details and links to more detailed documentation. In cases where a macro and a
function have the same name, the function will always take precedence.

Lastly, module-level help may be displayed by prefacing the name of the module
with the symbol ``:module``. Module help displays the full list of exported
functions for that module.

=head3 Usage

[ :module <name> | <function> | <macro> ]

=head3 Examples

    (help)
    (help apply)
    (help :module types.map)

=head2 help-all

=head3 Description

Displays a complete listing of all functions and macros available on the
current network.

=cut

has '+commands' => (
    default => sub {{
        'help' => { method  => 'help',
                    usage   => '[:module <module name> | <function> | <macro>]' },

        'help-all' => { method      => 'help_all',
                        description => 'Displays a complete listing of all functions and macros available on the current network.', },
    }},
);

sub help {
    my ($self, $message, $command, $rpl, $section, @args) = @_;

    if (defined $section && $section =~ m{\w+}o) {
        if ($section =~ m{^\:?(mod(ule)|plugin)?$}oi) {
            if (@args && defined $args[0] && $args[0] =~ m{\w+}o) {
                $self->plugin_help($message, $args[0]);
            } else {
                $self->general_help($message);
            }
        } elsif (exists $self->bot->commands->{$section}) {
            $self->command_help($message, $section);
        } elsif (exists $self->bot->macros->{$message->network->id}{lc($section)}) {
            $self->macro_help($message, $section);
        } elsif (grep { lc($section) eq $_->ns } @{$self->bot->plugins}) {
            $self->plugin_help($message, $section);
        } else {
            $message->response->push(sprintf('Unknown help section: %s', $section));
        }
    } else {
        $self->general_help($message);
    }

    return;
}

sub help_all {
    my ($self, $message) = @_;

    my @functions = sort { $a cmp $b } (
        map { keys %{$_->commands} }
        grep { ! exists $message->network->disabled_plugins->{lc($_->name)} }
        @{$self->bot->plugins}
    );

    my @macros = sort { $a cmp $b } (
        map { lc($_) }
        keys %{$self->bot->macros->{$message->network->id}}
    );

    my $res = $self->bot->config->db->do(q{
        select var_name
        from global_vars
        where network_id = ?
        order by lower(var_name) asc
    }, $message->network->id);

    my @globals;
    if ($res) {
        while ($res->next) {
            push(@globals, $res->{'var_name'});
        }
    }

    $message->response->push(sprintf('*Functions*: %s', join(', ', @functions))) if @functions > 0;
    $message->response->push(sprintf('*Macros*: %s', join(', ', @macros))) if @macros > 0;
    $message->response->push(sprintf('*Globals*: %s', join(', ', @globals))) if @globals > 0;

    return;
}

sub general_help {
    my ($self, $message) = @_;

    my %plugins = (
        map { $_->ns => 1 }
        grep { ! exists $message->network->disabled_plugins->{lc($_->name)} }
        @{$self->bot->plugins}
    );

    $message->response->push(sprintf('App::RoboBot v%s', $self->bot->version));
    $message->response->push(sprintf('Documentation: https://robobot.automatomatromaton.com/'));
    $message->response->push(sprintf('For additional help, use (help <function>) or (help :module "<name>"). Use (help-all) to see a complete list of functions and macros available on the current network.'));
    $message->response->push(sprintf('Active modules: %s', join(', ', sort keys %plugins)));

    # Return before the function display for now.
    return;

    local $Text::Wrap::columns = 200;
    my @functions = split(
        /\n/o,
        wrap( 'Available functions: ',
              '',
              join(', ',
                  sort { lc($a) cmp lc($b) }
                  grep { $_ !~ m{\w+/[^/]+$}o && !exists $message->network->disabled_plugins->{lc($self->bot->commands->{$_}->name)} }
                  keys %{$self->bot->commands}
              )
        )
    );
    $message->response->push($_) for @functions;

    return;
}

sub plugin_help {
    my ($self, $message, $plugin_name) = @_;

    my ($plugin) = (grep { $_->ns eq lc($plugin_name) } @{$self->bot->plugins});

    if (defined $plugin) {
        $message->response->push(sprintf('App::RoboBot Module: %s', $plugin->ns));
        $message->response->push(sprintf('Documentation: https://robobot.automatomatromaton.com/modules/%s/index.html', $plugin->ns));
        $message->response->push($plugin->description) if $plugin->has_description;
        $message->response->push(sprintf('Exports functions: %s', join(', ', sort keys %{$plugin->commands})));
    } else {
        $message->response->push(sprintf('Unknown module: %s', $plugin_name));
    }

    return;
}

sub command_help {
    my ($self, $message, $command_name, $rpl) = @_;

    if (exists $self->bot->commands->{$command_name}) {
        my $plugin = $self->bot->commands->{$command_name};
        my $doc = $self->bot->doc->function($plugin->ns, $command_name);

        if (exists $doc->{'usage'} && ref($doc->{'usage'}) eq 'ARRAY' && $doc->{'usage'}[0] =~ m{\w+}o) {
            $message->response->push(sprintf('(%s/%s %s)', $plugin->ns, $command_name, $doc->{'usage'}[0]));
        } else {
            $message->response->push(sprintf('(%s/%s)', $plugin->ns, $command_name));
        }

        if (exists $doc->{'description'} && ref($doc->{'description'}) eq 'ARRAY') {
            $message->response->push($_) for @{$doc->{'description'}};
        }

        if (exists $doc->{'example'} && exists $doc->{'result'}) {
            $message->response->push(sprintf('Example: (%s %s) -> %s', $command_name, $doc->{'example'}, $doc->{'result'}));
        } elsif (exists $doc->{'example'}) {
            $message->response->push(sprintf('Example: (%s %s)', $command_name, $doc->{'example'}));
        }

        $message->response->push(sprintf('See also: %s', join(', ', @{$doc->{'see_also'}})))
            if exists $doc->{'see_also'};

        $message->response->push(sprintf('Documentation: https://robobot.automatomatromaton.com/modules/%s/index.html#%s', $plugin->ns, $command_name));
    } else {
        $message->response->push(sprintf('Unknown function: %s', $command_name));
    }

    return;
}

sub macro_help {
    my ($self, $message, $macro_name) = @_;

    if (exists $self->bot->macros->{$message->network->id}{lc($macro_name)}) {
        # TODO: Extend macros to support more useful/informative documentation,
        #       possibly through a docstring like syntax, and then make use of
        #       that here. For now about all we can do is show the signature.
        my $macro = $self->bot->macros->{$message->network->id}{lc($macro_name)};

        $message->response->push(sprintf('(%s%s)',
            $macro->name,
            (length($macro->signature) > 0 ? ' ' . $macro->signature : '')
        ));
        $message->response->push(sprintf('For the complete macro definition, use: (show-macro %s)', $macro->name));
    } else {
        $message->response->push(sprintf('Unknown macro: %s', $macro_name));
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
