package DSP::LinPred_XS;
use 5.008005;
use Mouse;
our $VERSION = "0.03";
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);




has 'mu' => (
	     is => 'rw',
	     isa => 'Num',
	     default => 0.001
	    );
has 'mu_mode' => (
		  is => 'rw',
		  isa => 'Int',
		  default => 0
		 );
has 'h_length' => (
		   is => 'rw',
		   isa => 'Int',
		   default => 100
		  );
has 'h' => (
	    is => 'rw',
	    isa => 'ArrayRef[Num]',
	    default => sub{[(0) x 100]}
	   );
has 'x_stack' => (
		  is => 'rw',
		  isa => 'ArrayRef[Num]',
		  default => sub{[(0) x 100]}
		 );
has 'x_count' => (
		  is => 'rw',
		  isa => 'Int',
		  default => 0
		 );
has 'current_error' => (
			is => 'rw',
			isa => 'Num',
			default => 0
		       );
has 'dc' => (
	     is => 'rw',
	     isa => 'Num',
	     default => 0
	    );
has 'dc_init' => (
		  is => 'rw',
		  isa => 'Num',
		  default => 0
		 );
has 'stddev' => (
		 is => 'rw',
		 isa => 'Num',
		 default => 0
		);
has 'stddev_init' => (
		      is => 'rw',
		      isa => 'Num',
		      default => 1
		     );
has 'est_mode' => (
		   is => 'rw',
		   isa => 'Num',
		   default => 1
		  );


# filter specification
# mu : step size
# h_length : filter size
sub set_filter{
  my $self = shift;
  my $conf = shift;
  if(defined($conf->{filter_length})){
    $self->h_length($conf->{filter_length});
    $self->h([(0) x $conf->{filter_length}]);
    if(defined($conf->{dc_init})){
      $self->x_stack([($conf->{dc_init}) x $conf->{filter_length}]);
    }else{
      $self->x_stack([(0) x $conf->{filter_length}]);
    }
  }
  if(defined($conf->{dc_init})){
    $self->dc($conf->{dc_init});
    $self->dc_init($conf->{dc_init});
  }
  if(defined($conf->{est_mode})){
    $self->est_mode($conf->{est_mode});
  }
  if(defined($conf->{stddev_init})){
    $self->stddev($conf->{stddev_init});
    $self->stddev_init($conf->{stddev_init});
  }
}

# reset filter state
sub reset_state{
  my $self = shift;
  my $h_length = $self->h_length;
  $self->h([(0) x $h_length]);
  $self->x_stack([($self->dc_init) x $h_length]);
  $self->current_error(0);
  $self->dc($self->dc_init);
  $self->x_count(0);
  $self->stddev($self->stddev_init);
}

# prediction only
# predict_num : number of output predicted values
# this method returns list reference of predicted values
sub predict{
  my $self = shift;
  my $predict_num = shift;
  my $h = $self->h;
  my $x_stack = $self->x_stack;
  my $estimated;
  for(0 .. $predict_num){
    my $x_est = 0;
    for( my $k = 0; $k <= $#{$h} and $k <= $self->x_count; $k++){
      $x_est += $h->[$k] * ($x_stack->[$k] - $self->dc);
    }
    $x_est += $self->dc;
    unshift(@$x_stack,$x_est);
    push(@$estimated,$x_est);
    pop(@$x_stack);
  }
  shift(@$estimated);
  return($estimated);
}

# update only
# x should be array reference

sub update{
  my $self = shift;
  my $x = shift;
  my $h_length = $self->h_length;
  my $h = $self->h;
  my $x_stack = $self->x_stack;
  
  for ( my $kx=0; $kx <= $#{$x}; $kx++){
    
    unshift(@$x_stack,$x->[$kx]);
    pop(@$x_stack);
    $self->x_count($self->x_count + 1);
    if($self->est_mode == 1){
      $self->dc_stddev_update;
    }
    my $x_est = 0;
    for( my $k = 0; $k <= $#{$h} and $k <= $self->x_count;$k++){
      $x_est += $h->[$k] * ($x_stack->[$k] - $self->dc);
    }
    my $error = $x->[$kx] - ($x_est + $self->dc);
    $self->current_error($error);
    my $h_new = $h;
    my $tmp_coef = 1;
    if($self->est_mode == 1){
      $tmp_coef = $self->mu * $error / (1 + $self->stddev);
    }else{
      $tmp_coef = $self->mu * $error;
    }
    if($self->mu_mode == 1){
      $tmp_coef = 10 * $self->mu / (1 + $self->h_length);
    }
    
    for(my $k = 0;$k <= $#{$h} and $k <= $self->x_count; $k++){
      $h_new->[$k] = 
	$h->[$k] 
	  + $tmp_coef * ($x_stack->[$k] - $self->dc);
    }
    $self->h($h_new);
  }
}

