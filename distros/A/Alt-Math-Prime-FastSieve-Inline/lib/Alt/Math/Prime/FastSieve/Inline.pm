use 5.008001; use strict; use warnings;
package Alt::Math::Prime::FastSieve::Inline;
our $VERSION = '0.09';

=head1 NAME

Alt::Math::Prime::FastSieve::Inline - Alternate Math::Prime::FastSieve using Inline::Module

=head1 SYNOPSIS

    > cpanm Alt::Math::Prime::FastSieve::Inline

    use Math::Prime::FastSieve;

=head1 DESCRIPTION

This is an alternate version of Math::Prime::FastSieve that is made with
Inline::Module and Inline::CPP. It is the first Inline::CPP module to be done
this way.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
