package Algorithm::BaumWelch;
use warnings;
use strict;
use Carp;
use Math::Cephes qw/:explog/;
use List::Util qw/sum/;
use Text::SimpleTable;

# vale a pena em fazer forward/backward com normalisation? e gamma!?!

=head1 NAME

Algorithm::BaumWelch - Baum-Welch Algorithm for Hidden Markov Chain parameter estimation.

=cut

=head1 VERSION

This document describes Algorithm::BaumWelch version 0.0.2

=cut

=head1 SYNOPSIS

    use Algorithm::BaumWelch;

    # The observation series see http://www.cs.jhu.edu/~jason/.
    my $obs_series = [qw/ obs2 obs3 obs3 obs2 obs3 obs2 obs3 obs2 obs2 
                          obs3 obs1 obs3 obs3 obs1 obs1 obs1 obs2 obs1 
                          obs1 obs1 obs3 obs1 obs2 obs1 obs1 obs1 obs2 
                          obs3 obs3 obs2 obs3 obs2 obs2
                     /];

    # The emission matrix - each nested array corresponds to the probabilities of a single observation type.
    my $emis = { 
        obs1 =>  [0.3, 0.3], 
        obs2 =>  [0.3, 0.4], 
        obs3 =>  [0.4, 0.3], 
               };

    # The transition matrixi - each row and column correspond to a particular state e.g. P(state1_x|state1_x-1) = 0.9...
    my $trans = [ 
                    [0.9, 0.1], 
                    [0.1, 0.9], 
                ];

    # The probabilities of each state at the start of the series.
    my $start = [0.5, 0.5];

    # Create an Algorithm::BaumWelch object.
    my $ba = Algorithm::BaumWelch->new;

    # Feed in the observation series.
    $ba->feed_obs($obs_series);

    # Feed in the transition and emission matrices and the starting probabilities.
    $ba->feed_values($trans, $emis, $start);

    # Alternatively you can randomly initialise the values - pass it the number of hidden states - 
    # i.e. to determine the parameters we need to make a first guess).
    # $ba->random_initialise(2);
     
    # Perform the algorithm.
    $ba->baum_welch;

    # Use results to pass data. 
    # In VOID-context prints formated results to STDOUT. 
    # In LIST-context returns references to the predicted transition & emission matrices and the starting parameters.
    $ba->results;

=cut

=head1 DESCRIPTION

The Baum-Welch algorithm is used to compute the parameters (transition and emission probabilities) of an Hidden Markov
Model (HMM). The algorithm calculates the forward and backwards probabilities for each HMM state in a series and then re-estimates the parameters of
the model. 

=cut

use version; our $VERSION = qv('0.0.2');

#r/ matrices de BW sao 1xN_states matrices - quer dizer quasi arrays - entao nao usa matrices reais. arrays são bastante
sub new {
    my $class = shift;
    my $self = [undef, undef, []]; bless $self, $class;
    return $self;
}

sub feed_obs {
    my ($self, $series) = @_;
    my %uniq;
    @uniq{@{$series}} = 1;
    my @obs = (keys %uniq);
    @obs = sort { $a cmp $b } @obs;
    $self->[0][0] = $series;
    $self->[0][1] = [@obs];
    $self->[0][2] = scalar @obs;
    return;
}

