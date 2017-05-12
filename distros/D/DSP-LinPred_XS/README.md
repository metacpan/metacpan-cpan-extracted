# NAME

DSP::LinPred\_XS - Linear Prediction

# SYNOPSIS

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

# DESCRIPTION

DSP::LinPred\_XS is Linear Prediction by Least Mean Squared Algorithm.
Implemented by XS.

This Linear Predicting method can estimate the standard deviation, direct current component, and predict future value of input.

# METHODS

## _set\_filter_

_set\_filter_ method sets filter specifications to DSP::LinPred object.

    $lp->set_filter(
        {
            mu => $step_size, # <Num>
            filter_length => $filter_length, # <Int>
            dc_init => $initial_dc_bias, # <Num>
            stddev_init => $initial_stddev, # <Num>
            est_mode => $estimation_mode # <Int>, enable when 1
        });

## _update_

_update_ method updates filter state by source inputs are typed ArrayRef\[Num\].

    my $x = [0.13,0.3,-0.2,0.5,-0.07];
    $lp->update($x);

If you would like to extract the filter state, you can access member variable directly like below.

    my $filter = $lp->h;
    for( 0 .. $#$filter ){ print $filter->[$_], "\n"; }

## _predict_

_predict_ method generates predicted future values of inputs by filter.

    my $predicted = $lp->predict(7);
    for( 0 .. $#$predicted ){ print $predicted->[$_], "\n";}

## _filter\_dc_

This method can calculate mean value of current filter.

    my $filter_dc = $lp->filter_dc;

## _filter\_stddev_

This method can calculate standard deviation of current filter.

    my $filter_stddev = $lp->filter_stddev;

# READING STATES

## _current\_error_

    # It returns value of current prediction error
    # error = Actual - Predicted
    my $current_error = $lp->current_error;
    print 'Current Error : '.$current_error, "\n";

## _h_

    # It returns filter state(ArrayRef)
    my $filter = $lp->h;
    print "Filter state\n";
    for( 0 .. $#$filter ){ print $_.' : '.$filter->[$_],"\n"; }

## _x\_count_

    # It returns value of input counter used in filter updating.
    my $x_count = $lp->x_count;
    print 'Input count : '.$x_count, "\n";

## _dc_

    # Get value of current Direct Current Components of inputs.
    my $dc = $lp->dc;
    print 'Current DC-Component : '.$dc, "\n";

## _stddev_

    # Get value of current standard deviation of inputs.
    my $stddev = $lp->dc;
    print 'Current STDDEV : '.$stddev, "\n";

# LICENSE

Copyright (C) Toshiaki Yokoda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Toshiaki Yokoda <>
