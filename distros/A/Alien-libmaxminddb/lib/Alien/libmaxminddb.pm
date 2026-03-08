package Alien::libmaxminddb;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.014;
use warnings;
use utf8;

our $VERSION = 2.003;

use File::Spec qw();
use JSON::PP   qw();

sub cflags {
    my $class = shift;

    return $class->config->{cflags};
}

sub libs {
    my $class = shift;

    return $class->config->{libs};
}

sub version {
    my $class = shift;

    return $class->config->{version};
}

sub install_type {
    my $class = shift;

    return $class->config->{install_type};
}

sub config {
    my $class = shift;

    state $config = $class->_config;
    return $config;
}

sub dynamic_libs {
    my $class = shift;

    return;
}

sub bin_dir {
    my $class = shift;

    return;
}

sub _dist_dir_with_subdir {
    my ($class, $subdir) = @_;

    my $dist = $class;
    $dist =~ s/::/-/g;

    my $search_dir = File::Spec->catdir(qw(auto share dist), $dist, $subdir);
    for my $inc (@INC) {
        my $dir = File::Spec->catdir($inc, $search_dir);
        if (-d $dir) {
            return $dir;
        }
    }
    die "unable to find dist share directory for $dist";
}

sub _config {
    my $class = shift;

    my $alien_dir = $class->_dist_dir_with_subdir('_alien');

    my $json_file = File::Spec->catfile($alien_dir, 'alien.json');
    open my $in, '<', $json_file
        or die "Cannot read $json_file";
    my $json = do { local $/; <$in> };
    close $in;

    my $config = JSON::PP::decode_json($json);

    if ($config->{install_type} eq 'share') {
        my $inc_dir = $class->_dist_dir_with_subdir('include');
        $config->{cflags} = join ' ', "-I$inc_dir", $config->{cflags};
        my $lib_dir = $class->_dist_dir_with_subdir('lib');
        $config->{libs} = join ' ', "-L$lib_dir", $config->{libs};
    }

    return $config;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Alien::libmaxminddb - Find or install libmaxminddb

=head1 VERSION

version 2.003

=head1 SYNOPSIS

Add the library to your F<dist.ini> if you use Dist::Zilla.

  [@Filter]
  -bundle = @Basic
  -remove = MakeMaker

  [Prereqs / ConfigureRequires]
  Alien::libmaxminddb = 0

  [Prereqs / BuildRequires]
  Alien::libmaxminddb = 0

  [MakeMaker::Awesome]
  header = use Config;
  header = use Alien::libmaxminddb;
  WriteMakefile_arg = CCFLAGS => Alien::libmaxminddb->cflags . ' ' . $Config{ccflags}
  WriteMakefile_arg = LIBS => [ Alien::libmaxminddb->libs ]

  [Prereqs / DevelopRequires]
  Dist::Zilla = 0
  Dist::Zilla::Plugin::MakeMaker::Awesome = 0

=head1 DESCRIPTION

MaxMind and DP-IP.com provide geolocation databases in the MaxMind DB file
format format.  This Perl module finds or installs the C library libmaxminddb,
which can read MaxMind DB files.

=head1 SUBROUTINES/METHODS

=head2 cflags

  my $cflags = Alien::libmaxminddb->cflags;

Returns the C compiler flags necessary to compile an XS module that uses
libmaxminddb.

=head2 libs

  my $libs = Alien::libmaxminddb->libs;

Returns the library linker flags necessary to link an XS module against
libmaxminddb.

=head2 version

  my $version = Alien::libmaxminddb->version;

Returns the libmaxminddb version.

=head2 install_type

  my $install_type = Alien::libmaxminddb->install_type;

Returns "system" if the library is provided by the operating system or "share"
if the bundled library is used.

=for Pod::Coverage config dynamic_libs bin_dir

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Install C<pkg-config> and C<libmaxminddb-devel> or C<libmaxminddb-dev> if you
would like to use your operating system's libmaxminddb library.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

L<Geo::Location::IP>, L<IP::Geolocation::MMDB>

=head1 ACKNOWLEDGEMENTS

Thanks to all who have contributed patches and reported bugs:

=over

=item *

Alex Granovskiy

=back

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The libmaxminddb library is licensed under the Apache License, Version 2.0.

=cut
