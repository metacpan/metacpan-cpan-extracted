use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Grid;

my $temp = [];

sub get {
    my ($size, $rules, $start) = @_;
    return unless ref $rules eq 'HASH'and ref $start eq 'HASH';
    my $transfer_function = $rules->{'f'};
    my $action_function = $rules->{'action_f'};
    my $rule_size = $rules->{'size'};
    my @start = @{ $start->{'list'} };
    my $grid = [ [] ];
    my ($size_x, $size_y);
    if (ref $size eq 'ARRAY'){
        $size_x = $size->[0];
        $size_y = $size->[1];
    } else {
        $size_x = $size;
        $size_y = $size;
    }
    $size_x *= 3;
    if (ref $start[0]) {
        shift @start;
        my @repeat = @start;
        push @start, @repeat for 1 .. int $size_x / @start;
    } else {
        if (@start < $size_x){
            push @start, (0) x int( ($size_x - @start) / 2);
            unshift @start, (0) x ($size_x - @start);
            $grid->[0] = \@start;
        }
    }
    $grid->[0] = [splice @start, 0, $size_x];
    my $agrid  = [ [(1) x $size_x] ];
    
    for my $row_i (1 .. $size_y - 1) { # compute next rows
        my $row = $grid->[$row_i] = [];
        my $brow = $grid->[$row_i-1];
        my $bact = $agrid->[$row_i-1];
        my $val = $brow->[0];          # prerun for rule size
        my $act = $agrid->[$row_i]  = [(0) x $size_x];
        $val <<= 1;
        $val += $brow->[1];
        $val %= 8;
        $row->[0]  = $bact->[0] ? $transfer_function->[ $val ] : $brow->[0];
        $act->[0] |= 1 if $action_function->[ $val ] & 2;
        $act->[1] |= 1 if $action_function->[ $val ] & 1;            
        for my $cell_i (1 .. $size_x - 2){
            $val <<= 1;
            $val += $brow->[$cell_i+1];
            $val %= 8;
            $row->[$cell_i] = $bact->[$cell_i] ? $transfer_function->[ $val ] : $brow->[$cell_i];
            $act->[$cell_i-1] |= 1 if $action_function->[ $val ] & 4;
            $act->[$cell_i  ] |= 1 if $action_function->[ $val ] & 2;
            $act->[$cell_i+1] |= 1 if $action_function->[ $val ] & 1;            
        }
        # for (1 .. $rule_size - 1)
        {
            $val <<= 1; # last two elements are special
            $val %= 8;
            my $cell_i = $size_x - 1;
            $row->[$cell_i] = $bact->[$cell_i] ? $transfer_function->[ $val ] : $brow->[$cell_i];
            $act->[$cell_i-1] |= 1 if $action_function->[ $val ] & 4;
            $act->[$cell_i  ] |= 1 if $action_function->[ $val ] & 2;
        }
    }
    $grid;
}

1;
