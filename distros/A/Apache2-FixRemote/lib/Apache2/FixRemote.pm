package Apache2::FixRemote;

use warnings FATAL => 'all';
use strict;

use Apache2::RequestRec ();
use Apache2::Connection ();
use Apache2::Log        ();

use Apache2::Const -compile => qw(OK);

use APR::Table  ();

=head1 NAME

Apache2::FixRemote - Reset remote IP with contents of X-Forwarded-For header

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    # httpd.conf
    PerlModule Apache2::FixRemote

    PerlPostReadRequestHandler Apache2::FixRemote

    # or alternatively use any handler stage after map-to-storage, such as:
    <Location /foo>
    PerlHeaderParserHandler Apache2::FixRemote
    </Location>

=cut

sub handler {
    my $r = shift;
    my $hdr = $r->headers_in->get('X-Forwarded-For');
    if ($hdr and $hdr =~ /^\d+\.\d+\.\d+\.\d+$/) {
        my $old = $r->connection->remote_ip($hdr);
        $r->log->debug("Changed inbound IP from $old to $hdr");
    }
    Apache2::Const::OK;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-fixremote at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-FixRemote>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::FixRemote

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-FixRemote>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-FixRemote>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-FixRemote>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-FixRemote>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dorian Taylor, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::FixRemote
