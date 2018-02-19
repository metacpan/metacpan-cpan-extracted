=head1 NAME

WWW::Shorten::Debli - Perl interface to deb.li

=head1 SYNOPSIS

  use WWW::Shorten 'Debli';

  $short_url = makeashorterlink($long_url);

  $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site L<https://deb.li>. Deb.li provides a URL
shortening service primarily for Debian contributors.

=cut

package WWW::Shorten::Debli;

use strict;
use warnings;

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw(makeashorterlink makealongerlink);
our $VERSION = '0.1';

use Carp;
use JSON::RPC::Client::Any;

our $RPC_URL = 'https://deb.li/rpc/json';

=head1 Functions

=over

=item B<makeashorterlink>(I<URL>)

The function C<makeashorterlink> will connect to deb.li passing it
the URL and will return the shortened variant.

=cut

sub makeashorterlink {
    my $url = shift or croak 'No URL passed to makeashorterlink';
    my $rpc = JSON::RPC::Client::Any->new();
    my $res
        = $rpc->call( $RPC_URL => { method => 'add_url', params => [$url] } );
    return undef unless $res;
    return undef if $res->is_error;
    return 'https://deb.li/' . $res->result;
}

=item makealongerlink

The function C<makealongerlink> does the reverse. It will accept as an argument
either the full deb.li URL or just the key.

If anything goes wrong, then either function will return C<undef>.

=back

=cut

sub makealongerlink {
    my $key = shift or croak 'No key / URL passed to makealongerlink';
    $key =~ s,^https?://deb.li/,,;
    my $rpc = JSON::RPC::Client::Any->new();
    my $res
        = $rpc->call( $RPC_URL => { method => 'get_url', params => [$key] } );
    return undef unless $res;
    return undef if $res->is_error;
    return $res->result;
}

1;

__END__

=head2 EXPORT

makeashorterlink, makealongerlink

=head1 COPYRIGHT & LICENSE

Copyright (C) 2012 Damyan Ivanov L<dmn@debian.org>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version.

=head1 SEE ALSO

L<WWW::Shorten>, L<https://deb.li/>

=cut
