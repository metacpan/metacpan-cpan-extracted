package App::RoboBot::Plugin::Core::Macro;
$App::RoboBot::Plugin::Core::Macro::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use App::RoboBot::Macro;

use Data::Dumper;
use Scalar::Util qw( blessed );

extends 'App::RoboBot::Plugin';

=head1 core.macro

Provides functionality for defining and managing macros. Macros defined by this
plugin are available to all users in all channels on the current network, and
persist across bot restarts.

=cut

has '+name' => (
    default => 'Core::Macro',
);

has '+description' => (
    default => 'Provides functionality for defining and managing macros. Macros defined by this plugin are available to all users in all channels on the current network, and persist across bot restarts.',
);

=head2 defmacro

=head3 Description

Macros are user-defined functions, and any channel members with permission to
call ``(defmacro)`` may define their own macros. Name collisions between macros
and builtin functions are always resolved in favor of the functions.

Macro names may contain any valid identifier characters, including many forms
of punctuation and Unicode glyphs (as long as your chat network supports their
transmission). The primary restrictions on macro names are:

* They cannot begin with a colon ``:`` character (that is reserved for Symbols).

* They cannot contain whitespace.

* They cannot be a valid Numeric (have an optional leading dash, include a decimal separator, and otherwise consist only of numbers).

* They cannot contain a slash ``/`` as that is the function namespace separator.

The macro argument list is a vector of names to which arguments will be bound
whenever the macro is invoked. The may be used repeatedly within the macro
body, but bear in mind they are replaced during macro expansion with the value
of the argument. They are not mutable variables.

Unless otherwise indicated, all macro arguments are considered mandatory, and
calling the macro without them will result in an error. To mark arguments as
optional, they must follow a ``&optional`` symbol in the argument vector. In
addition to optional arguments, you may mark a single argument as the target
for all remaining arguments that may have been passed to the macro, after all
of the explicit arguments are bound. This is done by placing the name to which
they will be bound as a list after the ``&rest`` symbol in the argument vector.

Finally, the macro body expression may be any valid quoted expression and as
such may invoke other macros. The names from your argument vector will be
available for use within the entire macro body.

=head3 Usage

<macro name> <vector of arguments> <macro body expression>

=head3 Examples

    :emphasize-lines: 3,7

    (defmacro plus-one [a] '(+ a 1))
    (plus-one 5)
    6

    (defmacro grep-for-foo [&rest my-list] '(filter (match "foo" %) my-list))
    (grep-for-foo "foo" "bar" "baz" "food")
    ("foo" "food")

=head2 undefmacro

=head3 Description

Undefines the named macro. This is a permanent action and if the named macro is
desired again, it must be recreated from scratch.

If the macro has been locked by its author, only they may undefine it. Anyone
else attempting to remove the macro will receive an error explaining that it is
currently locked.

=head3 Usage

<macro name>

=head2 show-macro

=head3 Description

Displays a macro's definition and who authored it.

=head3 Usage

<macro name>

=head2 list-macros

=head3 Description

Displays a list of all registered macros. Optional pattern will limit list to
only those macros whose names match.

=head3 Usage

[<pattern>]

=head2 lock-macro

=head3 Description

Locks a macro from further modification or deletion. This function is only
available to the author of the macro.

=head3 Usage

<macro name>

=head2 unlock-macro

=head3 Description

Unlocks a previously locked macro, allowing it to once again be modified or
deleted. This function is only available to the author of the macro.

=head3 Usage

<macro name>

=cut

has '+commands' => (
    default => sub {{
        'defmacro' => { method          => 'define_macro',
                        preprocess_args => 0,
                        description     => 'Defines a new macro, or replaces an existing macro of the same name. Macros may call, or even create/modify/delete other macros.',
                        usage           => '<name> (<... argument list ...>) \'(<definition body list>)',
                        example         => "plus-one (a) '(+ a 1)" },

        'undefmacro' => { method      => 'undefine_macro',
                          description => 'Undefines an existing macro.',
                          usage       => '<name>' },

        'show-macro' => { method      => 'show_macro',
                          description => 'Displays the definition of a macro.',
                          usage       => '<name>' },

        'list-macros' => { method      => 'list_macros',
                           description => 'Displays a list of all registered macros. Optional pattern will limit list to only those macros whose names match.',
                           usage       => '[<pattern>]', },

        'lock-macro' => { method      => 'lock_macro',
                          description => 'Locks a macro from further modification or deletion. This function is only available to the author of the macro.',
                          usage       => '<macro name>' },

        'unlock-macro' => { method      => 'unlock_macro',
                            description => 'Unlocks a previously locked macro, allowing it to once again be modified or deleted. This function is only available to the author of the macro.',
                            usage       => '<macro name>' },
    }},
);

sub list_macros {
    my ($self, $message, $command, $rpl, $pattern) = @_;

    my $res = $self->bot->config->db->do(q{
        select name
        from macros
        where name ~* ?
            and network_id = ?
        order by name asc
    }, ($pattern // '.*'), $message->network->id);

    unless ($res) {
        $message->response->raise('Could not obtain list of macros. If you supplied a pattern, please ensure that it is a valid regular expression.');
        return;
    }

    my @macros;

    while ($res->next) {
        push(@macros, $res->{'name'});
    }

    return @macros;
}

sub define_macro {
    my ($self, $message, $command, $rpl, $macro_name, $args, $def) = @_;

    my $network = $message->network;

    unless (defined $macro_name && defined $args && defined $def) {
        $message->response->raise('Macro definitions must consist of a name, a list of arguments, and a definition body list.');
        return;
    }

    # Get the actual stringy name.
    if ($macro_name->type eq 'Macro') {
        # We need to special-case this, as redefining an existing macro is going to have the
        # parser identify the name token in the (defmacro ...) call as the name of an
        # existing macro (and therefore type "Macro") instead of just a bare string.
        $macro_name = $macro_name->value;
    } elsif ($macro_name->type eq 'Function') {
        # We can short-circuit and reject macros named the same as a function right away.
        $message->response->raise('Macros cannot have the same name as a function.');
        return;
    } else {
        $macro_name = $macro_name->evaluate($message, $rpl);
    }

    # Enforce a few rules on macro names.
    unless (defined $macro_name && !ref($macro_name) && $macro_name =~ m{^[^\s\{\(\)\[\]\{\}\|,#]+$} && substr($macro_name, 0, 1) ne "'") {
        $message->response->raise('Macro name must be a single string value.');
        return;
    }

    if (exists $self->bot->macros->{$network->id}{lc($macro_name)} && $self->bot->macros->{$network->id}{lc($macro_name)}->is_locked) {
        if ($self->bot->macros->{$network->id}{lc($macro_name)}->definer->id != $message->sender->id) {
            $message->response->raise(
                'The %s macro has been locked by its creator (who happens to not be you) and cannot be redefined by anyone else.',
                $self->bot->macros->{$network->id}{lc($macro_name)}->name
            );
            return;
        }
    }

    unless (blessed($args) && ($args->type eq 'List' || $args->type eq 'Vector')) {
        $message->response->raise('Macro arguments must be specified as a list or vector.');
        return;
    }

    unless (blessed($def) && ($def->type eq 'List' || $def->type eq 'Expression') && $def->quoted) {
        $message->response->raise('Macro body definition must be a quoted expression or list.');
        return;
    }

    $def->quoted(0);

    # Work through the argument list looking for &optional (and maybe in the
    # future we'll do things like &key and friends), building up the arrayref
    # of hashrefs for our macro's arguments.
    my $args_def = {
        has_optional => 0,
        positional   => [],
        keyed        => {},
        rest         => undef,
    };
    my $next_rest = 0;

    foreach my $arg ($args->evaluate($message, $rpl)) {
        if ($next_rest) {
            $args_def->{'rest'} = $arg;
            $next_rest = 0;
            next;
        }

        # We hit an '&optional', so all following arguments are optional. And if
        # more than the stated number are passed, they can be accessed through
        # the autovivified &rest list in the macro.
        if ($arg eq '&optional') {
            $args_def->{'has_optional'} = 1;
            next;
        } elsif ($arg eq '&rest') {
            $next_rest = 1;
            next;
        }

        # TODO; Add support for &key'ed macro arguments.

        push(@{$args_def->{'positional'}}, {
            name     => $arg,
            optional => $args_def->{'has_optional'},
        });
    }

    # Having &rest in the argument list without naming the variable into which
    # the remaining values will be placed is invalid. If the flag is still set
    # when we're done processing the arglist, then that has happened.
    if ($next_rest) {
        $message->response->raise('The &rest collection must be named.');
        return;
    }

    my $body;
    unless ($body = $def->flatten($rpl)) {
        $message->response->raise('Could not collapse macro definition.');
        return;
    }

    if ($self->bot->add_macro($message->network, $message->sender, $macro_name, $args_def, $body)) {
        $message->response->push(sprintf('Macro %s defined.', $macro_name));
    } else {
        $message->response->raise('Could not define macro %s.', $macro_name);
    }

    return;
}

sub undefine_macro {
    my ($self, $message, $command, $rpl, $macro_name) = @_;

    # For brevity below.
    my $network = $message->network;

    unless (defined $macro_name && $macro_name =~ m{\w+}o) {
        $message->response->raise('Must provide the name of a macro to undefine.');
        return;
    }

    unless (exists $self->bot->macros->{$network->id}{$macro_name}) {
        $message->response->raise('Macro %s has not been defined.', $macro_name);
        return;
    }

    if ($self->bot->macros->{$network->id}{$macro_name}->is_locked && $self->bot->macros->{$network->id}{$macro_name}->definer != $message->sender->id) {
        $message->response->raise(
            'The %s macro has been locked by its creator (who happens to not be you). You may not undefine it.',
            $self->bot->macros->{$network->id}{$macro_name}->name
        );
    } else {
        if ($self->bot->remove_macro($network, $macro_name)) {
            $message->response->push(sprintf('Macro %s undefined.', $macro_name));
        } else {
            $message->response->push(sprintf('Could not undefine macro %s.', $macro_name));
        }
    }

    return;
}

sub show_macro {
    my ($self, $message, $command, $rpl, $macro_name) = @_;

    my $network = $message->network;

    unless (defined $macro_name && exists $self->bot->macros->{$network->id}{$macro_name}) {
        $message->response->raise('No such macro defined.');
        return;
    }

    my $macro = $self->bot->macros->{$network->id}{$macro_name};
    my $pp = sprintf('(defmacro %s [%s] \'%s)', $macro->name, $macro->signature, $macro->expression->flatten);

    $pp =~ s{\n\s+([^\(]+)\n}{ $1\n}gs;
    $message->response->push($pp);
    $message->response->push(sprintf('Defined by <%s> on %s', $macro->definer->name, $macro->timestamp->ymd));
    $message->response->push('This macro is locked and may only be edited by its definer.') if $macro->is_locked;

    return;
}

sub lock_macro {
    my ($self, $message, $command, $rpl, $macro) = @_;

    my $network = $message->network;

    unless (defined $macro && $macro =~ m{\S+}) {
        $message->response->raise('Must provide the name of the macro you wish to lock.');
        return;
    }

    unless (exists $self->bot->macros->{$network->id}{lc($macro)}) {
        $message->response->raise('No such macro defined.');
        return;
    }

    $macro = $self->bot->macros->{$network->id}{lc($macro)};

    if ($macro->is_locked) {
        $message->response->raise('The macro %s is already locked.', $macro->name);
        return;
    }

    unless ($macro->definer->id == $message->sender->id) {
        $message->response->raise('You did not define the %s macro and cannot lock it. You may only lock your own macros.', $macro->name);
        return;
    }

    unless ($macro->lock(1) && $macro->save) {
        $message->response->raise('Could not lock the %s macro. Please try again.', $macro->name);
        return;
    }

    $message->response->push(sprintf('Your %s macro is now locked. Nobody but you may modify or delete it.', $macro->name));
    return;
}

sub unlock_macro {
    my ($self, $message, $command, $rpl, $macro) = @_;

    my $network = $message->network;

    unless (defined $macro && $macro =~ m{\S+}) {
        $message->response->raise('Must provide the name of the macro you wish to unlock.');
        return;
    }

    unless (exists $self->bot->macros->{$network->id}{lc($macro)}) {
        $message->response->raise('No such macro defined.');
        return;
    }

    $macro = $self->bot->macros->{$network->id}{lc($macro)};

    if ( ! $macro->is_locked) {
        $message->response->raise('The macro %s is not locked.', $macro->name);
        return;
    }

    unless ($macro->definer->id == $message->sender->id) {
        $message->response->raise('You did not define the %s macro and cannot unlock it. You may only unlock your own macros.', $macro->name);
        return;
    }

    unless ($macro->lock(0) && $macro->save) {
        $message->response->raise('Could not unlock the %s macro. Please try again.', $macro->name);
        return;
    }

    $message->response->push(sprintf('Your %s macro is now unlocked. Anybody else may modify or delete it.', $macro->name));
    return;
}

sub _pprint {
    my ($list, $nlv) = @_;

    $list //= [];
    $nlv  //= 1;

    if ($nlv <= 1 && ref($list) eq 'ARRAY' && scalar(@{$list}) == 1) {
        # Special-case looking for unnecessary nesting and remove the extra layers.
        return _pprint($list->[0], $nlv);
    } elsif (ref($list) eq 'ARRAY') {
        if (scalar(@{$list}) == 2 && $list->[0] eq 'backquote' && ref($list->[1]) eq 'ARRAY') {
            # Special case the '(...) forms so they don't show up as (backquote (...))
            return sprintf("'%s", _pprint($list->[1], $nlv));
        } elsif (scalar(grep { ref($_) eq 'ARRAY' } @{$list}) == 0) {
            # Simplest case: we are at a terminus list with no children.
            return sprintf('(%s)', join(' ', map { _fmtstr($_) } @{$list}));
        } else {
            # Harder case: there are child lists which must be formatted.
            my @subs;
            push(@subs, _pprint($_, $nlv + 1)) for @{$list};
            return sprintf('(%s)', join(sprintf("\n%s", "  " x $nlv), @subs));
        }
    } else {
        return _fmtstr($list);
    }
}

sub _fmtstr {
    my ($str) = @_;

    $str = "$str";

    if ($str =~ m{[\s"']}s) {
        $str =~ s{"}{\\"}g;
        $str =~ s{\n}{\\n}gs;
        return '"' . $str . '"';
    }
    return $str;
}

__PACKAGE__->meta->make_immutable;

1;
