package Data::Formula;

use warnings;
use strict;
use utf8;
use 5.010;

use List::MoreUtils qw(any);
use Moose;
use MooseX::StrictConstructor;
use Carp qw(croak);

our $VERSION = '0.02';
our @CARP_NOT;

my %operators = (
    '+' => {
        method => 'plus',
        calc   => 'plus',
        prio   => 10,
    },
    '-' => {
        method => 'minus',
        calc   => 'minus',
        prio   => 10,
    },
    '*' => {
        method => 'multiply',
        calc   => 'multiply',
        prio   => 50,
    },
    '/' => {
        method => 'divide',
        calc   => 'divide',
        prio   => 50,
    },
    '(' => {method => 'bracket_left',},
    ')' => {method => 'bracket_right',},
);

has 'variables'      => (is => 'rw', isa => 'ArrayRef', default    => sub {[]});
has 'formula'        => (is => 'ro', isa => 'Str',      default    => sub {[]});
has '_tokens'        => (is => 'ro', isa => 'ArrayRef', lazy_build => 1,);
has '_rpn'           => (is => 'ro', isa => 'ArrayRef', lazy_build => 1,);
has '_op_indent'     => (is => 'rw', isa => 'Int',      default    => 0,);
has 'used_variables' => (is => 'ro', isa => 'ArrayRef', lazy_build => 1,);

has 'on_error' => (
    is        => 'rw',
    predicate => 'has_on_error',
    clearer   => 'clear_on_error',
);
has 'on_missing_token' => (
    is        => 'rw',
    predicate => 'has_on_missing_token',
    clearer   => 'clear_on_missing_token',
);

sub _indented_operator {
    my ($self, $op) = @_;
    return {
        name => $op,
        %{$operators{$op}},
        prio => ($operators{$op}->{prio} + ($self->_op_indent * 100)),
    };
}

sub _build__rpn {
    my ($self) = @_;

    my $rpn = [];
    my $ops = [];
    foreach my $token (@{$self->_tokens}) {
        if ($operators{$token}) {
            my $rpn_method = '_rpn_method_' . $operators{$token}->{method};
            ($rpn, $ops) = $self->$rpn_method($rpn, $ops);
        }
        else {
            push(@$rpn, $token);
        }
    }

    return [@$rpn, reverse(@$ops)];
}

sub _rpn_method_plus {
    my ($self, $rpn, $ops) = @_;
    return $self->rpn_standard_operator('+', $rpn, $ops);
}

sub _rpn_method_minus {
    my ($self, $rpn, $ops) = @_;
    return $self->rpn_standard_operator('-', $rpn, $ops);
}

sub _rpn_method_multiply {
    my ($self, $rpn, $ops) = @_;
    return $self->rpn_standard_operator('*', $rpn, $ops);
}

sub _rpn_method_divide {
    my ($self, $rpn, $ops) = @_;
    return $self->rpn_standard_operator('/', $rpn, $ops);
}

sub rpn_standard_operator {
    my ($self, $cur_op, $rpn, $ops) = @_;
    my $prio = $operators{$cur_op}->{prio} + ($self->_op_indent * 100);
    if (@$ops) {
        while (@$ops) {
            my $prev_op = $ops->[-1];
            if ($prev_op->{prio} >= $prio) {
                push(@$rpn, pop(@$ops));
            }
            else {
                last;
            }
        }
    }
    push(@$ops, $self->_indented_operator($cur_op));

    return ($rpn, $ops);
}

sub _rpn_method_bracket_left {
    my ($self, $rpn, $ops) = @_;

    $self->_op_indent($self->_op_indent + 1);

    return ($rpn, $ops);
}

sub _rpn_method_bracket_right {
    my ($self, $rpn, $ops) = @_;

    $self->_op_indent($self->_op_indent - 1);

    return ($rpn, $ops);
}

sub _build_used_variables {
    my ($self, @rpn) = @_;

    return [
        grep {$_ !~ m/^[0-9]+$/}
        grep {!$operators{$_}} @{$self->_tokens}
    ];
}

sub _build__tokens {
    my ($self) = @_;

    my @tokens;
    my $formula = $self->formula;
    $formula =~ s/\s//g;

    my $op_regexp               = join('', map {q{\\} . $_} keys %operators);
    my $op_regexp_with_variable = '^([^' . $op_regexp . ']*?)([' . $op_regexp . '])';
    while ($formula =~ m/$op_regexp_with_variable/) {
        my $variable = $1;
        my $operator = $2;
        push(@tokens, $variable) if length($variable);
        push(@tokens, $operator);
        $formula = substr($formula, length($variable . $operator));
    }
    if (length($formula)) {
        push(@tokens, $formula);
    }

    return [map {$_ =~ m/^[0-9]+$/ ? $_ + 0 : $_} @tokens];
}

