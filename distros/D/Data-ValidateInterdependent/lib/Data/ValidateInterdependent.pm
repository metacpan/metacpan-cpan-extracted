package Data::ValidateInterdependent;
use utf8;
use v5.14;
use warnings;
our $VERSION = '0.000001';

use Moo;
use Carp;

=encoding UTF-8

=head1 NAME

Data::ValidateInterdependent - safely validate interdependent parameters

=head1 SYNOPSIS

    use Data::ValidateInterdependent;

    state $validator =
        Data::ValidateInterdependent->new
        # inject a constant value
        ->const(generator => 'perl')
        # take an input parameter without validation
        ->param('description')
        # create variables "x", "y", "z" from parameter "coords"
        ->validate(['x', 'y', 'z'], '$coords', sub {
            my ($coords) = @_;
            die "Coords must contain 3 elements" unless @$coords == 3;
            my ($x, $y, $z) = @$coords;
            return { x => $x, y => $y, z => $z };
        })
        # create variable "title" from parameter "title"
        # and from validated variables "x", "y", "z".
        ->validate('title', ['$title, 'x', 'y', 'z'], sub {
            my ($title, $x, $y, $z) = @_;
            $title //= "Object at ($x, $y, $z)";
            return { title => $title };
        });

    my $variables = $validator->run(%config);

=head1 DESCRIPTION

The problem: you need to validate some configuration.
But validation of one field depends on other fields,
or default values are taken from other parts of the config.
These dependencies can be daunting.

This module makes the dependencies between different validation steps
more explicit:
Each step declares which variables it provides,
and which variables or input parameters it consumes.
The idea of
L<Static Single Assignment|https://en.wikipedia.org/wiki/Static_single_assignment_form>
allows us to check basic consistency properties when the validator is assembled:

=over

=item *

The validator will provide all declared output variables.
Because there is no branching,
it is not possible to forget a variable.

=item *

All variables are declared before they are used.
It is not possible to accidentally read an unvalidated value.

=item *

Each variable is only initialized once.
It is not possible to accidentally overwrite a variable.

=back

=head2 Terminology

A B<parameter> is an unvalidated input value.
A parameter called C<name> can be addressed with the symbol C<$name>,
i.e. with a prepended C<$> character.
If no such parameter exists, its value will be C<undef>.

A B<variable> is a validated field that will be written exactly once.
A variable called C<name> is addressed with the symbol C<name>,
i.e. without any changes.

A B<validation rule> is a callback that initializes one or more variables.
It receives a list with any number of parameters and variables.

=head1 METHODS

Unless explicitly noted,
all methods return the object itself
so that you can chain methods.

=cut

# the static environment
has _variables => (
    is => 'ro',
    default => sub { {} },
);

has _unused_variables => (
    is => 'ro',
    default => sub { {} },
);

has _rules => (
    is => 'ro',
    default => sub { [] },
);

has _known_params => (
    is => 'ro',
    default => sub { {} },
);

has _ignore_unknown => (
    is => 'rw',
    default => 0,
);

sub _parse_params {
    my ($spec) = @_;
    return @$spec if ref $spec eq 'ARRAY';
    return $spec;
}

sub _declare_variable {
    my ($self, @names) = @_;

    my $known = $self->_variables;
    my $unused = $self->_unused_variables;
    for my $var (@names) {
        if ($known->{$var}) {
            croak qq(Variable cannot be declared twice: $var);
        }
        else {
            $known->{$var} = 1;
            $unused->{$var} = 1;  # all are unused initially
        }
    }

    return;
}

sub _declare_usage {
    my ($self, $name, @vars) = @_;

    my $known_variables = $self->_variables;
    my $unused = $self->_unused_variables;

    if (my @unknown = grep { not $known_variables->{$_} } @vars) {
        croak qq($name depends on undeclared variables: ), join q(, ) => sort @unknown;
    }

    delete @$unused{@vars};

    return;
}

