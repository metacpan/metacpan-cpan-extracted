#! perl

package App::PDF::Overlay;

use warnings;
use strict;

=head1 NAME

pdfolay - insert a PDF document over/under another document

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

pdfolay [options] [file ...]

 Options:
   --output=XXX		output document (default "__new__.pdf")
   --overlay=XXX	name of the overlay PDF document
   --back		overlay behind the source document
   --behind		same as --back
   --restart		restart the overlay at every source
   --repeat		cycle overlay pages if source hase more pages
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

=head1 OPTIONS

=over 8

=item B<--output=>I<XXX>

Name of the resultant PDF document.

Default is C<__new__.pdf>.

=item B<--overlay=>I<XXX>

Name of the PDF document to overlay.

=item B<--back>

Insert the overlay document I<behind> the source documents.

=item B<--repeat>

Repeat (cycle through) the pages of the overlay document when the
source document has more pages than the overlay.

Default is to stop overlaying when the pages of the overlay document
are exhausted.

=item B<--restart>

Restart overlaying with the first page of the overlay document when a
new source document is processed.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.
This option may be repeated to increase verbosity.

=item B<--quiet>

Suppresses all non-essential information.

=item I<file>

The input PDF documents.

=back

=head1 DESCRIPTION

B<This program> will read the given input PDF file(s) and copy them
into a new output document.

Optionally, an overlay PDF document can be specified. If so, the pages
of the overlay document are inserted over (or, with option
B<--behind>, behind) the pages of the source documents.

When the source documents have more pages than the overlay document,
there are a couple of ways to reuse the overlay pages. These can be
controlled with the options B<--restart> and B<--repeat>.

Assuming the source documents have pages A B C and D E F, and the
overlay document has pages X Y, then the combinations are:

    default:        AX BY C   D  E  F
    repeat:         AX BY CX  DY EX FY
    restart:        AX BY C   DX EY F
    repeat+restart: AX BY CX  DX EY FX

=head1 AUTHOR

Johan Vromans, C<< <JV at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-App-PDF-Overlay.

You can find documentation for this module with the perldoc command.

    perldoc App::PDF::Overlay

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2022 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::PDF::Overlay
