use Map::Metro::Standard::Moops;
use strict;
use warnings;

our $VERSION = '0.0100'; # VERSION:
# PODNAME: Map::Metro::Cmd::Mroute

class Map::Metro::Cmd::Mroute extends Map::Metro::Cmd using Moose {

    use MooseX::App::Command;
    use HTTP::Tiny;

    parameter cityname => (
        is => 'rw',
        isa => Str,
        documentation => 'The name of the city you want to search in',
        required => 1,
    );
    parameter origin => (
        is => 'rw',
        isa => Str,
        documentation => 'Start station',
        required => 1,
    );
    parameter destination => (
        is => 'rw',
        isa => Str,
        documentation => 'Final station',
        required => 1,
    );

    command_short_description 'Search in a map';

    method run {

        my $url = sprintf 'http://localhost:3000/%s/%s/%s.txt', $self->cityname, $self->origin, $self->destination;
        my $content = HTTP::Tiny->new->get($url)->{'content'};
        print $content;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Cmd::Mroute

=head1 VERSION

Version 0.0100, released 2015-01-24.

=head1 DESCRIPTION

See L<route|Map::Metro::Cmd/"map-metro.pl route $city $from $to">.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-Map-Metro>.

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
