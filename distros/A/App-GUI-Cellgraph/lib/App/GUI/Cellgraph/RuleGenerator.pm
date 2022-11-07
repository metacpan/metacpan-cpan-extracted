use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::RuleGenerator;

sub new {
    my ($pkg, $size, $states) = @_;
    my $self = {size => $size, states => $states, in_list => [], };
    $self->{'parts'} = 2 ** $size;
    $self->{'max_nr'} = (2 ** $self->{'parts'}) - 1;
    $self->{'input_nr'} = [ 0 .. $self->{'parts'} - 1];
    my $pattern = '%0'.$size.'b';
    for my $part (@{$self->{'input_nr'}}) {
        my $bin = sprintf $pattern, $part;
        push @{$self->{'in_list'}}, [split "", $bin];
        $self->{'symmetry_partner'}[ $part ] = nr_from_list($self,  @{$self->{'in_list'}[ $part ]});
    }
    bless $self;
}


sub nr_from_list {
    my ($self) = shift;
    my $number = 0;
    for (reverse @_){
        $number <<= 1;
        $number++ if $_;
    }
    $number;
}

sub list_from_nr {
    my ($self, $rule) = @_;
    $rule = int $rule;
    $rule = $self->{'max_nr'} if $rule > $self->{'max_nr'};
    $rule =                 0 if $rule < 0;
    $rule <<= 1;
    map { $rule >>= 1; $rule & 1 } @{$self->{'input_nr'}};
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
