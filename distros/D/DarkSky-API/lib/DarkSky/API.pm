package DarkSky::API;

use Moose;
use 5.010;
use Mojo::UserAgent;
use JSON;
use List::MoreUtils qw( natatime );

=head1 NAME

DarkSky::API - The Dark Sky API lets you query for short-term 
precipitation forecast data at geographical points inside
the United States.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

our $DARKSKY_API_URL = 'https://api.darkskyapp.com/v1';

has 'api_key' => ( isa => 'Str', is => 'rw', required => 1 );

=head1 SYNOPSIS

Perl module for retrieving data from the Dark Sky API. 
The Dark Sky API lets you query for short-term precipitation forecast data
at geographical points inside the United States.

    use DarkSky::API;

    my $darksky = DarkSky::API->new( api_key => '<your key here>' );
    
    # Returns a forecast for the next hour at a given location.
    my $forecast = $darksky->forecast({ latitude => '42.7243', longitude => '-73.6927' });

    # Returns a brief forecast for the next hour at a given location.
    my $brief_forecast = $darksky->brief_forecast({ latitude => '42.7243', longitude => '-73.6927' });

    # Returns forecasts for a collection of arbitrary points.
    my $precipitation = $darksky->precipitation(['42.7','-73.6',1325607100,'42.0','-73.0',1325607791]);

    # Returns a list of interesting storms happening right now.
    my $interesting_storms = $darksky->interesting();
    
    ...

=head1 SUBROUTINES/METHODS

=head2 forecast

Returns a forecast for the next hour at a given location.

  my $forecast = $darksky->forecast({ latitude => '42.7243', longitude => '-73.6927' });
    
=cut

sub forecast {
    my ( $self, $args ) = @_;
    my $tx = Mojo::UserAgent->new()->get(
        join( '/',
            $DARKSKY_API_URL, "forecast",
            $self->api_key,   $args->{latitude} . ',' . $args->{longitude} )
    );
    return unless ( defined $tx );
    return decode_json( $tx->res->body ) if ( $tx->res->code == 200 );
}

=head2 brief_forecast

Returns a brief forecast for the next hour at a given location.

  my $brief_forecast = $darksky->brief_forecast({ latitude => '42.7243', longitude => '-73.6927' });

=cut

sub brief_forecast {
    my ( $self, $args ) = @_;
    my $tx = Mojo::UserAgent->new()->get(
        join( '/',
            $DARKSKY_API_URL, "brief_forecast",
            $self->api_key,   $args->{latitude} . ',' . $args->{longitude} )
    );
    return unless ( defined $tx );
    return decode_json( $tx->res->body ) if ( $tx->res->code == 200 );
}

=head2 precipitation

Returns forecasts for a collection of arbitrary points.

  my $precipitation = $darksky->precipitation(['42.7','-73.6',1325607100,'42.0','-73.0',1325607791]);

=cut

sub precipitation {
    my ( $self, $latitudes_longitudes_times ) = @_;
    return unless ( @{$latitudes_longitudes_times} % 3 == 0 );
    my $it = natatime 3, @$latitudes_longitudes_times;
    my @triplets;
    while ( my @triplet = $it->() ) {
        push @triplets, join( ',', @triplet );
    }
    my $url = join( '/',
        $DARKSKY_API_URL, "precipitation",
        $self->api_key, join( ';', @triplets ) );
    my $tx = Mojo::UserAgent->new()->get($url);
    unless ( defined $tx ) {
        return;
    }
    if ( $tx->res->code == 200 ) {
        return decode_json( $tx->res->body );
    }
}

=head2 interesting

Returns a list of interesting storms happening right now.

    my $interesting_storms = $darksky->interesting();

=cut

sub interesting {
    my ($self) = @_;
    my $tx = Mojo::UserAgent->new()
      ->get( join( '/', $DARKSKY_API_URL, "interesting", $self->api_key ) );

    unless ( defined $tx ) {
        return;
    }
    return decode_json( $tx->res->body ) if ( $tx->res->code == 200 );
    return $tx->res->code();
}

=head1 AUTHOR

Martin-Louis Bright, C<< <mlbright at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-darksky-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DarkSky-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DarkSky::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DarkSky-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DarkSky-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DarkSky-API>

=item * Search CPAN

L<http://search.cpan.org/dist/DarkSky-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Martin-Louis Bright.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of DarkSky::API
