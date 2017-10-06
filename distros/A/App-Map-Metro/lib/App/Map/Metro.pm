use strict;
use warnings;

package App::Map::Metro;

# ABSTRACT: Web interface to Map::Metro maps
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Map::Metro - Web interface to Map::Metro maps



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-App-Map-Metro"><img src="https://api.travis-ci.org/Csson/p5-App-Map-Metro.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/App-Map-Metro-0.0200"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/App-Map-Metro/0.0200" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=App-Map-Metro%200.0200"><img src="http://badgedepot.code301.com/badge/cpantesters/App-Map-Metro/0.0200" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-81.8%-orange.svg" alt="coverage 81.8%" />
</p>

=end html

=head1 VERSION

Version 0.0200, released 2017-09-30.

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

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
