package CPANPLUS::Dist::Debora::Package::Mageia;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.016';

use parent qw(CPANPLUS::Dist::Debora::Package::RPM);

use CPANPLUS::Dist::Debora::Util qw(parse_version);

sub format_priority {
    my $class = shift;

    my $priority = 0;
    if (-f '/etc/mageia-release') {
        $priority = $class->SUPER::format_priority;
        if ($priority > 0) {
            $priority = 3;
        }
    }

    return $priority;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

sub _normalize_version {
    my ($self, $dist_version) = @_;

    my $version = $self->SUPER::_normalize_version($dist_version);
    $version = parse_version($version)->normal;
    $version =~ s{\A v}{}xms;

    return $version;
}

1;
__END__

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora::Package::Mageia - Create binary RPM packages

=head1 VERSION

version 0.016

=head1 SYNOPSIS

  use CPANPLUS::Dist::Debora::Package::Mageia;

  my $package =
      CPANPLUS::Dist::Debora::Package::Mageia->new(module => $module);

  my $ok = $package->create(verbose => 0|1);
  my $ok = $package->install(verbose => 0|1);

=head1 DESCRIPTION

This L<CPANPLUS::Dist::Debora::Package::RPM> subclass creates binary RPM
packages from Perl distributions on Mageia systems.

Mageia uses normalized package versions.

=head1 SUBROUTINES/METHODS

=head2 format_priority

  my $priority = CPANPLUS::Dist::Debora::Package::Mageia->format_priority;

Checks if the RPM package tools are available and if the system is Mageia.

=head1 DIAGNOSTICS

See L<CPANPLUS::Dist::Debora> for diagnostics.

=head1 CONFIGURATION AND ENVIRONMENT

See L<CPANPLUS::Dist::Debora> for supported files and environment variables.

=head1 DEPENDENCIES

See L<CPANPLUS::Dist::Debora::Package::RPM> for dependencies.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

See L<CPANPLUS::Dist::Debora::Package::RPM> for bugs and limitations.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
