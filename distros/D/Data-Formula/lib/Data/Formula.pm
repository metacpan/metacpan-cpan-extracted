package Data::Formula;

use warnings;
use strict;
use utf8;
use 5.010;

use List::MoreUtils qw(any);
use Moose;

our $VERSION = '0.01';

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
    '(' => {
        method => 'bracket_left',
    },
    ')' => {
        method => 'bracket_right',
    },
);

has 'variables'      => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'formula'        => ( is => 'ro', isa => 'Str', default => sub { [] } );
has '_tokens'        => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1, );
has '_rpn'           => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1, );
has '_op_indent'     => ( is => 'rw', isa => 'Int', default => 0, );
has 'used_variables' => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1, );

sub _indented_operator {
    my ($self,$op) = @_;
    return {
        name => $op,
        %{$operators{$op}},
        prio => ($operators{$op}->{prio}+($self->_op_indent*100)),
    };
}

sub _build__rpn {
    my ($self) = @_;

    my $rpn = [];
    my $ops = [];
    foreach my $token (@{$self->_tokens}) {
        if ($operators{$token}) {
            my $rpn_method = '_rpn_method_'.$operators{$token}->{method};
            ($rpn,$ops) = $self->$rpn_method($rpn,$ops)
        }
        else {
            push(@$rpn, $token);
        }
    }

    return [@$rpn,reverse(@$ops)];
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

sub rpn_standard_operator {
    my ($self, $cur_op, $rpn, $ops) = @_;
    my $prio = $operators{$cur_op}->{prio}+($self->_op_indent*100);
    if (@$ops) {
        while (@$ops) {
            my $prev_op = $ops->[-1];
            if ($prev_op->{prio} >= $prio) {
                push(@$rpn,pop(@$ops));
            }
            else {
                last;
            }
        }
    }
    push(@$ops,$self->_indented_operator($cur_op));

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
        grep { $_ !~ m/^[0-9]+$/ }
        grep { !$operators{$_} }
        @{$self->_tokens}
    ];
}

sub _build__tokens {
    my ($self) = @_;

    my @tokens;
    my $formula = $self->formula;
    $formula =~ s/\s//g;

    my $op_regexp = join('',map { q{\\}.$_ } keys %operators);
    my $op_regexp_with_variable = '^([^'.$op_regexp.']*?)(['.$op_regexp.'])';
    while ($formula =~ m/$op_regexp_with_variable/) {
        my $variable = $1;
        my $operator = $2;
        push(@tokens, $variable) if length($variable);
        push(@tokens, $operator);
        $formula = substr($formula,length($variable.$operator));
    }
    if (length($formula)) {
        push(@tokens, $formula);
    }

    return [
        map {
            $_ =~ m/^[0-9]+$/
            ? $_+0
            : $_
        } @tokens
    ];
}

sub _rpn_calc_plus {
    my ($self, $rpn) = @_;

    die 'not enough parameters left on stack'
        unless @$rpn > 1;

    my $val2 = pop(@$rpn);
    my $val1 = pop(@$rpn);

    push(@$rpn,$val1+$val2);
    return $rpn;
}
sub _rpn_calc_minus {
    my ($self, $rpn) = @_;

    die 'not enough parameters left on stack'
        unless @$rpn > 1;

    my $val2 = pop(@$rpn);
    my $val1 = pop(@$rpn);

    push(@$rpn,$val1-$val2);
    return $rpn;
}
sub _rpn_calc_multiply {
    my ($self, $rpn) = @_;

    die 'not enough parameters left on stack'
        unless @$rpn > 1;

    my $val2 = pop(@$rpn);
    my $val1 = pop(@$rpn);

    push(@$rpn,$val1*$val2);
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
            my $rpn_method = '_rpn_calc_'.$token->{calc};
            ($rpn) = $self->$rpn_method($rpn)
        }
        else {
            if (exists($variables{$token})) {
                push(@$rpn, $variables{$token} // 0);
            }
            else {
                push(@$rpn, $token);
            }
        }
    }

    return @$rpn[0];
}

1;


__END__

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
        variables => [qw( var212 var213 n274 n294 var314 var334 var354 var374 var394 )],
        formula   => 'var212 - var213 + var314 * (var354 + var394) - 10',
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

=head1 METHODS

=head2 new()

Object constructor.

     my $df = Data::Formula->new(
        formula   => 'var212 - var213 * var314 + var354',
     );

=head2 used_variables() 

return array with variables used in formula

=head2 calculate()

evaluate formula with values for variables, returns caluculated value

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 CONTRIBUTORS
 
The following people have contributed to the File::is by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advises, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    Andrea Pavlovic

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
