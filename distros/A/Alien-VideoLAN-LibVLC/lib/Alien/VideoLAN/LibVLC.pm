package Alien::VideoLAN::LibVLC;

use warnings;
use strict;
use ExtUtils::PkgConfig;

=head1 NAME

Alien::VideoLAN::LibVLC - Find installed libvlc.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

sub _find {
	my $self = shift;
	my $lib = shift;
	my %a = @_;

	my $version = $a{version};
	$version = '' unless defined $version;
	my %p;

	if ($a{suppress_error_message}) {
		my $str;
		open my $fh, '>', \$str;
		local *STDERR = $fh;
		%p = ExtUtils::PkgConfig->find("$lib $version");
	} else {
		%p = ExtUtils::PkgConfig->find("$lib $version");
	}

	my @cflags = grep { $_ ne '' } split /\s/, $p{cflags};
	$p{cflags} = \@cflags;
	my @ldflags = grep { $_ ne '' } split /\s/, $p{libs};
	delete $p{libs};
	$p{ldflags} = \@ldflags;
	$p{version} = $p{modversion};
	delete $p{modversion};
	return %p;
}

=head1 SYNOPSIS

    use Alien::VideoLAN::LibVLC;
    my %x = Alien::VideoLAN::LibVLC->find_libvlc();
    print $x{version};

    my %y = Alien::VideoLAN::LibVLC->find_libvlc(version => '>= 1.1.9');

=head1 METHODS

=head2 C<find_libvlc>

    Alien::VideoLAN::LibVLC->find_libvlc();
    Alien::VideoLAN::LibVLC->find_libvlc(version => '>= 1.1.9');
    Alien::VideoLAN::LibVLC->find_libvlc(version => '= 1.1.10',
                                         suppress_error_message => 1);

Finds installed libvlc.

If C<version> parameter is specified, required version is needed.
Check documentation of C<pkg-config> for format of version.

If C<suppress_error_message> parameter is specified and is true,
nothing will be put to STDERR if libvlc is not found.

Returns hash with following fields:

=over 4

=item * B<version>

a string with version.

=item * B<cflags>

arrayref of strings, e.g. C<['-I/foo/bar']>

=item * B<ldflags>

arrayref of strings, e.g. C<['-L/foo/baz', '-lvlc']>

=back

If libvlc of specified version isn't found, croaks.

=cut

sub find_libvlc {
	my $self = shift;
	my %a = @_;
	return $self->_find('libvlc', %a);
}

=head1 AUTHOR

Alexey Sokolov, C<< <alexey at alexeysokolov.co.cc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-videolan-libvlc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-VideoLAN-LibVLC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::VideoLAN::LibVLC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-VideoLAN-LibVLC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-VideoLAN-LibVLC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-VideoLAN-LibVLC>

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-VideoLAN-LibVLC/>

=back


=head1 SEE ALSO

L<http://www.videolan.org/vlc/>

L<http://www.videolan.org/vlc/libvlc.html>

L<Alien>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alexey Sokolov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Alien::VideoLAN::LibVLC
