
# compute sub_rule_nr (by input)

use v5.12;
use warnings;
use Wx;
package App::GUI::Cellgraph::Compute::Subrule;

sub new {
    my ($pkg, $input_size, $state_count, $mode) = @_;
    return unless defined $state_count and $state_count;
    $mode //= 'all';
    bless compute_subrules( {}, $input_size, $state_count, $mode );
}
sub renew {
    my ($self, $input_size, $state_count, $mode) = @_;
    return unless defined $state_count and $state_count;
    $mode //= 'all';
    $self->compute_subrules( $input_size, $state_count, $mode );
}

sub compute_subrules {
    my ($self, $input_size, $state_count, $mode) = @_;
    $self->{'input_size'} = $input_size;
    $self->{'state_count'} = $state_count;
    $self->{'mode'} = $mode;
    $self->{'subrule_count'} = $state_count ** $input_size;
    $self->{'independent_subrules'} = $self->{'subrule_count'};
    $self->{'input_list'} = [];
    $self->{'input_pattern'} = [];
    $self->{'input_pattern_index'} = {};
    $self->{'input_symmetric_partner'} = [];
    $self->{'subrule_mapping'} = [];
    $self->{'input_indy_pattern'} = [];

    $self->{'input_list'} = [ permutations( $self, $input_size, $state_count )];
    for my $i (0 .. $self->{'subrule_count'} - 1){
        $self->{'input_pattern'}[$i] = join '', @{$self->{'input_list'}[$i]};
        $self->{'input_pattern_index'}{ $self->{'input_pattern'}[$i] } = $i;
    }
    for my $i (0 .. $self->{'subrule_count'} - 1) {
        my $l = $self->{'input_list'}[$i];
        my $rev_pattern = join '', reverse @$l;
        $self->{'input_symmetric_partner'}[$i] = $self->{'input_pattern_index'}{$rev_pattern};
    }

    if ($mode eq 'all' ) {
        @{$self->{'subrule_mapping'}} = 0 .. $self->{'subrule_count'} - 1;
        $self->{'input_indy_pattern'} = [ @{$self->{'input_pattern'}} ];
    } elsif ($mode eq 'symmetric' ) {
        my $map_nr = 0;
        for my $i (0 .. $self->{'subrule_count'} - 1) {
            if ($self->{'input_symmetric_partner'}[$i] < $i) { # get mapped to symmetric partner
                $self->{'subrule_mapping'}[$i] = $self->{'subrule_mapping'}[ $self->{'input_symmetric_partner'}[$i] ];
                $self->{'independent_subrules'}--;
            } else { # is uniq
                $self->{'subrule_mapping'}[$i] = $map_nr;
                $self->{'input_indy_pattern'}[$map_nr++] = $self->{'input_pattern'}[$i];
            }
        }
    } elsif ($mode eq 'sorted' ) {
        my $map_nr = 0;
        for my $i (0 .. $self->{'subrule_count'} - 1) {
            my $sorted_pattern = join '', sort @{$self->{'input_list'}[$i]};
            my $pattern = $self->{'input_pattern'}[$i];
            if ($sorted_pattern ne $pattern){ # get mapped to sorted
                $self->{'subrule_mapping'}[$i] =
                    $self->{'subrule_mapping'}[ $self->{'input_pattern_index'}{$sorted_pattern} ];
                $self->{'independent_subrules'}--;
            } else { # is uniq
                $self->{'subrule_mapping'}[$i] = $map_nr;
                $self->{'input_indy_pattern'}[$map_nr++] = $pattern;
            }
        }
    } else { # summing mode
        $self->{'independent_subrules'} = ($state_count-1) * $input_size + 1;
        for my $i (0 .. $self->{'subrule_count'} - 1) {
            my $sum = 0;
            map {$sum += $_} @{$self->{'input_list'}[$i]};
            $self->{'subrule_mapping'}[$i] = $sum;
        }
        my @input = (0) x ($input_size);
        $self->{'input_indy_pattern'}[0] = join '', @input;
        for my $pos (0 .. $input_size - 1){
            for my $new_state (1 .. $state_count-1){
                $input[$pos] = $new_state;
                push @{$self->{'input_indy_pattern'}}, join '', reverse @input;
            }
        }
    }

    $self;
}

########################################################################

sub permutations {
    my ($self, $pos, $states) = @_;
    my @el = ((0) x $pos);
    my @perm = ([@el]);
    for my $i (1 .. ($states ** $pos) - 1){
        for my $cell_pos (0 .. $pos - 1) {
            $el[$cell_pos]++;
            last if $el[$cell_pos] < $states;
            $el[$cell_pos] = 0;
        }
        push @perm, [reverse @el];
    }
    return @perm;
}

########################################################################

sub input_size                 { $_[0]->{'input_size'} }
sub state_count                { $_[0]->{'state_count'} }
sub mode                       { $_[0]->{'mode'} }
sub max_count                  { $_[0]->{'subrule_count'} }
sub independent_count          { $_[0]->{'independent_subrules'} }
sub input_patterns             { @{$_[0]->{'input_pattern'}} }
sub independent_input_patterns { @{$_[0]->{'input_indy_pattern'}} }
sub index_iterator             { 0 .. $_[0]->{'independent_subrules'} - 1 }
########################################################################

sub all_pattern { @{$_[0]->{'input_pattern'}} }

sub effective_pattern_nr {
    my ($self, $pattern) = @_;
    return unless exists $self->{'input_pattern_index'}{$pattern};
    $self->{'subrule_mapping'}[ $self->{'input_pattern_index'}{$pattern} ];
}

sub input_list_from_index {
    my ($self, $index) = @_;
    @{$self->{'input_list'}[$index]} if exists $self->{'input_list'}[$index];
}

sub index_from_input_list {
    my ($self) = shift;
    my $pattern = join '', reverse @_;
    $self->{'input_pattern_index'}{ $pattern } if exists $self->{'input_pattern_index'}{ $pattern };
}

sub input_pattern_from_subrule_nr {
    my ($self, $sub_rule_nr) = @_;
    $self->{'input_indy_pattern'}[$sub_rule_nr] if exists $self->{'input_indy_pattern'}[$sub_rule_nr];
}


1;
