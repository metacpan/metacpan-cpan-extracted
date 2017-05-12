package Algorithm::Easing::Ease;

use Moose;

use constant EPSILON => 0.000001;

use namespace::clean;

sub ease_none {
    my $self = shift;
    my ($t,$b,$c,$d) = (shift,shift,shift,shift);

    return $b if $t < EPSILON;
    return $c if $d < EPSILON;

    return($c * $t / $d + $b);
}

sub pow {
    my $self = shift;
    my ($a, $b) = (shift,shift);

    return($a ** $b);
}

1;

__END__

# MAN3 POD

=head1 NAME

Algorithm::Easing::Ease - This is the base class for an ease.

=cut

=head1 METHODS

=cut

=head2 ease_none
    Usage :
    
        Arguments : 
            Let t be time,
            Let b be begin,
            Let c be change,
            Let d be duration,
        Return :
            Let p be position,
            
        my $p = $obj->ease_none($t,$b,$c,$d);

This method is used for a linear translation between two positive real whole integers using a positive real integer as the parameter for time.

=cut

=head1 AUTHOR

Jason McVeigh, <jmcveigh@outlook.com>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright 2016 by Jason McVeigh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut