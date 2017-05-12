package Alien::RRDtool;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.06';

use File::ShareDir qw(dist_dir);;
use File::Spec;

use constant prefix => dist_dir('Alien-RRDtool');

sub include {
    return File::Spec->catfile(prefix, 'include');
}

sub lib {
    return File::Spec->catfile(prefix, 'lib');
}

sub share {
    return File::Spec->catfile(prefix, 'share');
}

1;
__END__

=head1 NAME

Alien::RRDtool - Installation of Perl bindings to RRDtool

=head1 VERSION

This document describes Alien::RRDtool version 0.06.

=head1 SYNOPSIS

    use RRDs; # see RRDtool documentation

=head1 DESCRIPTION

This distribution installs F<RRDs.pm> on perls.
The RRDtool package will install RRDs.pm to the system perl, but there're cases
we need to install it to perls installded by ourselves.

NOTES: This distribution doesn't install rrdtool itself yet, as
other Alien::* dists do, but it does so in a future.

=head1 INSTALL

First, you must install the following C libraries which RRDtool depends on:

    pkg-config
    gettext
    glib
    xml2
    pango
    cairo
    XQuartz (for MacOSX)

Some of them might be installed by default.

Second, you can install this distribution by C<cpanm>:

    cpanm Alien::RRDtool

Then, you can use the C<RRDs> module.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

RRDtool depends on pkg-config, gettext, glib, xml2, pango and  cairo.
You shuould install those libraries by yourself with a package manager.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<http://oss.oetiker.ch/rrdtool/>

L<RRDs>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji(at)cpan.orgE<gt>;

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
