package Algorithm::Easing;

use strict;
use warnings;

our $VERSION = '0.998';

1;

__END__

# MAN3 POD

=head1 NAME

Algorithm::Easing - Calculate eased translations between two positive whole integer values over time

=cut

=head1 SYNOPSIS

        ## with mediator

        use Algorithm::Easing;
        use Algorithm::Easing::Mediator;
        use Algorithm::Easing::Bounce;

        # this example produces traditional 'bounce' output;

        my $translation_mediator = Algorithm::Easing::Mediator->new(Algorithm::Easing::Bounce->new);

        # total time for eased translation as a real positive integer value
        my $d = 2.5;

        # begin
        my $b = 0;

        # change
        my $c = 0;

        # time passed in seconds as a real positive integer between each frame
        my $frame_time = 0.0625;

        my @p = [319,0];

        for(my $t = 0; $t < 2.5; $t += 0.0625) {
            $p[1] = $translation_mediator->ease_out($t,$b,$c,$d)

            # plot
            ...
        }

=cut

=head1 INTRODUCTION

Commonly used in animation, Penner's easing functions are beautiful translations between two positive whole integer values.

The included easing functions in Algorithm::Easing are :

    Exponential
    Bounce
    Linear
    Cubic
    Quadratic
    Quartinion
    Quintonion
    Sinusoidal
    Backdraft
    Circular

For ease of use, there is an included Mediator class.  The Mediator class permits the programmer to select from the spread of easing functions through a single class name.

=cut

=head1 METHODS

=head2 ease_none
    usage :
    
        Parameters : 
            Let t be time,
            Let b be begin,
            Let c be change,
            Let d be duration,
        Results :
            Let p be position,
            
        my $p = $obj->ease_none($t,$b,$c,$d);

This method is used for a linear translation between two positive real whole integers using a positive real integer as the parameter for time.
=cut

=head2 ease_in
    usage :
    
        Parameters : 
            Let t be time,
            Let b be begin,
            Let c be change,
            Let d be duration,
        Results :
            Let p be position,
            
        my $p = $obj->ease_in($t,$b,$c,$d);

This method is used to ease in between two positive real whole integers using a positive real integer as the parameter for time in the specified fashion.

=cut

=head2 ease_out
    usage :
    
        Parameters : 
            Let t be time,
            Let b be begin,
            Let c be change,
            Let d be duration,
        Results :
            Let p be position,
            
        my $p = $obj->ease_out($t,$b,$c,$d);

This method is used to ease out between two positive real whole integers using a positive real integer as the parameter for time in the specified fashion.

=cut

=head2 ease_both
    usage :
    
        Parameters : 
            Let t be time,
            Let b be begin,
            Let c be change,
            Let d be duration,
        Results :
            Let p be position,
            
        my $p = $obj->ease_both($t,$b,$c,$d);

This method is used to ease both in then out between two positive real whole integers using a positive real integer as the parameter for time in the specified fashion.

=cut

=head1 AUTHOR

Jason McVeigh, <jmcveigh@outlook.com>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright 2016 by Jason McVeigh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut