package Dancer2::Plugin::Map::Tube;

$Dancer2::Plugin::Map::Tube::VERSION   = '0.03';
$Dancer2::Plugin::Map::Tube::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Dancer2::Plugin::Map::Tube - Dancer2 add-on for Map::Tube.

=head1 VERSION

Version 0.03

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

use Class::Load qw(try_load_class);
use Dancer2::Plugin::Map::Tube::API;
use Dancer2::Plugin;

=head1 DESCRIPTION

It provides the REST API features for L<Map::Tube::Server>.It holds the supported
map informations.

Currently users are allowed to make 6 api calls per minute. Other than that there
are no restrictions for now. In future, we would allow access by API KEY.

Please be gentle as it's running on tiny RaspberryPI box sitting in the corner of
my bedroom.

=head1 SYNOPSIS

    get '/map-tube/v1/shortest-route/:map/:start/:end' => sub {
        my $client   = request->address;
        my $name     = route_parameters->get('map');
        my $start    = route_parameters->get('start');
        my $end      = route_parameters->get('end');

        my $response = api($name)->shortest_route($client, $start, $end);

        ...
        ...

        return $response->{content};
    };

    get '/map-tube/v1/stations/:map/:line' => sub {
        my $client   = request->address;
        my $name     = route_parameters->get('map');
        my $line     = route_parameters->get('line');

        my $response = api($name)->line_stations($client, $line);

        ...
        ...

        return $response->{content};
    };

    get '/map-tube/v1/stations/:map' => sub {
        my $client   = request->address;
        my $name     = route_parameters->get('map');
        my $response = api($name)->map_stations($client);

        ...
        ...

        return $response->{content};
    };

    get '/map-tube/v1/maps' => sub {
        my $client   = request->address;
        my $response = api->available_maps($client);

        ...
        ...

        return $response->{content};
    };

=head1 METHODS

=head2 api($map_name)

Returns an object of type L<Dancer2::Plugin::Map::Tube::API>.The C<$map_name> can
be one of the following supported maps. Please make sure map is installed first.

=over 2

=item Barcelona

=item Beijing

=item Berlin

=item Bielefeld

=item Bucharest

=item Budapest

=item Delhi

=item Dnipropetrovsk

=item Glasgow

=item Hongkong

=item Kazan

=item Kharkiv

=item Kiev

=item KoelnBonn

=item Kolkatta

=item KualaLumpur

=item London

=item Lyon

=item Malaga

=item Minsk

=item Moscow

=item Nanjing

=item NizhnyNovgorod

=item Novosibirsk

=item Prague

=item SaintPetersburg

=item Samara

=item Singapore

=item Sofia

=item Tbilisi

=item Vienna

=item Warsaw

=item Yekaterinburg

=back

=cut

our $INSTALLED_MAPS;
our $SUPPORTED_MAPS = [qw/
    Barcelona       Beijing   Berlin          Bielefeld    Bucharest
    Budapest        Delhi     Dnipropetrovsk  Glasgow      Hongkong
    Kazan           Kharkiv   Kiev            KoelnBonn    Kolkatta
    KualaLumpur     London    Lyon            Malaga       Minsk
    Moscow          Nanjing   NizhnyNovgorod  Novosibirsk  Prague
    SaintPetersburg Samara    Singapore       Sofia        Tbilisi
    Vienna          Warsaw    Yekaterinburg/];

register api => sub {
    my ($dsl, $map_name) = @_;

    my $params = { map_name => $map_name };
    my $conf   = plugin_setting();
    if (exists $conf->{user_maps}) {
        my $maps = $conf->{user_maps};
        $params->{user_maps} = $maps if (scalar(@$maps));
    }

    $params->{supported_maps} = { map { $_ => 1      } @$SUPPORTED_MAPS };
    $params->{map_names}      = { map { lc($_) => $_ } @$SUPPORTED_MAPS };

    # If user has provided list of maps then make only those available.
    my $user_maps = {};
    if (defined $params->{user_maps}) {
        $user_maps = {
            map {
                'Map::Tube::'. $params->{map_names}->{lc($_)} => 1
            }
            @{$params->{user_maps}}
        };
    }

    my $maps = { map { 'Map::Tube::'.$_ => $_ } @$SUPPORTED_MAPS };
    foreach my $map (keys %$maps) {
        try_load_class($map) or next;
        next if (scalar(keys %$user_maps) && !exists $user_maps->{$map});
        $INSTALLED_MAPS->{$maps->{$map}} = $map->new;
    }

    $params->{installed_maps} = $INSTALLED_MAPS;

    return Dancer2::Plugin::Map::Tube::API->new($params);
};

register_plugin;

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Dancer2-Plugin-Map-Tube>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Dancer2-Plugin-Map-Tube/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Map::Tube

You can also look for information at:

=over 4

=item * BUGS / ISSUES

L<https://github.com/manwar/Dancer2-Plugin-Map-Tube/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-Map-Tube>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-Map-Tube>

=item * Search MetaCPAN

L<https://metacpan.org/pod/Dancer2::Plugin::Map::Tube>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Dancer2::Plugin::Map::Tube