sub _declare_param {
    my ($self, @names) = @_;
    my $known_params = $self->_known_params;

    $known_params->{$_} = 1 for @names;

    return;
}

=head2 const

    $validator = $validator->const(name => $value, ...);

Declare one or more variables with a constant value.

In most cases this is not necessary
because you could use Perl variables
to make data accessible to all pipeline steps.

Note that this method cannot provide default values for a variable,
since all variables are write-once.

This method is functionally equivalent to:

    $validator->validate(['name', ...], [], sub {
        return { name => $value, ... };
    });

=cut

sub const {
    my ($self, %values) = @_;
    # TODO must not be empty

    _declare_variable($self, sort keys %values);
    push @{ $self->_rules }, [const => \%values];
    return $self;
}

=head2 param

    $validator = $validator->param('name', { variable => 'parameter' }, ...);

Declare variables that take their value directly from input parameters
without any validation.

The arguments may be variable names,
in which case the value is taken from the parameter of the same name.
The arguments may also be a hash ref,
which maps variable names to parameters.
These names are not symbols,
so you must not include the C<$> for parameter symbols.

Absolutely no validation will be performed.
If the parameter does not exist, the variable will be C<undef>.

This method is functionally equivalent to:

    $validator->validate(['name', 'variable', ...], ['$name', '$parameter'], sub {
        my ($name, $parameter, ...) = @_;
        return { name => $name, variable => $parameter, ... };
    });

=cut

sub param {
    my ($self, @items) = @_;
    # TODO must not be empty

    my %mapping;
    for my $item (@items) {
        $item = { $item => $item } if ref $item ne 'HASH';
        @mapping{ keys %$item } = values %$item;
    }

    _declare_param($self, sort values %mapping);
    _declare_variable($self, sort keys %mapping);

    push @{ $self->_rules }, [param => \%mapping];

    return $self;
}

=head2 validate

    $validator = $validator->validate($output, $input, sub { ... });

Perform a validation step.

B<$output> declares the variables which are assigned by this validation step.
It may either be a single variable name,
or an array ref with one or more variable names.

B<$input> declares dependencies on other variables or input parameters.
It may either be a single symbol,
or an array ref of symbols.
The array ref may be empty.
A symbol can be the name of a variable,
or a C<$> followed by the name of a parameter.

B<sub { ... }> is a callback that peforms the validation step.
The callback will be invoked with the values of all I<$input> symbols,
in the order in which they were listed.
Note that a parameter will have C<undef> value if it doesn't exist.
The callback must return a hash ref that contains all variables to be assigned.
The hash keys must match the declared I<$output> variables exactly.

The returned hash ref will be modified.
If other code depends on this hash ref, return a copy instead.

B<Throws> when an existing variable was re-declared.
All variables are write-once.
You cannot reassign them.

B<Throws> when an undeclared variable was used.
You must declare all variables before you can use them.

B<Example:> Reading multiple inputs:

    # "x" and "y" are previously declared variables.
    # "foo" is an input parameter.
    $validator->validate('result', ['x', '$foo', 'y'], sub {
        my ($x, $foo, $y) = @_;
        $foo //= $y;
        return { result => $x + $foo };
    });

=cut

sub validate {
    my ($self, $output, $input, $callback) = @_;
    $output = [_parse_params($output)];
    $input = [_parse_params($input)];

    if (not @$output) {
        croak q(Validation rule must provide at least one variable);
    }

    my @vars;
    my @args;
    for (@$input) {
        if (/^\$/) {
            push @args, s/^\$//r;
        }
        else {
            push @vars, $_;
        }
    }

    _declare_param($self, @args) if @args;
    _declare_usage($self, qq(Validation rule "@$output"), @vars);
    _declare_variable($self, @$output);

    push @{ $self->_rules }, [rule => $output, $input, $callback];
    return $self;
}

=head2 run

    my $variables = $validator->run(%params);

Run the validator with a given set of params.
A validator instance can be run multiple times.

