package Algorithm::Easing::Exponential;

use Moose;

use Math::Trig qw(:pi);

use constant EPSILON => 0.000001;

extends 'Algorithm::Easing::Ease';

use namespace::clean;

sub ease_in  {
    my $self = shift;
    my ($t,$b,$c,$d) = (shift,shift,shift,shift);

    return $b if ($t < EPSILON);
    return $c if ($d < EPSILON);

    return ($t==0) ? $b : $c * $self->pow(2, 10 * ($t / $d - 1)) + $b;
}

sub ease_out {
    my $self = shift;
    my ($t,$b,$c,$d) = (shift,shift,shift,shift);

    return $b if ($t < EPSILON);
    return $c if ($d < EPSILON);

    return ($t == $d) ? $b + $c : $c * (-$self->pow(2, -10 * $t / $d) + 1) + $b;
}

sub ease_both {
    my $self = shift;
    my ($t,$b,$c,$d) = (shift,shift,shift,shift);

    return $b if ($t < EPSILON);
    return $c if ($d < EPSILON);

    if ($t == 0) {
        return $b;
    }

    if ($t == $d) {
        return $b + $c;
    }

    if (($t /= $d / 2) < 1) {
        return $c / 2 * $self->pow(2, 10 * ($t - 1)) + $b;
    }

    return $c / 2 * (-$self->pow(2, -10 * --$t) + 2) + $b;
}

1;

__END__

# MAN3 POD

=head1 NAME

Algorithm::Easing::Exponential - Calculate eased translations between two positive whole integer values over time

=cut

=head1 SYNOPSIS

        use Algorithm::Easing;
        use Algorithm::Easing::Exponential;

        # this example produces traditional 'exponential' output;

        my $translation = Algorithm::Easing::Exponential->new;

        # total time for eased translation as a real positive integer value
        my $d = 2.5;

        # begin
        my $b = 0;

        # change
        my $c = 240;

        # time passed in seconds as a real positive integer between each frame
        my $frame_time = 0.0625;

        my @p = [319,0];

        for(my $t = 0; $t < 2.5; $t += 0.0625) {
            $p[1] = $translation->ease_out($t,$b,$c,$d)

            # plot
            ...;
        }

=cut

=head1 METHODS

=cut

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

This method is used to ease in between two positive real whole integers using a positive real integer as the parameter for time in an exponential fashion.

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

This method is used to ease in between two positive real whole integers using a positive real integer as the parameter for time in exponential fashion.

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

This method is used to ease both in then out between two positive real whole integers using a positive real integer as the parameter for time in exponential fashion.

=cut

=head1 AUTHOR

Jason McVeigh, <jmcveigh@outlook.com>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright 2016 by Jason McVeigh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut