package CPANPLUS::Dist::Slackware::Plugin::GD;

use strict;
use warnings;

our $VERSION = '1.024';

use File::Spec qw();

sub available {
    my ( $plugin, $dist ) = @_;

    my $module = $dist->parent;

    if ( $module->package_name eq 'GD' ) {
        if ( $module->package_version =~ /^2\.5[56]$/ ) {
            $module->status->installer_type('CPANPLUS::Dist::Build');
        }
        return 1;
    }
    return 0;
}

sub pre_prepare {
    my ( $plugin, $dist ) = @_;

    my $module = $dist->parent;
    my $cb     = $module->parent;

    my $wrksrc = $module->status->extract;
    return if !$wrksrc;

    # Only install the bdf2gdfont.pl script.
    my $build_pl = File::Spec->catfile( $wrksrc, 'Build.PL' );
    if ( -f $build_pl ) {
        my $code = $dist->_read_file($build_pl);
        if ( $code =~ /script_files \s+ => \s+ 'bdf_scripts'/xms ) {
            $code =~ s{
                (script_files \s+ => \s+) 'bdf_scripts'
            }{$1 'bdf_scripts/bdf2gdfont.pl'}xms;
            $cb->_move( file => $build_pl, to => "$build_pl.orig" ) or return;
            $dist->_write_file( $build_pl, $code ) or return;
        }
    }

    # Force the test suite to recreate the test image files.
    my $gd_t = File::Spec->catfile( $wrksrc, 't', 'GD.t' );
    if ( -f $gd_t ) {
        my $code = $dist->_read_file($gd_t);
        if ( $code =~ /if \(defined \$arg && \$arg eq '--write'\)/ ) {
            $code =~ s{if \(defined \$arg && \$arg eq '--write'\)}{if (1)};
            $cb->_move( file => $gd_t, to => "$gd_t.orig" ) or return;
            $dist->_write_file( $gd_t, $code ) or return;
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

CPANPLUS::Dist::Slackware::Plugin::GD - Patch Build.PL and the tests

=head1 VERSION

This document describes CPANPLUS::Dist::Slackware::Plugin::GD version 1.024.

=head1 SYNOPSIS

    $is_available = $plugin->available($dist);
    $success = $plugin->pre_prepare($dist);

=head1 DESCRIPTION

Prefer Build.PL over the broken Makefile.PL when building GD 2.55 or 2.56.
Only install the bdf2gdfont.pl script in /usr/bin and not the README file.
Force the test suite to recreate the test image files as the tests are prone
to fail.

=head1 SUBROUTINES/METHODS

=over 4

=item B<< $plugin->available($dist) >>

Returns true if this plugin applies to the given Perl distribution.

=item B<< $plugin->pre_prepare($dist) >>

Patch F<Build.PL> and F<t/GD.t>.

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

Copyright 2014-2016 Andreas Voegele

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut
