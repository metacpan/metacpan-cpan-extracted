
# compute rule_nr (by output)

package App::GUI::Cellgraph::Compute::Rule;
use v5.12;
use bigint;
use warnings;
use Wx;
use App::GUI::Cellgraph::Compute::History;

sub new {
    my ($pkg, $subrules) = @_;
    return unless ref $subrules eq 'App::GUI::Cellgraph::Compute::Subrule';

    my $rules = $subrules->independent_count;
    my $states = $subrules->state_count;
    bless { subrules => $subrules, subrule_result => [],
            max_rule_nr => ($states ** $rules), rule_nr => -1,
            history => App::GUI::Cellgraph::Compute::History->new(),
    };
}
sub renew {
    my ($self) = @_;
    my $sub_rule_count = $self->{'subrules'}->independent_count;
    $self->{'history'}->reset;
    pop @{$self->{'subrule_result'}} while @{$self->{'subrule_result'}} > $sub_rule_count;   # prevent undefined results
    push @{$self->{'subrule_result'}}, 0 while @{$self->{'subrule_result'}} < $sub_rule_count;
    $self->{'max_rule_nr'} = $self->{'subrules'}->state_count ** $sub_rule_count;
    $self->_update_rule_nr_from_results();
}

########################################################################

sub subrules { $_[0]->{'subrules'} }

sub get_rule_nr { $_[0]->{'rule_nr'} }
sub set_rule_nr {
    my ($self, $nr) = @_;
    return unless defined $nr and $nr !~ /e/;
    return if $nr < 0 and $nr >= $self->{'max_rule_nr'} and $nr == $self->{'rule_nr'};
    $_[0]->{'rule_nr'} = $nr;
}

sub _update_rule_nr_from_results { $_[0]->{'rule_nr'} = $_[0]->rule_nr_from_result_list( @{$_[0]->{'subrule_result'}} ) }
sub _is_state { (@_ == 2 and $_[1] >= 0 and $_[1] < $_[0]->{'subrules'}->state_count) ? 1 : 0 }
sub _is_index { (@_ == 2 and $_[1] >= 0 and $_[1] < $_[0]->{'subrules'}->independent_count) ? 1 : 0 }

sub get_subrule_result {
    my ($self, $index) = @_;
    return unless $self->_is_index( $index );
    $self->{'subrule_result'}[$index];
}
sub set_subrule_result {
    my ($self, $index, $result) = @_;
    return unless $self->_is_index( $index ) and $self->_is_state( $result );
    $self->{'subrule_result'}[$index] = int $result;
    $self->_update_rule_nr_from_results();
    $self->safe_result( );
}
sub get_subrule_results { @{$_[0]->{'subrule_result'}} }
sub set_subrule_results {
    my ($self, @result) = @_;
    return unless @result == $self->{'subrules'}->independent_count;
    @{$self->{'subrule_result'}} = @result;
    $self->_update_rule_nr_from_results();
    $self->safe_result( );
    @result;
}

sub result_from_pattern {
    my ($self, $pattern) = @_;
    my $nr = $self->{'subrules'}->effective_pattern_nr( $pattern );
    return unless defined $nr;
    $self->get_subrule_result( $nr );
}

sub rule_nr_from_result_list {
    my ($self, @results) = @_;
    return unless @results == $self->{'subrules'}->independent_count;
    my $sts = $self->{'subrules'}->state_count;
    my $rule_nr = 0;
    for my $result (reverse @results){
        $rule_nr *= $sts;
        $rule_nr += $result;
    }
    return $rule_nr;
}

sub result_list_from_rule_nr {
    my ($self, $nr) = @_;
    return unless defined $nr and $nr !~ /e/i;
    return if $nr < 0 and $nr >= $self->{'max_rule_nr'};
    my $sts = $self->{'subrules'}->state_count;
    my @result = ();
    while ($nr){
        my $rest = $nr % $sts;
        push @result, $rest;
        $nr -= $rest;
        $nr /= $sts;
    }
    while (@result < $self->{'subrules'}->independent_count){ push @result, 0 }
    return @result;
}

#### interface with history ############################################
sub safe_result { $_[0]->{'history'}->add_value( join '', $_[0]->get_subrule_results ) }
sub undo_results {
    my ($self) = @_;
    my $summary = $self->{'history'}->undo // return;
    return $self->set_subrule_results( split '', $summary );

}
sub redo_results {
    my ($self) = @_;
    my $summary = $self->{'history'}->redo // return;
    return $self->set_subrule_results( split '', $summary );
}

sub can_undo { $_[0]->{'history'}->can_undo }
sub can_redo { $_[0]->{'history'}->can_redo }

####rule nr functions ##################################################
sub prev_rule_nr {
    my ($self) = @_;
    my @result = $self->get_subrule_results;
    my $state_count = $self->{'subrules'}->state_count;
    my $pos = 0;
    while ($pos < @result){
        $result[$pos]--;
        last if $result[$pos] >= 0;
        $result[$pos] = $state_count - 1;
        $pos++;
    }
    $self->set_subrule_results( @result );
}
sub next_rule_nr {
    my ($self) = @_;
    my @result = $self->get_subrule_results;
    my $state_count = $self->{'subrules'}->state_count;
    my $pos = 0;
    while ($pos < @result){
        $result[$pos]++;
        last if $result[$pos] < $state_count;
        $result[$pos] = 0;
        $pos++;
    }
    $self->set_subrule_results( @result );
}
sub shift_rule_nr_left {
    my ($self) = @_;
    my @result = $self->get_subrule_results;
    unshift @result, pop @result;
    $self->set_subrule_results( @result );
}
sub shift_rule_nr_right {
    my ($self) = @_;
    my @result = $self->get_subrule_results;
    push @result, shift @result;
    $self->set_subrule_results( @result );
}
sub opposite_rule_nr {
    my ($self) = @_;
    my $sub_rules = $self->{'subrules'}->independent_count-1;
    my @old_result = $self->get_subrule_results;
    my @new_result = map { $old_result[ $sub_rules - $_] } $self->{'subrules'}->index_iterator;
    $self->set_subrule_results( @new_result );
}
sub symmetric_rule_nr {
    my ($self) = @_;
    my @old_result = $self->get_subrule_results;
    return @old_result unless $self->{'subrules'}->mode eq 'all';
    my @new_result = map { $old_result[ $self->{'subrules'}{'input_symmetric_partner'}[$_] ] }
        $self->{'subrules'}->index_iterator;
    $self->set_subrule_results( @new_result );
}
sub inverted_rule_nr {
    my ($self) = @_;
    my $max_state = $self->{'subrules'}->state_count - 1;
    my @new_result = map { $max_state - $_ } @{$self->{'subrule_result'}};
    $self->set_subrule_results( @new_result );
}
sub random_rule_nr {
    my ($self) = @_;
    my @result = map {int rand $self->{'subrules'}->state_count} $self->{'subrules'}->index_iterator;
    $self->set_subrule_results( @result );
}

1;