sub _rpn_calc_plus {
    my ($self, $rpn) = @_;

    die 'not enough parameters left on stack'
        unless @$rpn > 1;

    my $val2 = pop(@$rpn);
    my $val1 = pop(@$rpn);

    push(@$rpn, $val1 + $val2);
    return $rpn;
}

sub _rpn_calc_minus {
    my ($self, $rpn) = @_;

    die 'not enough parameters left on stack'
        unless @$rpn > 1;

    my $val2 = pop(@$rpn);
    my $val1 = pop(@$rpn);

    push(@$rpn, $val1 - $val2);
    return $rpn;
}

sub _rpn_calc_multiply {
    my ($self, $rpn) = @_;

    die 'not enough parameters left on stack'
        unless @$rpn > 1;

    my $val2 = pop(@$rpn);
    my $val1 = pop(@$rpn);

    push(@$rpn, $val1 * $val2);
    return $rpn;
}

sub _rpn_calc_divide {
    my ($self, $rpn) = @_;

    die 'not enough parameters left on stack'
        unless @$rpn > 1;

    my $val2 = pop(@$rpn);
    my $val1 = pop(@$rpn);

    die "Illegal division by zero\n"
        unless $val2;

    push(@$rpn, $val1 / $val2);
    return $rpn;
}

sub calculate {
    my ($self, %variables) = @_;

    if (@{$self->variables} == 0) {
        $self->variables([keys %variables]);
    }

    my $rpn = [];
    my $ops = [];
    foreach my $token (@{$self->_rpn}) {
        if (ref($token) eq 'HASH') {
            my $rpn_method = '_rpn_calc_' . $token->{calc};
            ($rpn) = eval {$self->$rpn_method($rpn)} // [];
            $self->_report_error($rpn, $@)
                if $@;
        }
        else {
            if (exists($variables{$token})) {
                push(@$rpn, $variables{$token} // 0);
            }
            elsif ($token =~ /^[+\-]?\d*\.?\d*$/) {
                push(@$rpn, $token);
            }
            else {
                if (my $on_missing = $self->has_on_missing_token) {
                    push(@$rpn, (ref($on_missing) eq 'CODE' ? $on_missing->($token) : $on_missing));
                }
                else {
                    $self->_report_error($rpn,
                        '"' . $token . '" is not a literal number, not a valid token');
                }
            }
        }
    }

    return @$rpn[0];
}

sub _report_error {
    my ($self, $rpn, $err) = @_;
    local @CARP_NOT = __PACKAGE__;
    chomp($err);
    if ($self->has_on_error) {
        my $on_err = $self->on_error;
        push(@$rpn, (ref($on_err) eq 'CODE' ? $on_err->($err) : $on_err));
    }
    else {
        croak($err);
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Data::Formula - formulas evaluation and calculation

=head1 SYNOPSIS

    my $df = Data::Formula->new(
        formula   => 'var212 - var213 * var314 + var354',
    );
    my $val = $df->calculate(
        var212 => 5,
        var213 => 10,
        var314 => 7,
        var354 => 100
    );
    # 5-(10*7)+100

    my $df = Data::Formula->new(
        variables        => [qw( var212 var213 n274 n294 var314 var334 var354 var374 var394 )],
        formula          => 'var212 - var213 + var314 * (var354 + var394) - 10',
        on_error         => undef,
        on_missing_token => 0,
    );
    my $used_variables = $df->used_variables;
    # [ var212 var213 var314 var354 var394 ]

    my $val = $df->calculate(
        var212 => 5,
        var213 => 10,
        var314 => 2,
        var354 => 3,
        var394 => 9,
    );
    # 5-10+2*(3+9)-10

=head1 DESCRIPTION

evaluate and calulate formulas with variables of the type var212 - var213 + var314 * (var354 + var394) - 10

=head1 ACCESSORS

=head2 formula

Formula for calculation. Required.

=head2 on_error

Sets what should L</calculate()> return in case of an error. When division
by zero happens or unknown tokens are found.

Can be a scalar value, like for example C<0> or C<undef>, or a code ref
that will be executed with error message as argument.

Optional, if not set L</calculate()> will throw an exception in case of an error.

=head2 on_missing_token

Sets what should happen when there is a missing/unknown token found in
formula.

Can be a scalar value, like fixed number, or a code ref
that will be executed with token name as argument.

Optional, if not set L</calculate()> will throw an exception with unknown tokens.

=head1 METHODS

=head2 new()

Object constructor.

     my $df = Data::Formula->new(
        formula   => 'var212 - var213 * var314 + var354',
     );

=head2 used_variables() 

return array with variables used in formula

=head2 calculate()

Evaluate formula with values for variables, returns calculated value.

Will throw expetion on division by zero of unknown variables, unless
changes by L</on_error> or L</on_missing_token>

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 CONTRIBUTORS
 
The following people have contributed to the File::is by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advises, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    Andrea Pavlovic
    Thomas Klausner

=head1 THANKS

Thanks to L<VÖV - Verband Österreichischer Volkshochschulen|http://www.vhs.or.at/>
for sponsoring development of this module.

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