B<%params> is a hash of all input parameters.
The hash may be empty.

B<Returns:> a hashref with all output variables.
If your validation rules assigned helper variables,
you may want to delete them from this hashref before further processing.

B<Throws:> when unknown parameters were provided
(but see L<ignore_unknown()|/ignore_unknown>).

B<Throws:> when a rule callback did not return a suitable value:
either it was not a hash ref,
or the hash ref did not assign exactly the $output variables.

=cut

sub run {
    my ($self, %params) = @_;

    unless ($self->_ignore_unknown) {
        my $known_params = $self->_known_params;
        if (my @unknown = grep { not $known_params->{$_} } keys %params) {
            croak qq(Unknown parameters: ), join q(, ) => sort @unknown;
        }
    }

    my %variables;

    my $get_arg = sub {
        my ($name) = @_;
        return $params{$name} if $name =~ s/^\$//;
        return $variables{$name};
    };

    RULE:
    for my $rule (@{ $self->_rules }) {
        my ($type, @rule_args) = @$rule;

        if ($type eq 'const') {
            my ($values) = @rule_args;
            @variables{keys %$values} = values %$values;
            next RULE;
        }

        if ($type eq 'param') {
            my ($mapping) = @rule_args;
            @variables{ keys %$mapping } = @params{ values %$mapping };
            next RULE;
        }

        if ($type eq 'rule') {
            my ($provided, $required, $callback) = @rule_args;

            my $result = $callback->(map { $get_arg->($_) } @$required);

            for my $var (@$provided) {
                if (exists $result->{$var}) {
                    $variables{$var} = delete $result->{$var};
                }
                else {
                    croak qq(Validation rule "@$provided" must return parameter $var);
                }
            }

            if (my @unknown = keys %$result) {
                croak qq(Validation rule "@$provided" returned unknown variables: ),
                    join q(, ) => sort @unknown;
            }

            next RULE;
        }

        die "Unknown rule type: $type";
    }

    return \%variables;
}

=head2 ignore_unknown

    $validator = $validator->ignore_unknown;

Ignore unknown parameters.
If this flag is not set, the L<run()|/run> method will die
when unknown parameters were provided.
A parameter is unknown when no validation rule or param assignment
reads from that parameter.

=cut

sub ignore_unknown {
    my ($self) = @_;
    $self->_ignore_unknown(1);
    return $self;
}

=head2 ignore_param

    $validator = $validator->ignore_param($name, ...);

Ignore a specific parameter.

=cut

sub ignore_param {
    my ($self, @names) = @_;
    _declare_param($self, @names);
    return $self;
}

=head2 provided

    my @names = $validator->provided;

Get a list of all provided variables.
The order is unspecified.

=cut

sub provided {
    my ($self) = @_;
    return keys %{ $self->_variables };
}

=head2 unused

    my @names = $validator->unused;

Get a list of all variables that are provided but not used.
The order is unspecified.

=cut

sub unused {
    my ($self) = @_;
    return keys %{ $self->_unused_variables };
}

=head2 select

    $validator = $validator->select(@names);

Mark variables as used, and ensure that these variables exist.

This is convenient when the validator is assembled in different places,
and you want to make sure that certain variables are provided.

The output variables may include variables that were not selected.
This method does not list all output variables,
but just ensures their presence.

=cut

sub select :method {
    my ($self, @names) = @_;
    _declare_usage($self, q(Select), @names);
    return $self;
}

=head1 SUPPORT

Homepage: L<https://github.com/latk/p5-Data-ValidateInterdependent>

Bugtracker: L<https://github.com/latk/p5-Data-ValidateInterdependent/issues>

=head1 AUTHOR

amon – Lukas Atkinson (cpan: AMON) <amon@cpan.org>

=head1 COPYRIGHT

Copyright 2017 Lukas Atkinson

This library is free software and may be distributed under the same terms
as perl itself. See http://dev.perl.org/licenses/.

=cut

1;
