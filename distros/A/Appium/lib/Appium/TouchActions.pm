package Appium::TouchActions;
$Appium::TouchActions::VERSION = '0.0803';
# ABSTRACT: Perform touch actions through appium: taps, swipes, scrolling
use Moo;

has 'driver' => (
    is => 'ro',
    required => 1,
    handles => [ qw/execute_script/ ]
);


sub tap {
    my ($self, @coords) = @_;

    my $params = {
        x => $coords[0],
        y => $coords[1]
    };

    $self->execute_script('mobile: tap', $params);

    return $self->driver;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Appium::TouchActions - Perform touch actions through appium: taps, swipes, scrolling

=head1 VERSION

version 0.0803

=head1 METHODS

=head2 tap ( $x, $y )

Perform a precise tap at a certain location on the device, specified
either by pixels or percentages. All values are relative to the top
left of the device - by percentages, (0,0) would be the top left, and
(1, 1) would be the bottom right.

As per the Appium documentation, values between 0 and 1 will be
interepreted as percentages. (0.5, 0.5) will click in the center of
the screen. Values greater than 1 will be interpreted as pixels. (10,
10) will click at ten pixels away from the top and left edges of the
screen.

    # tap in the center of the screen
    $appium->tap( 0.5, 0.5 )

    # tap a pixel position
    $appium->tap( 300, 500 );

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Appium|Appium>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/appium/perl-client/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
