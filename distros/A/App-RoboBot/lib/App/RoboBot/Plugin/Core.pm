package App::RoboBot::Plugin::Core;
$App::RoboBot::Plugin::Core::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

use App::RoboBot::TypeFactory;

use Scalar::Util qw( blessed );

extends 'App::RoboBot::Plugin';

=head1 core

Provides a limited set of special form functions for core syntax and language
features.

=cut

has '+name' => (
    default => 'Core',
);

has '+description' => (
    default => 'Provides a limited set of special form functions for core syntax and language features.',
);

=head2 let

=head3 Description

Creates a new scope with one or more variables (as defined in the mandatory
vector) and then evaluates all child forms within that scope. Masking is
supported, in that conflicting variable names from the outer scope will have
their values restored when the scope created by this form is terminated. The
return value of this function is that of the last child form evaluated.

The vector of variables must contain an even number of elements. Each pair of
elements defines the name of the variable and its value, respectively. The
value may be a literal string or numeric, or may be any other valid type or
expression which yields a value.

Values are evaluated and bound to the variable at the time of scope
initialization and are available for use for the remainder of the scope,
including any inner scopes.

=head3 Usage

<vector of scoped variables> <list|expression> [<list|expression> ...]

=head3 Examples

    :emphasize-lines: 2,5

    (let [two (+ 1 1)] (* two 4))
    8

    (let [two (+ 1 1)] (let [four (* two two)] (* two four)))
    8

=cut

has '+commands' => (
    default => sub {{
        'let' => { method          => 'core_let',
                   preprocess_args => 0,
                   description     => 'Creates a new scope with one or more variables (as defined in the mandatory vector) and then evaluates all child forms within that scope. Masking is supported, in that conflicting variable names from the outer scope will have their values restored when the scope created by this form is terminated. The return value of this function is that of the last child form evaluated.',
                   usage           => '<vector of scoped variables> <list|expression> [<list|expression> ...]',
                   example         => '[two (+ 1 1)] (* two 4)',
                   result          => '8' },
    }},
);

sub core_let {
    my ($self, $message, $command, $rpl, $vec, @forms) = @_;

    my %new_scope = defined $rpl && ref($rpl) eq 'HASH' ? %{$rpl} : ();

    unless (defined $vec && blessed($vec) && $vec->type eq 'Vector') {
        $message->response->raise('First argument must be a vector of variable definitions.');
        return;
    }

    unless (@forms && @forms > 0) {
        $message->response->raise('A new scope requires at least one form to evaluate.');
        return;
    }

    if ($vec->has_value) {
        unless (@{$vec->value} % 2 == 0) {
            $message->response->raise("Scope's variable vector must contain an event number of members. Yours had %d.", scalar(@{$vec->value}));
            return;
        }

        my $tf = App::RoboBot::TypeFactory->new( bot => $self->bot );

        my @vars = @{$vec->value};

        while (@vars > 0) {
            my $name = shift @vars;

            unless (defined $name && blessed($name) && $name->type eq 'String') {
                $message->response->raise('Vector must be pairs of variable names and their definitions. Names must be provided as scalars, not expressions or complex structures.');
                return;
            }

            # We do not want to ->evaluate these, as that will choke in the
            # event of a re-used variabe name from an outer scope.
            $name = $name->value;

            my $def = shift @vars;

            unless (defined $def && blessed($def) && $def->can('evaluate')) {
                $message->response->raise('Variables require a definition.');
                return;
            }

            # By default we're going to mask a conflicting variable name from
            # the outer scope, but any valid definition is going to end up
            # replacing this with an actual value.
            $new_scope{$name} = undef;

            if ($def->quoted) {
                $new_scope{$name} = $def;
            } elsif ($def->type eq 'String' || $def->type eq 'Number') {
                $new_scope{$name} = $def->evaluate($message, \%new_scope);
            } elsif ($def->type eq 'Vector' || $def->type eq 'Set' || $def->type eq 'Map') {
                # Evaluate the structure provided in the definition and create a
                # new one of the same type from the results.
                $new_scope{$name} = $tf->build($def->type, [$def->evaluate($message, \%new_scope)]);
            } elsif ($def->type eq 'List' || $def->type eq 'Expression') {
                my @val = $def->evaluate($message, \%new_scope);

                if (@val) {
                    if (@val == 1) {
                        $new_scope{$name} = $val[0];
                    } elsif (@val > 1) {
                        $new_scope{$name} = $tf->build('List', \@val);
                    }
                }
            } else {
                $message->response->raise('Variables may currently only be strings, vectors, lists, maps, and sets. Your variable definition for %s violates this.', $name);
                return;
            }
        }
    }

    my @r;

    foreach my $form (@forms) {
        unless (blessed($form) && $form->can('evaluate')) {
            $message->response->raise('Child forms must be lists or expressions to be evaluated within the current scope.');
            return;
        }

        @r = $form->evaluate($message, \%new_scope);
    }

    return @r;
}

__PACKAGE__->meta->make_immutable;

1;
