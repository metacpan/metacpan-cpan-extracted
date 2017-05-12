package CPANPLUS::Dist::Slackware::Plugin::Net::Pcap;

use strict;
use warnings;

our $VERSION = '1.024';

use File::Spec qw();

sub available {
    my ( $plugin, $dist ) = @_;
    return ( $dist->parent->package_name eq 'Net-Pcap' );
}

sub pre_prepare {
    my ( $plugin, $dist ) = @_;

    my $module = $dist->parent;
    my $cb     = $module->parent;

    my $wrksrc = $module->status->extract;
    return if !$wrksrc;

    # See L<https://rt.cpan.org/Ticket/Display.html?id=73335>.
    my $offending_code = qr/
        \$options[{]CCFLAGS[}] \s* = \s* ["']-Wall \s+ -Wwrite-strings["'] .*?;
    /xms;
    my $filename = File::Spec->catfile( $wrksrc, 'Makefile.PL' );
    if ( -f $filename ) {
        my $code = $dist->_read_file($filename);
        if ( $code =~ $offending_code ) {
            $code =~ s/$offending_code//;
            $cb->_move( file => $filename, to => "$filename.orig" ) or return;
            $dist->_write_file( $filename, $code ) or return;
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

CPANPLUS::Dist::Slackware::Plugin::Net::Pcap - Patch Makefile.PL

=head1 VERSION

This document describes CPANPLUS::Dist::Slackware::Plugin::Net::Pcap version 1.024.

=head1 SYNOPSIS

    $is_available = $plugin->available($dist);
    $success = $plugin->pre_prepare($dist);

=head1 DESCRIPTION

Fix the libpcap detection.  Reported as bug #73335 at L<http://rt.cpan.org/>.

=head1 SUBROUTINES/METHODS

=over 4

=item B<< $plugin->available($dist) >>

Returns true if this plugin applies to the given Perl distribution.

=item B<< $plugin->pre_prepare($dist) >>

Patch F<Makefile.PL> if necessary.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires the module File::Spec.

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

Copyright 2012-2016 Andreas Voegele

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut
