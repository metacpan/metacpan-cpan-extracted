package Alien::Plotly::Orca;

# ABSTRACT: Finds or installs plotly-orca

use strict;
use warnings;

our $VERSION = '0.0001'; # VERSION

use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Plotly::Orca - Finds or installs plotly-orca

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Alien::Plotly::Orca;
    use Config;

    if (Alien::Plotly::Orca->install_type eq 'share') {
        $ENV{PATH} = join(
            $Config{path_sep},
            Alien::Plotly::Orca->bin_dir,
            $ENV{PATH}
        );

        # get version
        my $version = Alien::Plotly::Orca->version;
    }

    # If install_type is not 'share' then it means plotly-orca
    # was detected from PATH when Alien::Plotly::Orca was installed.
    # So in either case now you should be able to do,
    print `orca -h`;

=head1 DESCRIPTION

This module finds L<plotly-orca|https://github.com/plotly/orca> from your
system, or installs it (version 1.2.1).

For installation it uses prebuilt packages and would supports 3 OS
platforms: Windows, Linux and OSX.
For Windows and OSX it would get package from
L<Anaconda's plotly repo|https://anaconda.org/plotly/plotly-orca/files>.
For Linux it would get the AppImage file from
L<plotly-orca's github release page|https://github.com/plotly/orca/releases>.

=head1 INSTALLATION

=head2 Linux

Normally you should be all fine if you have a recent version of popular
distros like Ubuntu as your Linux desktop. If you're an advanced Linux user
or if you get problems check below list and make sure you have them all on
you Linux host.

=over 4

=item *

FUSE

to run AppImage, as we use AppImage for Linux. See also
L<https://github.com/AppImage/AppImageKit/wiki/FUSE>.

=item *

A running X service

plotly-orca requires X service. If your host is headless you
mostly need L<xvfb|https://en.wikipedia.org/wiki/Xvfb>, either ran as a
service, or ran as a wrapper every time like C<xvfb-run orca ...>.

=item *

"open sans" font

Not having this font would cause installation to fail, but texts could be
not properly rendered in the exported image file. See also
L<https://github.com/plotly/orca/issues/148>.

=back

=head2 Windows

On Windows do not have your Perl installation itself in a long path. This
is because that in the plotly-orca's tar.bz2 archive there are some files
with quite long paths, and if your Perl itself is in a long path, during
some intermediate step of installing this library there would need very
long paths for some extractd files which could exceed Windows's default
MAX_PATH limit of 260 characters.
And Archive::Tar cannot handle that properly.

=head2 Max OSX

For Mac OSX I can't really test it as I don't have such a system at
hand. Travis CI does not seem to support Perl for OSX...

=head1 SEE ALSO

L<Alien>, 
L<Chart::Plotly>

L<https://github.com/plotly/orca>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
