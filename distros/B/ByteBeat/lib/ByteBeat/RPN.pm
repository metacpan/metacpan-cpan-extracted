package ByteBeat::RPN;
use Pegex::Base;

extends 'Pegex::Tree';

has rpn => ();

sub gotrule {
    my ($self, $list) = @_;
    return $list unless ref $list;
    if ($self->rule eq 'power') {
        while (@$list > 1) {
            my ($a, $b) = splice(@$list, -2, 2);
            push @$list, [$a, $b, '**'];
        }
    }
    else {
        while (@$list > 1) {
            my ($a, $op, $b) = splice(@$list, 0, 3);
            unshift @$list, [$a, $b, $op];
        }
    }
    return $list;
}

sub final {
    my ($self, $got) = @_;
    $self->rpn($self->flatten($got));
    return $self;
}

sub run {
    my ($self, $t) = @_;
    my $rpn = [ map { /t/ ? $t : $_ } @{$self->{rpn}} ];
    evaluate($rpn);
}

sub evaluate {
    my ($rpn) = @_;
    return $rpn->[0] if @$rpn == 1;
    my $op = pop @$rpn;
    my $b = get_value($rpn);
    my $a = get_value($rpn);
    return
        $op eq '^'  ? $a ^ $b :
        $op eq '|'  ? $a | $b :
        $op eq '&'  ? $a & $b :
        $op eq '>>' ? $a >> $b :
        $op eq '<<' ? $a << $b :
        $op eq '+'  ? $a + $b :
        $op eq '-'  ? $a - $b :
        $op eq '*'  ? $a * $b :
        $op eq '/'  ? $a / $b :
        $op eq '%'  ? $a % $b :
        $op eq '**' ? $a ** $b :
        die "Unknown operator '$op'";
}

sub get_value {
    my ($rpn) = @_;
    if (ref($rpn->[-1]) eq 'ARRAY') {
        evaluate(pop @$rpn);
    }
    elsif ($rpn->[-1] !~ /^\d+$/) {
        evaluate($rpn);
    }
    else {
        pop @$rpn;
    }
}

1;
