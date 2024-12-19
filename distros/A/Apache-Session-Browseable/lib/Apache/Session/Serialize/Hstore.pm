package Apache::Session::Serialize::Hstore;

use strict;
use JSON qw(to_json from_json);

our $VERSION = '1.2.5';

sub serialize {
    my ($session) = @_;
    $session->{serialized} = {};
    my $data = $session->{data};
    my $res  = '';
    if ( ref $data and %$data ) {
        foreach ( keys %$data ) {
            my $v;
            if ( ref $data->{$_} ) {
                $v = '_json://' . to_json( $data->{$_} );
            }
            else {
                $v = $data->{$_};
            }
            $v =~ s/"/#%22/g;
            $res .= qq'"$_" => "$v",';
        }
    }
    $res =~ s/,$//;
    $session->{serialized} = $res;
}

sub unserialize {
    my ($session) = @_;

    my $data = _unserialize( $session->{serialized} );
    die "Session could not be unserialized" unless defined $data;
    $session->{data} = $data;
}

sub _unserialize {
    my ( $serialized, $next ) = @_;
    my $res = {};
    while ( $serialized =~ s/\s*"([^"]*)"\s*=>\s*"([^"]*)"\s*,?// ) {
        my ( $k, $v ) = ( $1, $2 );
        $v =~ s/#%22/"/g;
        if ( $v =~ s#^_json://## ) {
            my $tmp;
            eval { $tmp = from_json($v) };
            if ($@) {
                print STDERR "JSON error: $@\n";
                return undef;
            }
            $v = $tmp;
        }
        $res->{$k} = $v;
    }
    return $res;
}

1;

=pod

=head1 NAME

=encoding utf8

Apache::Session::Serialize::Hstore - Serialize/unserialize datas for PostgreSQL
"hstore" storage.

=head1 SYNOPSIS

 use Apache::Session::Serialize::Hstore;

 $zipped = Apache::Session::Serialize::Hstore::serialize($ref);
 $ref = Apache::Session::Serialize::Hstore::unserialize($zipped);

=head1 DESCRIPTION

This module fulfills the serialization interface of Apache::Session.
It serializes only ref data value for PostgreSQL "hstore" fields.

=head1 SEE ALSO

L<JSON>, L<Apache::Session>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 COPYRIGHT AND LICENSE

=over

=item 2009-2023 by Xavier Guimard

=item 2013-2023 by Clément Oudot

=item 2019-2023 by Maxime Besson

=item 2013-2023 by Worteks

=item 2023 by Linagora

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
