package Alien::TidyHTML5;

# ABSTRACT: Download and install HTML Tidy

use strict;
use warnings;

use base qw/ Alien::Base /;

our $VERSION = 'v0.1.1';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::TidyHTML5 - Download and install HTML Tidy

=head1 VERSION

version v0.1.1

=head1 DESCRIPTION

This distribution provides tidy (a.k.a. "libtidy" or "html-tidy")
v5.6.0 or newer, so that it can be used by other Perl
distributions. . It does this by first trying to detect an existing
install of tidy on your system. If found it will use that. If it
cannot be found, the source code will be downloaded from the official
git repository, and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<http://www.html-tidy.org/>

L<Alien::Build::Manual::AlienUser>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Alien-TidyHTML5>
and may be cloned from L<git://github.com/robrwo/Alien-TidyHTML5.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Alien-TidyHTML5/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
