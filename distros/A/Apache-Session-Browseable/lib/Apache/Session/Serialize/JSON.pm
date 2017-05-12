# Directly copied from Lemonldap::NG project (http://lemonldap-ng.org/)
package Apache::Session::Serialize::JSON;

use strict;
use JSON qw(to_json from_json);

our $VERSION = '1.2.2';

sub serialize {
    my $session = shift;

    $session->{serialized} = to_json( $session->{data} );
}

sub unserialize {
    my ($session,$next) = @_;

    my $data = _unserialize( $session->{serialized}, $next );
    die "Session could not be unserialized" unless defined $data;
    $session->{data} = $data;
}

sub _unserialize {
    my ( $serialized, $next ) = @_;
    my $tmp;
    eval { $tmp = from_json($serialized) };
    if ($@) {
        require Storable;
        $next ||= \&Storable::thaw;
        return &$next($serialized);
    }
    return $tmp;
}

1;

=pod

=head1 NAME

=encoding utf8

Apache::Session::Serialize::JSON - Use JSON to zip up data

=head1 SYNOPSIS

 use Apache::Session::Serialize::JSON;

 $zipped = Apache::Session::Serialize::JSON::serialize($ref);
 $ref = Apache::Session::Serialize::JSON::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session.
It serializes the data in the session object by use of JSON C<to_json>
and C<from_json>. The serialized data is UTF-8 text.


=head1 SEE ALSO

L<JSON>, L<Apache::Session>

=head1 AUTHORS

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2015-2017 by Clément Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Copyright (C) 2015-2017 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
