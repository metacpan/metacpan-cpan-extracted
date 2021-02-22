package CPANPLUS::Dist::Slackware::Plugin::Alien::wxWidgets;

use strict;
use warnings;

our $VERSION = '1.030';

sub available {
    my ( $plugin, $dist ) = @_;

    return ( $dist->parent->package_name eq 'Alien-wxWidgets' );
}

sub pre_prepare {
    my ( $plugin, $dist ) = @_;

    if ( !exists $ENV{AWX_URL} && !exists $ENV{WX_CONFIG} ) {
        $ENV{AWX_URL} = 'https://prdownloads.sourceforge.net/wxwindows';
    }

    return 1;
}

sub post_prepare {
    my ( $plugin, $dist ) = @_;

    delete $ENV{AWX_URL};

    return 1;
}

1;
__END__

=head1 NAME

CPANPLUS::Dist::Slackware::Plugin::Alien::wxWidgets - Configure Alien::wxWidgets

=head1 VERSION

This document describes CPANPLUS::Dist::Slackware::Plugin::Alien::wxWidgets version 1.030.

=head1 SYNOPSIS

    $is_available = $plugin->available($dist);
    $success = $plugin->pre_prepare($dist);
    $success = $plugin->post_prepare($dist);

=head1 DESCRIPTION

Configures Alien::wxWidgets to download and build its own version of the
wxWidgets library unless C<$ENV{WX_CONFIG}> is set to the full path to
F<wx-config>.

If wxGTK3 or wxPython is installed you can set C<$ENV{WX_CONFIG}> to
F</usr/bin/wx-config>. You will have to rebuild Alien::wxWidgets and Wx
whenever wxWidgets is updated, though.

=head1 SUBROUTINES/METHODS

=over 4

=item B<< $plugin->available($dist) >>

Returns true if this plugin applies to the given Perl distribution.

=item B<< $plugin->pre_prepare($dist) >>

If neither C<$ENV{AWX_URL}> nor C<$ENV{WX_CONFIG}> are set, sets
C<$ENV{AWX_URL}> to C<https://prdownloads.sourceforge.net/wxwindows>, which
causes Alien::wxWidgets to ignore existing wxWidgets installations and build
its own library.

=item B<< $plugin->post_prepare($dist) >>

Unsets C<$ENV{AWX_URL}>.

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

Please report any bugs using the issue tracker at
L<https://github.com/graygnuorg/CPANPLUS-Dist-Slackware/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2020 Andreas Voegele

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See https://dev.perl.org/licenses/ for more information.

=cut
