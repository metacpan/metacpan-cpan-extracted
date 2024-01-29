package Dancer2::Plugin::Map::Tube::API;

$Dancer2::Plugin::Map::Tube::API::VERSION   = '0.03';
$Dancer2::Plugin::Map::Tube::API::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Dancer2::Plugin::Map::Tube::API - API for Map::Tube.

=head1 VERSION

Version 0.03

=cut

use 5.006;
use JSON;
use Data::Dumper;
use Cache::Memcached::Fast;
use Dancer2::Plugin::Map::Tube::Error;

use Moo;
use namespace::autoclean;

our $REQUEST_PERIOD    = 60; # seconds.
our $REQUEST_THRESHOLD = 6;  # API calls limit per minute.
our $MEMCACHE_HOST     = 'localhost';
our $MEMCACHE_PORT     = 11211;

has 'map_name'          => (is => 'ro');
has 'user_maps'         => (is => 'rw');
has 'user_error'        => (is => 'rw');
has 'installed_maps'    => (is => 'ro');
has 'map_names'         => (is => 'ro');
has 'supported_maps'    => (is => 'ro');
has 'request_period'    => (is => 'ro', default => sub { $REQUEST_PERIOD    });
has 'request_threshold' => (is => 'ro', default => sub { $REQUEST_THRESHOLD });
has 'memcache_host'     => (is => 'ro', default => sub { $MEMCACHE_HOST     });
has 'memcache_port'     => (is => 'ro', default => sub { $MEMCACHE_PORT     });
has 'memcached'         => (is => 'rw');
has 'map_object'        => (is => 'rw');

=head1 DESCRIPTION

It is the backbone for L<Map::Tube::Server> and provides the core functionalities
for the REST API.

This is  part of Dancer2 plugin L<Dancer2::Plugin::Map::Tube> distribution, which
makes most of work for L<Map::Tube::Server>.

=cut

sub BUILD {
    my ($self, $arg) = @_;

    my $address = sprintf("%s:%d", $self->memcache_host, $self->memcache_port);
    $self->{memcached} = Cache::Memcached::Fast->new({ servers => [{ address => $address }] });

    my $map_name = $self->map_name;
    if (defined $map_name) {
        unless (exists $self->{map_names}->{lc($map_name)}) {
            $self->{user_error} =  {
                error_code    => $BAD_REQUEST,
                error_message => $RECEIVED_INVALID_MAP_NAME,
            };
            return;
        }

        unless (exists $self->{installed_maps}->{$self->{map_names}->{lc($map_name)}}) {
            $self->{user_error} = {
                error_code    => $BAD_REQUEST,
                error_message => $MAP_NOT_INSTALLED,
            };
            return;
        }

        $self->{map_object} = $self->{installed_maps}->{$self->{map_names}->{lc($map_name)}};
    }
}

=head1 METHODS

=head2 shortest_route($client_ip, $start, $end)

Returns ordered list of stations for the shortest route from C<$start> to C<$end>.

=cut

sub shortest_route {
    my ($self, $client_ip, $start, $end) = @_;

    return { error_code    => $TOO_MANY_REQUEST,
             error_message => $REACHED_REQUEST_LIMIT,
    } unless $self->_is_authorized($client_ip);

    my $map_name = $self->{map_name};
    return { error_code    => $BAD_REQUEST,
             error_message => $MISSING_MAP_NAME,
    } unless (defined $map_name && ($map_name !~ /^$/));

    return { error_code    => $BAD_REQUEST,
             error_message => $MISSING_START_STATION_NAME,
    } unless (defined $start && ($start !~ /^$/));

    return { error_code    => $BAD_REQUEST,
             error_message => $MISSING_END_STATION_NAME,
    } unless (defined $end && ($end !~ /^$/));

    my $object = $self->map_object;
    return { error_code    => $BAD_REQUEST,
             error_message => $RECEIVED_UNSUPPORTED_MAP_NAME,
    } unless (defined $object);

    eval { $object->get_node_by_name($start) };
    return { error_code    => $BAD_REQUEST,
             error_message => $RECEIVED_INVALID_START_STATION_NAME,
    } if ($@);

    eval { $object->get_node_by_name($end) };
    return { error_code    => $BAD_REQUEST,
             error_message => $RECEIVED_INVALID_END_STATION_NAME,
    } if ($@);

    my $route    = $object->get_shortest_route($start, $end);
    my $stations = [ map { sprintf("%s", $_) } @{$route->nodes} ];

    return _jsonified_content($stations);
};

=head2 line_stations($client_ip, $line)

Returns the list of stations, indexed if it is available, in the given C<$line>.

=cut

sub line_stations {
    my ($self, $client_ip, $line_name) = @_;

    return { error_code    => $TOO_MANY_REQUEST,
             error_message => $REACHED_REQUEST_LIMIT,
    } unless $self->_is_authorized($client_ip);

    return $self->{user_error} if (defined $self->{user_error});

    my $map_name = $self->{map_name};
    return { error_code    => $BAD_REQUEST,
             error_message => $MISSING_MAP_NAME,
    } unless (defined $map_name && ($map_name !~ /^$/));

    return { error_code    => $BAD_REQUEST,
             error_message => $MISSING_LINE_NAME,
    } unless (defined $line_name && ($line_name !~ /^$/));

    my $object = $self->map_object;
    return { error_code    => $BAD_REQUEST,
             error_message => $RECEIVED_UNSUPPORTED_MAP_NAME,
    } unless (defined $object);

    eval { $object->get_line_by_name($line_name) };
    return { error_code    => $BAD_REQUEST,
             error_message => $RECEIVED_INVALID_LINE_NAME,
    } if ($@);

    my $stations = $object->get_stations($line_name);

    return _jsonified_content([ map { sprintf("%s", $_) } @{$stations} ]);
};

=head2 map_stations($client_ip)

Returns ordered list of stations in the map.

=cut

sub map_stations {
    my ($self, $client_ip) = @_;

    return { error_code    => $TOO_MANY_REQUEST,
             error_message => $REACHED_REQUEST_LIMIT,
    } unless $self->_is_authorized($client_ip);

    return $self->{user_error} if (defined $self->{user_error});

    my $map_name = $self->{map_name};
    return { error_code    => $BAD_REQUEST,
             error_message => $MISSING_MAP_NAME,
    } unless (defined $map_name && ($map_name !~ /^$/));

    my $object = $self->map_object;
    return { error_code    => $BAD_REQUEST,
             error_message => $RECEIVED_UNSUPPORTED_MAP_NAME,
    } unless (defined $object);

    my $stations = {};
    foreach my $station (@{$object->get_stations}) {
        $stations->{sprintf("%s", $station)} = 1;
    }

    return _jsonified_content([ sort keys %$stations ]);
};

=head2 available_maps($client)

Returns ordered list of available maps.

=cut

sub available_maps {
    my ($self, $client_ip) = @_;

    return { error_code    => $TOO_MANY_REQUEST,
             error_message => $REACHED_REQUEST_LIMIT,
    } unless $self->_is_authorized($client_ip);

    my $maps = [ sort keys %{$self->{installed_maps}} ];

    return _jsonified_content($maps);
};

#
#
# PRIVATE METHODS

sub _jsonified_content {
    my ($data) = @_;

    return { content => JSON->new->allow_nonref->utf8(1)->encode($data) };
}

sub _is_authorized {
    my ($self, $client_ip) = @_;

    my $userdata = $self->memcached->get('userdata');
    my $now = time;

    if (defined $userdata) {
        if (exists $userdata->{$client_ip}) {
            my $old = $userdata->{$client_ip}->{last_access_time};
            my $cnt = $userdata->{$client_ip}->{count};
            if (($now - $old) < $self->request_period) {
                if (($cnt + 1) > $self->request_threshold) {
                    return 0;
                }
                else {
                    $userdata->{$client_ip}->{last_access_time} = $now;
                    $userdata->{$client_ip}->{count} = $cnt + 1;
                }
            }
            else {
                $userdata->{$client_ip}->{last_access_time} = $now;
                $userdata->{$client_ip}->{count} = 1;
            }
        }
        else {
            $userdata->{$client_ip}->{last_access_time} = $now;
            $userdata->{$client_ip}->{count} = 1;
        }

        $self->memcached->replace('userdata', $userdata);
    }
    else {
        $userdata->{$client_ip}->{last_access_time} = $now;
        $userdata->{$client_ip}->{count} = 1;

        $self->memcached->add('userdata', $userdata);
    }

    return 1;
}

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

    perldoc Dancer2::Plugin::Map::Tube::API

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

1; # End of Dancer2::Plugin::Map::Tube::API