sub feed_values {
    croak qq{\nThis method expects 3 arguments.} if @_ != 4;
    my ($self, $trans, $emis, $start) = @_;
    croak qq{\nThis method expects 3 arguments.} if (ref $trans ne q{ARRAY} || ref $emis ne q{HASH} || ref $start ne q{ARRAY});
    my $obs_tipos = $self->[0][1];
    my $obs_numero = $self->[0][2];
    my $t_length = &_check_trans($trans);
    &_check_emis($emis, $obs_tipos, $obs_numero, $t_length);
    &_check_start($start, $t_length);
    $self->[1][0] = $trans;
    $self->[1][1] = $emis;
    $self->[1][2] = $start;
    my @stop; # 0.1/1 nao faz diferenca e para|comeca (stop|start) sempre iguala = 0
    for (0..$#{$trans}) { push @stop, 1 };
    $self->[1][3] = [@stop];
    return;
}

sub _check_start {
    my ($start, $t_length) = @_;
    croak qq{\nThere must be an initial probablity for each state in the start ARRAY.} if scalar @{$start} != $t_length;
    for (@{$start}) { croak qq{\nThe start ARRAY values must be numeric.} if !(/^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$/) };
    my $sum =0;
    for (@{$start}) { $sum += $_ }
    croak qq{\nThe starting probabilities must sum to 1.} if ($sum <= 0.95 || $sum >= 1.05);
    return;
}

sub _check_emis {
    my ($emis, $obs_tipos, $obs_numero, $t_length) = @_;
    my @emis_keys = (keys %{$emis});
    @emis_keys = sort {$a cmp $b} @emis_keys;
    croak qq{\nThere must be an entry in the emission matrix for each type of observation in the observation series.} if $obs_numero != scalar @emis_keys;
    for (0..$#emis_keys) { croak qq{\nThe observations in the emission matrix do not match those in the observation series.} if $emis_keys[$_] ne $obs_tipos->[$_]; }
    for (values %{$emis}) { 
        croak qq{\nThere must be a probability value for each state in the emission matrix.} if scalar @{$_} != $t_length;
        for my $cell (@{$_}) { croak qq{\nThe emission matrix values must be numeric.} if $cell !~ /^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$/; }
    }
    for my $i (0..$t_length-1) { # só fazendo 2-estado agora
        my $sum = 0;
        for my $o (@{$obs_tipos}) { $sum += $emis->{$o}[$i] }
        croak qq{\nThe emission matrix column must sum to 1.} if ($sum <= 0.95 || $sum >= 1.05);
    }
    return;
}

sub _check_trans {
    my $trans = shift;
    my $t_length = scalar @{$trans};
    for (@{$trans}) { 
        croak qq{\nThe transition matrix much be square.} if scalar @{$_} != $t_length;
        my $sum = 0;
        for my $cell (@{$_}) { 
            croak qq{\nThe transition matrix values must be numeric.} if $cell !~ /^[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$/;
            $sum += $cell
        }
        croak qq{\nThe transition matrix row must sum to 1.} if ($sum <= 0.95 || $sum >= 1.05);
    }
    return $t_length;
}

sub random_initialise {
    my ($self, $states) = @_;
    my $obs_names = $self->[0][1];
    my $trans = &_gera_trans($states);
    my $emis = &_gera_emis($states, $obs_names);
    my $start = &_gera_init($states);
    $self->[1][0] = $trans;
    $self->[1][1] = $emis;
    $self->[1][2] = $start;
    my @stop; # 0.1/1 nao faz diferenca e para|comeca (stop|start) sempre iguala = 0
    for (0..$states-1) { push @stop, 1 };
    $self->[1][3] = [@stop];
    return;
}

sub _gera_init {
    my $length = shift;
    my $sum = 0;
    my $init = [];
    srand;
    $#{$init} = $length-1; # só fazendo 2-estado agora
    for (@{$init}) { $_ = rand; $sum += $_ }
    #/ normalise such that sum is equal to 1
    for (@{$init}) { $_ /= $sum }
    return $init;
}

sub _gera_trans {
    my $length = shift;
    my $t = [];
    $#{$t} = $length-1; # só fazendo 2-estado agora
    #/ gera_init normalises
    for (@{$t}) { $_ = &_gera_init($length); }
    return $t;
}

sub _gera_emis {
    my ($length, $obs_names) = @_;
    my $e = {};
    srand;
    for (@{$obs_names}) { 
        my $init = [];
        $#{$init} = $length-1; # só fazendo 2-estado agora
        for (@{$init}) { $_ = rand;  }
        $e->{$_} = $init;
    }
    # para cada estado a suma deve iguala 1 - normalise such that sum of obs_x|state = 1
    for my $i (0..$length-1) { # só fazendo 2-estado agora
        my $sum = 0;
        for my $o (@{$obs_names}) { $sum += $e->{$o}[$i] }
        for my $o (@{$obs_names}) { $e->{$o}[$i] /= $sum }
    }
    #print qq{\n\nauto-gera emis de numeros aleatorios que sumam 1 para cada estado}; draw($e);
    return $e;
}

sub _forwardbackward_reestimacao {
    my $self = shift;
    my $obs_series = $self->[0][0];
    my $obs_types = $self->[0][1];
    my $trans = $self->[1][0];
    my $emis = $self->[1][1];
    my $start = $self->[1][2];
    my $stop = $self->[1][3];
    my $alpha = [];
    #y initialise
    for (0..$#{$trans}) { $alpha->[$_][0] = $start->[$_] * $emis->{$obs_series->[0]}[$_]; }
    #y not sure if i´ve extrapolated to higher-state number BW algorithm equations correctly?!?
    for my $n (1..$#{$obs_series}) {
        for my $s (0..$#{$trans}) {
            #push @{$alpha->[$s]}, ( ( ($alpha->[0][$n-1]*$trans->[$s][0]) + ($alpha->[1][$n-1]*$trans->[$s][1]) ) * $emis->{$obs_series->[$n]}[$s] ) ;
            my $sum = 0;
            for my $s_other (0..$#{$trans}) { $sum +=  $alpha->[$s_other][$n-1]*$trans->[$s][$s_other]; }
            push @{$alpha->[$s]}, ( ($sum) * $emis->{$obs_series->[$n]}[$s] ) ;
        }
    }                     

    my $beta = [];
    #y initialise
    for (0..$#{$trans}) { $beta->[$_][$#{$obs_series}] = $stop->[$_]; }
    for ( my $n = $#{$obs_series}-1; $n > -1; $n-- ) { 
        for my $s (0..$#{$trans}) {
            #$beta->[$s][$i] = ( ($trans->[0][$s]*$beta->[0][$i+1]*$emis->{$obs_series->[$i+1]}[0]) + ($trans->[1][$s]*$beta->[1][$i+1]*$emis->{$obs_series->[$i+1]}[1]) );
            my $sum = 0;
            for my $s_other (0..$#{$trans}) { $sum += ($trans->[$s_other][$s]*$beta->[$s_other][$n+1]*$emis->{$obs_series->[$n+1]}[$s_other]); }
            $beta->[$s][$n] = $sum;
        }
    }

#=fs normalisation?!?
#for my $n (0..$#{$obs_series}) { my $sum = 0; for my $s (0..$#{$trans}) { $sum += $alpha->[$s][$n] } for my $s (0..$#{$trans}) { $alpha->[$s][$n] = $alpha->[$s][$n] / $sum; } }
#for my $n (0..$#{$obs_series}) { my $sum = 0; for my $s (0..$#{$trans}) { $sum += $beta->[$s][$n] } for my $s (0..$#{$trans}) { $beta->[$s][$n] = $beta->[$s][$n] / $sum; } }
#=fe 

    # per state gamma - i.e. gamma é matric de 1 x N_states
    my $gamma = [];
    for my $s (0..$#{$trans}) { @{$gamma->[$s]} = map { $alpha->[$s][$_] * $beta->[$s][$_] } (0..$#{$obs_series}); }

#=fs normalisation?!?
#for my $n (0..$#{$obs_series}) { my $sum = 0; for my $s (0..$#{$trans}) { $sum += $gamma->[$s][$n] } for my $s (0..$#{$trans}) { $gamma->[$s][$n] = $gamma->[$s][$n] / $sum; } }
#=fe 

    #y gamma_sum = probadilidade total - entao nos nao normalisar dados como normal - faz differenca?!?
    my $gamma_sum = []; # should be same for all elements or...
    #@{$gamma_sum} = map { $gamma->[0][$_] + $gamma->[1][$_] } (0..$#{$obs_series});

    # map so devolve o último statement / map only returns the last statement
    @{$gamma_sum} = map { my $sum = 0; for my $s (0..$#{$trans}) { $sum += $gamma->[$s][$_] }; $sum } (0..$#{$obs_series});
    #push @{$perp}, 2**(-log2($gamma_sum->[0])/(scalar @{$obs_series} + 1));
    push @{$self->[2]}, 2**(-log2($gamma_sum->[0])/(scalar @{$obs_series} + 1));

    my $p_too_state_trans = [];
    for my $s (0..$#{$trans}) { @{$p_too_state_trans->[$s]} = map { $gamma->[$s][$_] / $gamma_sum->[$_] } (0..$#{$obs_series}); }

    my $p_too_state_trans_with_obs = []; # estado será primeira índice e obs será a segunda - é uma matric real mas facil
    for my $s (0..$#{$trans}) {
        for my $o (0..$#{$obs_types}) {
            @{$p_too_state_trans_with_obs->[$s][$o]} = map { $obs_series->[$_] eq $obs_types->[$o] ? $p_too_state_trans->[$s][$_] : 0; } (0..$#{$obs_series}); 
        }
    }

    my $p_state_too_state_trans = [];
    for my $s_1st (0..$#{$trans}) {
        for my $s_2nd (0..$#{$trans}) {
            #/ this is pretty inefficient - but its fun 
            @{$p_state_too_state_trans->[$s_1st][$s_2nd]} = map { $_ != 0 ?  ( $alpha->[$s_1st][$_-1] * $trans->[$s_2nd][$s_1st] 
                                                                            * $beta->[$s_2nd][$_] * $emis->{$obs_series->[$_]}[$s_2nd] ) 
                                                                            / $gamma_sum->[$_] : 0 } (0..$#{$obs_series}); 
        }
    }

    my $emis_new = {};
    for my $s (0..$#{$trans}) {
        for my $o (0..$#{$obs_types}) {
            $emis_new->{$obs_types->[$o]}[$s] = (sum @{$p_too_state_trans_with_obs->[$s][$o]} ) / (sum @{$p_too_state_trans->[$s]} );
        }
    }

    my $trans_new = [];
    for my $s_1st (0..$#{$trans}) {
        for my $s_2nd (0..$#{$trans}) {
            $trans_new->[$s_2nd][$s_1st] = (sum @{$p_state_too_state_trans->[$s_1st][$s_2nd]} ) / (sum @{$p_too_state_trans->[$s_1st]} );
        }
    }

    my $stop_new = [];
    for my $s (0..$#{$trans}) { $stop_new->[$s] = ( $p_too_state_trans->[$s][$#{$obs_series}] ) / (sum @{$p_too_state_trans->[$s]} ); }
    my $start_new = [];
    for my $s (0..$#{$trans}) { $start_new->[$s] = $p_too_state_trans->[$s][0]; }

   $self->[1][0] = $trans_new;
   $self->[1][1] = $emis_new;
   $self->[1][2] = $start_new;
   $self->[1][3] = $stop_new;

   return;
}

sub baum_welch {
    #/ i´m being lazy this is an acceptable cut-off mechanism for now
    my ($self, $max) = @_;
    $max ||= 100;
    my $val;
    my $count = 1;
    while (1) { 
        $self->_forwardbackward_reestimacao;
        last if defined $val && $val < ${$self->[2]}[-1];
        $val = ${$self->[2]}[-1] - ( ${$self->[2]}[-1]/1000000000) if $count > 3;
        $count++;
        last if $count > 100;
    }
    return;
}

sub _baum_welch_10 {
    my $self = shift;
    for (0..10) { $self->_forwardbackward_reestimacao; }
    return;
}

sub _baum_welch_length {
    my $self = shift;
    for (0..$#{$self->[0][0]}) { $self->_forwardbackward_reestimacao; }
    return;
}

sub results {
    my $self = shift;
    my $trans = $self->[1][0];
    my $emis = $self->[1][1];
    my $start = $self->[1][2];
    if (wantarray) {
        return ($trans, $emis, $start);
    }
    else { 
        my $keys = $self->[0][1];
        my @config = ( [15, q{}] );
        push @config, (map { [ 15, q{P(...|State_}.$_.q{)} ] } (1..$#{$trans->[0]}+1));
        my $tbl = Text::SimpleTable->new(@config);
        for my $row (0..$#{$trans}) {
            my @data;
            # quem liga qual serie
            for my $col (0..$#{$trans->[0]}) { push @data, sprintf(q{%.8e},$trans->[$row][$col]); }
            my $row_num = $row+1;
            $tbl->row( qq{P(State_${row_num}|...)}, @data );
            $tbl->hr if $row != $#{$trans};
        }
        print qq{\nTransition matrix.\n};
        print $tbl->draw;

        undef @config; 
        @config = ( [15, q{}] );
        push @config, (map { [ 15, q{P(...|State_}.$_.q{)} ] } (1..$#{$trans->[0]}+1));
        my $tbl1 = Text::SimpleTable->new(@config);
        my $count = 0;
        for my $row (@{$keys}) {
#$tbl1->row( $row, ( map { my $v = $emis->{$row}[$_]; if ($v > 1e-4 || $v < 1e4 ) { $v = sprintf(q{%.12f},$start->[$_]) } else { $v = sprintf(q{%.8e},$start->[$_]) }; $v } (0..$#{$trans->[0]})  ) );
            my @data;
            for my $col (0..$#{$trans->[0]}) { push @data, sprintf(q{%.8e},$emis->{$row}[$col]); }
            $tbl1->row( qq{P($row|...)}, @data );
            $tbl1->hr if $count != $#{$keys};
            $count++;
        }
        print qq{\nEmission matrix.\n};
        print $tbl1->draw;

        undef @config; 
        push @config, (map { [ 15, q{State_}.$_ ] } (1..$#{$start}+1));
        my $tbl2 = Text::SimpleTable->new(@config);
        #my @data;
        #for my $i (0..$#{$trans->[0]}) { push @data, sprintf(q{%.8e},$start->[$i]); }
        #$tbl2->row(@data);
        $tbl2->row( ( map { my $v = $start->[$_]; if ($v > 1e-4 && $v < 1e4 || $v == 0 ) { 
                        $v = sprintf(q{%.12f},$start->[$_]) 
                    } 
                    else { 
                        $v = sprintf(q{%.8e},$start->[$_]) }; $v 
                    } (0..$#{$trans->[0]})  ) );
        print qq{\nStart probabilities.\n};
        print $tbl2->draw;
    }
    return;
}

1; # Magic true value required at end of module

__END__

#ARRAY REFERENCE (0)
#  |  
#  |__ARRAY REFERENCE (1) [ '->[0]' ]
#  |    |  
#  |    |__ARRAY REFERENCE (2) ---LONG_LIST_OF_SCALARS--- [ length = 33 ] e.g. 0..2:  obs2, obs3, obs3 [ '->[0][0]' ] # a serie
#  |    |  
#  |    |__ARRAY REFERENCE (2) ---LONG_LIST_OF_SCALARS--- [ length = 3 ]: obs3, obs1, obs2 [ '->[0][1]' ] # a lista de tipos de observacoes
#  |    |  
#  |    |__SCALAR = '3' (2)  [ '->[0][2]' ] # o numero de tipos de observacoes 
#  |  
#  |__ARRAY REFERENCE (1) [ '->[1]' ]
#  |    |  
#  |    |__ARRAY REFERENCE (2) [ '->[1][0]' ] # transition matrix
#  |    |    |  
#  |    |    |__ARRAY REFERENCE (3) ---LONG_LIST_OF_SCALARS--- [ length = 2 ]: 0.933779184947876, 0.0718663090308487 [ '->[1][0][0]' ]
#  |    |    |  
#  |    |    |__ARRAY REFERENCE (3) ---LONG_LIST_OF_SCALARS--- [ length = 2 ]: 0.0662208150521236, 0.864944219467616 [ '->[1][0][1]' ]
#  |    |  
#  |    |__HASH REFERENCE (2) [ '->[1][1]' ] # emission matrix
#  |    |    |  
#  |    |    |__'obs3'=>ARRAY REFERENCE (3) ---LONG_LIST_OF_SCALARS--- [ length = 2 ]: 0.211448366743702, 0.465609305295478 [ '->[1][1]{obs3}' ]
#  |    |    |  
#  |    |    |__'obs1'=>ARRAY REFERENCE (3) ---LONG_LIST_OF_SCALARS--- [ length = 2 ]: 0.640481492730478, 7.18630557481621e-09 [ '->[1][1]{obs1}' ]
#  |    |    |  
#  |    |    |__'obs2'=>ARRAY REFERENCE (3) ---LONG_LIST_OF_SCALARS--- [ length = 2 ]: 0.14807014052582, 0.534390687518216 [ '->[1][1]{obs2}' ]
#  |    |  
#  |    |__ARRAY REFERENCE (2) ---LONG_LIST_OF_SCALARS--- [ length = 2 ]: 4.52394236439737e-30, 1 [ '->[1][2]' ] # start conditions
#  |
#  |__ ARRAY REFERENCE (1)  [ '->[2]' ] # perp
#

=head1 SEE ALSO

Algorithm::Viterbi

=cut

=head1 DEPENDENCIES

'Carp'                      => '1.08', 
'Math::Cephes'              => '0.47', 
'List::Util'                => '1.19', 
'Text::SimpleTable'         => '2.0',

=cut

=head1 WARNING

This module Baum-Welch implementation has been tested fairly extensively with 2-hidden state cases but as yet has been subject to little (almost
no) testing with >2 hidden states.

=cut

=head1 BUGS AND LIMITATIONS

Let me know.

=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cantab.net> >>

=cut

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel S. T. Hughes C<< <dsth@cantab.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut

