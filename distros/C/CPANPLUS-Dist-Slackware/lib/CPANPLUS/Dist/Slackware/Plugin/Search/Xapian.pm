package CPANPLUS::Dist::Slackware::Plugin::Search::Xapian;

use strict;
use warnings;

our $VERSION = '1.030';

use CPANPLUS::Dist::Slackware::Util qw(catfile slurp spurt);

sub available {
    my ( $plugin, $dist ) = @_;

    return ( $dist->parent->package_name eq 'Search-Xapian' );
}

sub pre_prepare {
    my ( $plugin, $dist ) = @_;

    # See L<https://trac.xapian.org/ticket/692>.
    my $fn = 'Makefile.PL';
    if ( -f $fn ) {
        my $code = slurp($fn);
        $code =~ s/(if \(defined \$builddir)\)/$1 && \$builddir ne \$srcdir)/;
        spurt( $fn, $code ) or return;
    }

    return 1;
}

1;
__END__

=head1 NAME

CPANPLUS::Dist::Slackware::Plugin::Search::Xapian - Patch Makefile.PL

=head1 VERSION

This document describes CPANPLUS::Dist::Slackware::Plugin::Search::Xapian version 1.030.

=head1 SYNOPSIS

    $is_available = $plugin->available($dist);
    $success = $plugin->pre_prepare($dist);

=head1 DESCRIPTION

When building Search::Xapian up to version 1.2.21.0 with CPANPLUS the make command
gets into an infinite loop.  Reported as bug #692 at L<https://trac.xapian.org/>.

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

Copyright 2015-2020 Andreas Voegele

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See https://dev.perl.org/licenses/ for more information.

=cut
