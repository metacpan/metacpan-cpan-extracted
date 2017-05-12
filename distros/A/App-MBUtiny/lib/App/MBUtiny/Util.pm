package App::MBUtiny::Util; # $Id: Util.pm 52 2014-09-03 12:41:26Z abalama $
use strict;

=head1 NAME

App::MBUtiny::Util - Internal utilities used by App::MBUtiny module

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MBUtiny::Util;

=head1 DESCRIPTION

Internal utility functions

=over 8

=item B<md5sum>

    my $md5 = md5sum( $filename );

See L<Digest::MD5>

=item B<sha1sum>

    my $sha1 = sha1sum( $filename );

See L<Digest::SHA1>

=item B<resolv>

    my $name = resolv( $IPv4 );
    my $ip = resolv( $name );

Resolv ip to a hostname or hostname to ip. See L<Sys::Net/"resolv">, L<Socket/"inet_ntoa">
and L<Socket/"inet_aton">

=back

=head1 HISTORY

See C<CHANGES> file

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw($VERSION);
$VERSION = '1.01';

use CTK::Util qw/ :API /;
use Digest::MD5;
use Digest::SHA1;
use Socket qw/inet_ntoa inet_aton AF_INET/;

use base qw/Exporter/;
our @EXPORT = qw(
        sha1sum
        md5sum
        resolv
    );
our @EXPORT_OK = @EXPORT;

sub sha1sum { # Генерация sha1 суммы
    my $f = shift;
    my $sha1 = new Digest::SHA1;
    my $sum = '';
    return $sum unless -e $f;
    open( my $sha1_fh, '<', $f) or (carp("Can't open '$f': $!") && return $sum);
    if ($sha1_fh) {
        binmode($sha1_fh);
        $sha1->addfile($sha1_fh);
        $sum = $sha1->hexdigest;
        close($sha1_fh);
    }
    return $sum;
}
sub md5sum { # Генерация md5 суммы
    my $f = shift;
    my $md5 = new Digest::MD5;
    my $sum = '';
    return $sum unless -e $f;
    open( my $md5_fh, '<', $f) or (carp("Can't open '$f': $!") && return $sum);
    if ($md5_fh) {
        binmode($md5_fh);
        $md5->addfile($md5_fh);
        $sum = $md5->hexdigest;
        close($md5_fh);
    }
    return $sum;
}
sub resolv { # Resolving. See Socket::inet_ntoa
    # Original: Sys::Net::resolv
    my $name = shift;
    # resolv ip to a hostname
    if ($name =~ m/^\s*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s*$/) {
        return scalar gethostbyaddr(inet_aton($name), AF_INET);
    }
    # resolv hostname to ip
    else {
        return inet_ntoa(scalar gethostbyname($name));
    }
}

1;
