use 5.10.0;
use strict;
use warnings;

package Map::Metro::Cmd::Mroute;

# ABSTRACT: Search in a map
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use Moose;
use MooseX::App::Command;
use HTTP::Tiny;
use Types::Standard qw/Str/;
extends 'Map::Metro::Cmd';

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

sub run {
    my $self = shift;

    my $url = sprintf 'http://localhost:3000/%s/%s/%s.txt', $self->cityname, $self->origin, $self->destination;
    my $content = HTTP::Tiny->new->get($url)->{'content'};
    print $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Cmd::Mroute - Search in a map

=head1 VERSION

Version 0.0200, released 2017-09-30.

=head1 DESCRIPTION

See L<route|Map::Metro::Cmd/"map-metro.pl route $city $from $to">.

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
