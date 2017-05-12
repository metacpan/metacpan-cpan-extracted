use strict;
use warnings;

package App::Map::Metro;

our $VERSION = '0.0100'; # VERSION
# ABSTRACT: Web interface to Map::Metro maps

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Map::Metro - Web interface to Map::Metro maps

=head1 VERSION

Version 0.0100, released 2015-01-24.

=head1 SYNOPSIS

    $ morbo path/to/app-map-metro
    # Then visit http://localhost:3000
    # or:

    $ map-metro.pl mroute Stockholm Akalla Kista

=head1 DESCRIPTION

App::Map::Metro is a simple web interface to L<Map::Metro> implemented in L<Mojolicious>. It can also be used as an alternative backend to the C<route> command, by instead using C<mroute> (currently hardcoded to use C<localhost> and port 3000).

The web interface (available at C<http://localhost:3000>), lists all installed maps and presents two C<select> menus to pick routes in a chosen city.

There is currently no error handlling.

=head1 SEE ALSO

=over 4

=item *

L<Map::Metro>

=item *

L<Task::MapMetro::Maps>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-Map-Metro>.

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson <info@code301.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
