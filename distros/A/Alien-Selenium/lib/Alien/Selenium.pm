package Alien::Selenium;

use strict;
use warnings;

use File::Copy ();
use File::Path ();
use File::Basename qw(dirname);

=head1 NAME

Alien::Selenium - installing and finding the Selenium Web test framework

=head1 SYNOPSIS

    use Alien::Selenium;

    my $version = Alien::Selenium->version;
    my $path    = Alien::Selenium->path;

    Alien::Selenium->install( $destination_directory );

=head1 DESCRIPTION

Please see L<Alien> for the manifesto of the Alien namespace.

=cut

use strict;

our $VERSION = '0.09';
our $SELENIUM_VERSION = '0.8.3';

=over

=item I<version ()>

Returns the version of Selenium that is contained within this Alien
package (not to be confused with $Alien::Selenium::VERSION, which is
the version number of the Perl wrapper)

=cut

sub version { $SELENIUM_VERSION }

=item I<path ()>

Returns the path where a file-for-file copy of the Selenium core has
been installed as part of the Alien::Selenium Perl package.  One may
direct one's webserver to serve files directly off I<path()>, or
alternatively use L</install>.

=cut

sub path {
    my $base = $INC{'Alien/Selenium.pm'};

    $base =~ s{\.pm$}{/javascript};

    return $base;
}

=item I<install ($destdir)>

Install a copy of the contents of L</path> into $dest_dir, which need
not exist beforehand.

=cut

sub install {
    my( $class, $dest_dir ) = @_;

    File::Path::mkpath $dest_dir;

    my $path = $class->path();
    foreach my $f ( grep { -f $_ }
                         glob "$path/*" ) {
        File::Copy::copy( $f, $dest_dir )
            or die "Can't copy $f to $dest_dir: $!";
    }
}

=item I<path_readystate_xpi ()>

Returns the path to the C<readyState.xpi> Mozilla/Firefox extension
that is part of Selenium starting at version 0.8.0.  Returns undef for
versions of Selenium that do not have such a file.

=cut

sub path_readystate_xpi {
    my $base = $INC{'Alien/Selenium.pm'};

    $base =~ s{\.pm$}{/xpi/readyState.xpi};
    return if ! -f $base;
    return $base;
}

=item I<install_readystate_xpi ($targetfile)>

Installs the C<readyState.xpi> file as $targetfile, creating any
missing directories if needed.  Croaks if there is no
C<readyState.xpi> in this version of Selenium (see
L</path_readystate_xpi>).

=cut

sub install_readystate_xpi {
    my ($class, $targetfile) = @_;

    die "no readyState.xpi in this version of Selenium ($SELENIUM_VERSION)"
        unless defined(my $srcfile = $class->path_readystate_xpi());

    File::Path::mkpath (dirname($targetfile));
    File::Copy::copy($srcfile, $targetfile)
        or die "Can't copy $srcfile to $targetfile: $!";
}

=back

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>
Dominique Quatravaux <domq@cpan.org>

=head1 LICENSE

Copyright (c) 2005-2006 Mattia Barbon <mbarbon@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself

Please notice that Selenium comes with its own licence.

=cut

1;
