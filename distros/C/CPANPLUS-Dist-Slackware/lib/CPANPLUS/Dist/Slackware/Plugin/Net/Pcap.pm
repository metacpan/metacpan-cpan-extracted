package CPANPLUS::Dist::Slackware::Plugin::Net::Pcap;

use strict;
use warnings;

our $VERSION = '1.027';

use CPANPLUS::Dist::Slackware::Util qw(catfile slurp spurt);

sub available {
    my ( $plugin, $dist ) = @_;

    return ( $dist->parent->package_name eq 'Net-Pcap' );
}

sub pre_prepare {
    my ( $plugin, $dist ) = @_;

    # See L<https://rt.cpan.org/Ticket/Display.html?id=117831>.
    my $fn = catfile( 't', '09-error.t' );
    if ( -f $fn ) {
        my $code = slurp($fn);
        $code =~ s/\^(\Q(?:parse|syntax)\E)/$1/xms;
        spurt( $fn, $code ) or return;
    }

    return 1;
}

1;
__END__

=head1 NAME

CPANPLUS::Dist::Slackware::Plugin::Net::Pcap - Patch Makefile.PL

=head1 VERSION

This document describes CPANPLUS::Dist::Slackware::Plugin::Net::Pcap version 1.027.

=head1 SYNOPSIS

    $is_available = $plugin->available($dist);
    $success = $plugin->pre_prepare($dist);

=head1 DESCRIPTION

Adapt a test to libpcap 1.8.0.  See bug #117831 at L<http://rt.cpan.org/> for
more information.

=head1 SUBROUTINES/METHODS

=over 4

=item B<< $plugin->available($dist) >>

Returns true if this plugin applies to the given Perl distribution.

=item B<< $plugin->pre_prepare($dist) >>

Patch F<t/09-error.t> if necessary.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None known.

=head1 SEE ALSO

CPANPLUS::Dist::Slackware

=head1 AUTHOR

Andreas Voegele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

Please report any bugs to C<bug-cpanplus-dist-slackware at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2018 Andreas Voegele

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut
