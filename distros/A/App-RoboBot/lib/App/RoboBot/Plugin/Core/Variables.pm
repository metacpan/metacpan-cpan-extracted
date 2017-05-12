package App::RoboBot::Plugin::Core::Variables;
$App::RoboBot::Plugin::Core::Variables::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Data::Dumper;
use Scalar::Util qw( blessed );

extends 'App::RoboBot::Plugin';

=head1 core.variables

Provides functions to create and manage variables.

There are two types of variables in App::RoboBot: message scope and global. Message
scope variables persist only as long as it takes to process the current message
and then they are destroyed. Global variables, however, persist indefinitely
and are available across all channels on a single network. They may be re-used,
changed, and undefined from anywhere on the network they were initialized, by
anyone with permission to call the ``(set-global)`` or ``(unset-global)``
functions.

=cut

has '+name' => (
    default => 'Core::Variables',
);

has '+description' => (
    default => 'Provides functions to create and manage variables.',
);

=head2 defined

=head3 Description

=head3 Usage

=head3 Examples

=head2 setvar

=head3 Description

=head3 Usage

=head3 Examples

=head2 unsetvar

=head3 Description

=head3 Usage

=head3 Examples

=head2 incr

=head3 Description

=head3 Usage

=head3 Examples

=head2 set-global

=head3 Description

=head3 Usage

=head3 Examples

=head2 unset-global

=head3 Description

=head3 Usage

=head3 Examples

=head2 var

=head3 Description

=head3 Usage

=head3 Examples

=cut

has '+commands' => (
    default => sub {{
        'defined' => { method          => 'is_defined',
                       preprocess_args => 0,
                       description     => 'Returns true if all of the named variables are defined, otherwise false. Must pass variable names as a list.',
                       usage           => '(<varname1> [... <varnameN>])', },

        'setvar' => { method          => 'set_var',
                      preprocess_args => 0,
                      description     => 'Sets the value of a variable.',
                      usage           => '<variable name> <value or expression>',
                      example         => 'foo 10',
                      result          => '10' },

        'unsetvar' => { method          => 'unset_var',
                        preprocess_args => 0,
                        description     => 'Unsets a variable and removes it from the symbol table.',
                        usage           => '<variable name>',
                        example         => 'foo',
                        result          => '' },

        'incr' => { method          => 'increment_var',
                    preprocess_args => 0,
                    description     => 'Increments a numeric variable by the given amount. If no increment amount is provided, 1 is assumed. Negative amounts are permissible.',
                    usage           => '<variable name> [<amount>]' },

        'set-global' => { method      => 'set_global',
                          description => 'Sets a global variable (accessible from any channel on the current network).',
                          usage       => '<name> <value>' },

        'unset-global' => { method      => 'unset_global',
                            description => 'Unsets a global variable on the current network.',
                            usage       => '<name>' },

        'var' => { method      => 'get_global',
                   description => 'Retrieves the value(s) of a global variable, if it exists on the current network. If the variable does not exist, an empty list is returned, unless <default> is specified in which case that is used instead.',
                   usage       => '<name> [<default>]' },
    }},
);

sub set_global {
    my ($self, $message, $command, $rpl, $var_name, @values) = @_;

    unless (defined $var_name && $var_name =~ m{\w+}) {
        $message->response->raise('Must provide a variable name and at least one value.');
        return;
    }

    unless (@values) {
        return $self->unset_global($message, $command, $var_name);
    }

    my $res = $self->bot->config->db->do(q{
        update global_vars
        set ???
        where network_id = ?
            and lower(var_name) = lower(?)
    }, {
        var_values => \@values,
        updated_at => 'now',
    }, $message->network->id, $var_name);

    if ($res && $res->count > 0) {
        $message->response->push(sprintf('Global variable %s has been updated.', $var_name));
        return;
    }

    $res = $self->bot->config->db->do(q{
        insert into global_vars ??? returning *
    }, {
        network_id => $message->network->id,
        var_name   => $var_name,
        var_values => \@values,
        created_by => $message->sender->id,
    });

    if ($res && $res->next && $res->{'id'} =~ m{\d+}) {
        $message->response->push(sprintf('Global variable %s has been set.', $var_name));
        return;
    }

    $message->response->raise('Could not set global variable %s. Please check your input and try again.', $var_name);
    return;
}

sub unset_global {
    my ($self, $message, $command, $rpl, $var_name) = @_;

    unless (defined $var_name && $var_name =~ m{\w+}) {
        $message->response->raise('Must provide a variable name to unset it.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        delete from global_vars where network_id = ? and lower(var_name) = lower(?)
    }, $message->network->id, $var_name);

    $message->response->push(sprintf('Global variable %s has been unset.', $var_name))
        if $res && $res->count > 0;
    return;
}

sub get_global {
    my ($self, $message, $command, $rpl, $var_name, $default) = @_;

    unless (defined $var_name && $var_name =~ m{\w+}) {
        $message->response->raise('Must provide a variable name to retrieve a value.');
        return;
    }

    my $res = $self->bot->config->db->do(q{
        select var_values
        from global_vars
        where network_id = ? and lower(var_name) = lower(?)
    }, $message->network->id, $var_name);

    if ($res && $res->next && defined $res->{'var_values'}) {
        return @{$res->{'var_values'}};
    } elsif (defined $default) {
        return $default;
    } else {
        return;
    }
}

sub is_defined {
    my ($self, $message, $command, $rpl, @var_list) = @_;

    return 0 unless @var_list > 0;

    my $defined = 1;

    foreach my $var (@var_list) {
        if (blessed($var) && $var->can('type')) {
            $defined = 0 unless $var->has_value;
        } else {
            unless (defined $var) {
                $defined = 0;
                last;
            }

            if (ref($var)) {
                $var = $var->evaluate($message, $rpl);
            }

            unless (defined $var) {
                $defined = 0;
                last;
            }
        }
    }

    return $defined;
}

sub set_var {
    my ($self, $message, $command, $rpl, @args) = @_;

    if (@args && @args == 2 && $args[0] =~ m{^[\$\@\*\:\+0-9a-zA-Z_-]+$}) {
        return $message->vars->{$args[0]} = $message->process_list($args[1]);
    }
}

sub unset_var {
    my ($self, $message, $command, $rpl, @args) = @_;

    if (@args && @args == 1) {
        if (exists $message->vars->{$args[0]}) {
            return delete $message->vars->{$args[0]};
        } else {
            return $message->response->raise('No such variable.');
        }
    }
}

sub increment_var {
    my ($self, $message, $command, $rpl, $var_name, $amount) = @_;

    $amount = 1 unless defined $amount;

    unless (defined $var_name && exists $self->message->vars->{$var_name}) {
        return $message->response->raise('Variable name unspecified or invalid.');
    }

    unless ($amount =~ m{\d+}o && m{^-?\d*\.\d*$}o) {
        return $message->response->raise('Increment amount "%s" does not appear to be a valid number.', $amount);
    }

    unless ($self->message->vars->{$var_name} =~ m{^-?\d*\.\d*$}o) {
        return $message->response->raise('Variable "%s" is not numeric. Cannot increment.', $var_name);
    }

    $self->message->vars->{$var_name} += $amount;
    return $self->message->vars->{$var_name};
}

__PACKAGE__->meta->make_immutable;

1;
