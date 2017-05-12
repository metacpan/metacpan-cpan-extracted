#! /usr/bin/perl -w
# --*-Perl-*--
# $Id: PBibTk.pl 23 2005-07-17 19:28:02Z tandler $

=head1 NAME

PBibTk.pl - GUI for PBib, a tool for managing and processing bibliographic data

=head1 SYNOPSIS

	PBibTk.pl
	PBibTk.pl I<filename> # will open the file

=head1 DESCRIPTION

I wrote PBib to have something like BibTex for MS Word that can use a various sources for bibliographic references, not just BibTeX files, but also database systems.

PBibTk is a simple GUI written with Perl's Tk package.

=head2 Features

=over

=item *

B<Browse references> both in database and those cited in the current document side-by-side. Get quickly an idea, how many and which references you are using plus how often each reference is cited.

=item * 

B<Quick search> for authors and keywords. Searches are remembered and can be quickly accessed (or re-executed) later.

=item *

Easy B<copy-and-paste of references> into the document using the system clipboard and your favourite editor (including MS Word and OpenOffice).

=item *

B<Jump> to the place a reference is cited in the current document. (I think this only works with MS Word at the moment.) For most document types, you will be able to quickly B<open the current document> for editing.

=item *

Start F<PBib>, i.e. B<process the current input document> to create one with formatted citations and list of references.

=item *

B<Import and export> of references to the bibliographic database in various text-based formats. (Not all database types support import yet.)

=item *

B<Quick-export> of a single reference in various text-based formats (such as BibTeX, HTML, Endnote, Refer/Tib) and B<quick-import> from the L<Reference dialog|PBibTk::ReferenceDialog>.

=back

=cut


use strict;
use FindBin;
use lib "$FindBin::Bin/../lib", '$FindBin::Bin/../lib/Biblio/bp/lib';
use PBibTk::LitRefs;
use PBibTk::Main;

my $litrefs = new PBibTk::LitRefs();
$litrefs->processArgs();

my $ui = new PBibTk::Main($litrefs);
$ui->main();

__END__

=head1 AUTHOR

Peter Tandler <pbib@tandlers.de>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002-2004 P. Tandler

For copyright information please refer to the LICENSE file included in this distribution.

=head1 SEE ALSO

Modules: L<PBibTk::Main>, L<PBib::PBib>

Scripts: F<pbib.pl>, F<pbib-export.pl>, F<pbib-import.pl>

URL: L<http://tandlers.de/peter/pbib/>
