use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::RuleGenerator;

sub new {
    my ($pkg, $size, $alphabet) = @_;
    my $self = { size => $size, states => $alphabet, input_list => [], 
                 avg => 0, parts => $alphabet ** $size }; # count of partial rules
    
    my @input = (0) x $size;
    $self->{'input_list'}[0] = [@input];
    $self->{'input_pattern'}  [0] = join '', @input;
    if ($self->{'parts'} > 30 ) {
        $self->{'parts'} = ($alphabet-1) * $size + 1;
        $self->{'avg'} = 1; # here we do averaging to min amount of pastial rules
        my $cursor_pos = 0;
        for my $i (1 .. $self->{'parts'} - 1){
            $cursor_pos++ if $input[$cursor_pos] == $alphabet - 1;
            $input[$cursor_pos]++;
            $self->{'input_list'}[$i] = [@input];
            $self->{'input_pattern'}  [$i] = join '', @input;
        }
    } else {
        for my $i (1 .. $self->{'parts'} - 1){
            for my $cp (0 .. $size - 1){
                $input[$cp]++;
                last if $input[$cp] < $alphabet;
                $input[$cp] = 0;
            }
            $self->{'input_list'}[$i]    = [reverse @input];
            $self->{'input_pattern'}[$i] = join '', @input;
        }            
    }
    $self->{'part_iterator'} = [ 0 .. $self->{'parts'} - 1];
    for my $i (@{$self->{'part_iterator'}}){
        $self->{'index_from_pattern'}{ $self->{'input_pattern'}[$i] } = $i;
    }
    $self->{'max_nr'} = ($alphabet ** ($self->{'parts'} + 1)) - 1;

    for my $i (@{$self->{'part_iterator'}}){
        $self->{'symmetry_partner'}[ $i ] = $self->{'index_from_pattern'}{ join '', reverse @{$self->{'input_list'}[$i]} };
    }
    bless $self;
}


sub part_rule_iterator { @{$_[0]->{'part_iterator'}} }

sub nr_from_input_list {
    my ($self) = shift;
    my $pattern = join '', @_;
    $self->{'index_from_pattern'}{ $pattern } if exists $self->{'index_from_pattern'}{ $pattern };    
}

sub input_list_from_nr {
    my ($self, $rule) = @_;
    @{$self->{'input_list'}[$rule]} if exists $self->{'input_list'}[$rule];
}

sub input_pattern_from_nr {
    my ($self, $sub_rule_nr) = @_;
    $self->{'input_pattern'}[$sub_rule_nr] if exists $self->{'input_pattern'}[$sub_rule_nr];
}

sub nr_from_output_list {
    my ($self) = shift;
    my $number = 0;
    my $base = 1;
    for (@_){
        $number += $_ * $base;
        $base *= $self->{'states'};
    }
    $number;
}

sub output_list_from_nr {
    my ($self, $rule) = @_;
    my $base = $self->{'states'};
    my $nr = ($self->{'max_nr'}+1) / $base;
    reverse map { $rule %= $nr; $nr /= $base; int $rule / $nr } $self->part_rule_iterator;

}

sub prev_nr {
    my ($self, $nr) = @_;
    $nr < 0 ? $self->{'max_nr'} : $nr - 1;
}

sub next_nr {
    my ($self, $nr) = @_;
    $nr > $self->{'max_nr'} ? 0 : $nr + 1;
}

sub shift_nr_left {
    my ($self, $nr) = @_;
    my @old_list = $self->list_from_nr( $nr );
    push @old_list, shift @old_list;
    @old_list;
}

sub shift_nr_right {
    my ($self, $nr) = @_;
    my @old_list = $self->list_from_nr( $nr );
    unshift @old_list, pop @old_list;
    @old_list;
}

sub opposite_nr {
    my ($self, $nr) = @_;
    my @old_list = $self->list_from_nr( $nr );
    map { $old_list[ $self->{'parts'} - $_ - 1] } @{$self->{'input_nr'}};
}

sub symmetric_nr {
    my ($self, $nr) = @_;
    my @old_list = $self->list_from_nr( $nr );
    map { $old_list[ $self->{'symmetry_partner'}[$_] ] } @{ $self->{'input_nr'} };
}


sub inverted_nr { 
    my ($self, $nr) = @_;
    $nr //= 0;
    $self->{'max_nr'} - $nr
}

sub random_nr { 
    my ($self) = @_;
    int rand $self->{'max_nr'} + 1;
}

1;
__END__
