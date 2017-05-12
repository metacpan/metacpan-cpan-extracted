=head1 NAME

Asterisk::LCR::Comparer::XERAND - More advanced rate comparer for Asterisk::LCR


=head1 SUMMARY

This comparer is a bit cleverer than L<Asterisk::LCR::Comparer::Dummy>.

It does currency conversion using Finance::Currency::Convert::XE, and then adjust
cost per minute using a traffic simulator.

Currently the traffic simulator is a bit simplistic: it generates a call length between
0 and 200 seconds (to have an everage of 100 seconds call length).

In the future there will be a more sophisticated simulator capable of running rates
against past traffic CDRs to measure real cost.

=head1 ATTRIBUTES

none.


=head1 METHODS


=cut
package Asterisk::LCR::Comparer::XERAND;
use base qw /Asterisk::LCR::Comparer/;
use Finance::Currency::Convert::XE;
use warnings;
use strict;

our %CURRENCY_RATES = ();
our $XE = Finance::Currency::Convert::XE->new();
our $SUITE = undef;


sub normalize
{
    my $self = shift;
    my $rate = shift;
    
    # fetch the rate itself
    my $price = $rate->rate();
    my $curr  = $rate->currency();
    my $cfee  = $rate->connection_fee();
    my $finc  = $rate->first_increment();
    my $ninc  = $rate->increment();

    # overwrite the attributes with corrected rate
    $SUITE ||= [ map { _random_normalized ($self->average(), $self->variance()) } 1..10000 ];
    $price = _simulate_cost_suite ($SUITE, $price, $cfee, $finc, $ninc);
    my $totsecs = 0;
    for (@{$SUITE}) { $totsecs += $_ };
    $price = int (10000 * 60 * ($price / $totsecs)) / 10000;
    
    $rate->{rate}            = $self->_convert ($price, $curr);
    $rate->{currency}        = $self->currency();
    $rate->{increment}       = 1;
    $rate->{first_increment} = 1;
    $rate->{connection_fee}  = 0;
}


sub currency
{
    my $self = shift;
    return uc ($self->{currency}) || 'EUR';
}


# converts $amount of $currency into base currency
sub _convert
{
    my $self     = shift;
    my $amount   = shift;
    my $currency = shift;
    my $rate     = $self->_fetch_rate ($currency);
    return $amount * $rate;
}


sub _fetch_rate
{
    my $self     = shift;
    my $cur      = shift;   
    my $base_cur = $self->currency();
    $cur eq $base_cur and return 1;
    $CURRENCY_RATES{$cur} ||= $XE->convert (
        source => $cur,
        target => $base_cur,
        value  => 1,
        format => 'number',
    );
    
    return $CURRENCY_RATES{$cur};
}


sub sortme
{
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;
    $arg1->{_is_normal} && $arg2->{_is_normal} && return $arg1->rate() <=> $arg2->rate();
    
    my $rate1 = $arg1->rate();
    my $rate2 = $arg2->rate();

    my $cur1 = $arg1->currency();
    my $cur2 = $arg2->currency();

    $rate1 = $self->_convert ($rate1, $cur1);
    $rate2 = $self->_convert ($rate2, $cur2);
    
    my ($cost1, $cost2) = $self->_simulate_cost (
        $rate1, $arg1->connection_fee(), $arg1->first_increment(), $arg1->increment(),
        $rate2, $arg2->connection_fee(), $arg2->first_increment(), $arg2->increment()
    );

    return +1 if ($cost1 > $cost2);
    return -1 if ($cost2 > $cost1);
    return 0;
}


sub average
{
    my $self = shift;
    return $self->{average} || 100;
}


sub variance
{
    my $self = shift;
    return $self->{variance} || 10000;
}


sub _simulate_cost
{
    my $self       = shift;
    
    my $rate1      = shift;
    my $conn1      = shift;
    my $first_inc1 = shift;
    my $next_inc1  = shift;

    my $rate2      = shift;
    my $conn2      = shift;
    my $first_inc2 = shift;
    my $next_inc2  = shift;

    my $avg  = $self->average();
    my $std  = $self->variance();
    my $var  = $std**2;

    $SUITE ||= [ map { _random_normalized ($avg, $var) } 1..10000 ];
    my $cost1 = _simulate_cost_suite ($SUITE, $rate1, $conn1, $first_inc1, $next_inc1);
    my $cost2 = _simulate_cost_suite ($SUITE, $rate2, $conn2, $first_inc2, $next_inc2);
    
    return ($cost1, $cost2); 
}


our %CACHE_SIMULATE_COST_SUITE = ();

sub _simulate_cost_suite
{
    my $SUITE     = shift;
    my $rate      = shift;
    my $conn      = shift;
    my $first_inc = shift;
    my $next_inc  = shift;
    
    my $key = "$rate-$conn-$first_inc-$next_inc";
    
    $CACHE_SIMULATE_COST_SUITE{$key} ||= do {
        my $tot_len = 0;
        my $cost = 0;
        for my $length ( @{$SUITE} )
        {
            $cost += _simulate_cost_per_call ($length, $rate, $conn, $first_inc, $next_inc);
            $tot_len += $length;
        }
        
        $cost;
    };
    
    return $CACHE_SIMULATE_COST_SUITE{$key};
}


sub _simulate_cost_per_call
{
    my $length    = shift;
    my $rate      = shift;
    my $conn      = shift;
    my $first_inc = shift;
    my $next_inc  = shift;
 
    my $bk = $length; 
    $length = $first_inc if ($length < $first_inc);
    $length = $next_inc * ( 1 + int ($length / $next_inc) ) if ($length % $next_inc);
    my $cost = $length * ($rate/60);
    return $cost;
}


# algo from:
# http://psweb.sbs.ohio-state.edu/faculty/rtimpone/computer_resources/polar.htm
sub _random_normalized
{
    return int (rand (200));

#   This was meant to be clever but It Doesn't Work, aaaargh!
#    my $average  = shift;
#    my $variance = shift;
#
#    my $v1 = 0;
#    my $v2 = 0;
#    my $s = 2;
#    while ($s > 1)
#    {
#        # Step 1: Generate random numbers, U1 and U2
#        # Step 2: Calculate V1, V2, and S
#        $v1 = 2 * rand() - 1;
#        $v2 = 2 * rand() - 1;
#        $s  = $v1 ** 2 + $v2 ** 2;
#
#        # Step 3: If S=>1 get new values for U1 and U2
#        # (go back to while loop)
#    }
#
#    # Step 4: Calculate normal
#    my $z = (((-2 * log ($s)) / $s) ** (1/2)) * $v1;
#    my $stdev = ($variance) ** (1/2);
#    my $res = abs ( ($z * $stdev) + $average );
#    if ($res > 6400) { return _random_normalized ($average, $variance) }
#    else { return $res }
}


1;


__END__