## DC component calculation and update
# using x_stack

sub dc_stddev_update{
  my $self = shift;
  my $x_stack = $self->x_stack;
  my ($sum,$mean,$variance,$stddev) = &get_stat($x_stack);
  $self->dc($mean);
  $self->stddev($stddev);
}


## calculation of mean value of filter
sub filter_dc{
  my $self = shift;
  my $h = $self->h;
  my $mean = 0;
  my $num = $#$h + 1;
  for(0 .. $#$h){
    $mean += $h->[$_];
  }
  return($mean / $num);
}

## calculation of stddev of filter
sub filter_stddev{
  my $self = shift;
  my $h = $self->h;
  my $variance = 0;
  my $num = $#$h + 1;
  for(0 .. $#$h){
    $variance += ($h->[$_])**2;
  }
  return(sqrt($variance / $num));
}



1;
__END__

=encoding utf-8

=head1 NAME

DSP::LinPred_XS - Linear Prediction

=head1 SYNOPSIS

    use DSP::LinPred_XS;

    # OPTIONS
    # mu       : Step size of filter. (default = 0.001)
    #
    # h_length : Filter size. (default = 100)
    #
    # dc_init  : Initial DC bias.
    #            It *SHOULD* be set value *ACCURATELY* when dc_mode => 0.
    #            (default = 0)
    #
    # stddev_init : Initial value of stddev.
    #               (default = 1)
    #

    my $lp = DSP::LinPred_XS->new;

    # set filter
    $lp->set_filter({
                     mu => 0.001,
                     filter_length => 500,
                     est_mode => 1
                    });

    # defining signal x
    my $x = [0,0.1,0.5, ... ]; # input signal

    # Updating Filter
    $lp->update($x);
    my $current_error = $lp->current_error; # get error

    # Prediction
    my $pred_length = 10;
    my $pred = $lp->predict($pred_length);
    for( 0 .. $#$pred ){ print $pred->[$_], "\n"; }


=head1 DESCRIPTION

DSP::LinPred_XS is Linear Prediction by Least Mean Squared Algorithm.
Implemented by XS.

This Linear Predicting method can estimate the standard deviation, direct current component, and predict future value of input.

=head1 METHODS

=head2 I<set_filter>

I<set_filter> method sets filter specifications to DSP::LinPred object.

    $lp->set_filter(
        {
            mu => $step_size, # <Num>
            filter_length => $filter_length, # <Int>
            dc_init => $initial_dc_bias, # <Num>
            stddev_init => $initial_stddev, # <Num>
            est_mode => $estimation_mode # <Int>, enable when 1
        });


=head2 I<update>

I<update> method updates filter state by source inputs are typed ArrayRef[Num].

    my $x = [0.13,0.3,-0.2,0.5,-0.07];
    $lp->update($x);

If you would like to extract the filter state, you can access member variable directly like below.

    my $filter = $lp->h;
    for( 0 .. $#$filter ){ print $filter->[$_], "\n"; }

=head2 I<predict>

I<predict> method generates predicted future values of inputs by filter.

    my $predicted = $lp->predict(7);
    for( 0 .. $#$predicted ){ print $predicted->[$_], "\n";}

=head2 I<filter_dc>

This method can calculate mean value of current filter.

    my $filter_dc = $lp->filter_dc;

=head2 I<filter_stddev>

This method can calculate standard deviation of current filter.

    my $filter_stddev = $lp->filter_stddev;


=head1 READING STATES

=head2 I<current_error>

    # It returns value of current prediction error
    # error = Actual - Predicted
    my $current_error = $lp->current_error;
    print 'Current Error : '.$current_error, "\n";

=head2 I<h>

    # It returns filter state(ArrayRef)
    my $filter = $lp->h;
    print "Filter state\n";
    for( 0 .. $#$filter ){ print $_.' : '.$filter->[$_],"\n"; }

=head2 I<x_count>

    # It returns value of input counter used in filter updating.
    my $x_count = $lp->x_count;
    print 'Input count : '.$x_count, "\n";

=head2 I<dc>

    # Get value of current Direct Current Components of inputs.
    my $dc = $lp->dc;
    print 'Current DC-Component : '.$dc, "\n";

=head2 I<stddev>

    # Get value of current standard deviation of inputs.
    my $stddev = $lp->dc;
    print 'Current STDDEV : '.$stddev, "\n";


=head1 LICENSE

Copyright (C) Toshiaki Yokoda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Toshiaki Yokoda E<lt>E<gt>

=cut

