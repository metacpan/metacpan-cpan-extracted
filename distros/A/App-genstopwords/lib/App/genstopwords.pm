package App::genstopwords;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

=head1 NAME

App::genstopwords - Generate a .stopwords file for POD spell-checking

=head1 VERSION

Version v0.0.1

=head1 SYNOPSIS

    gen-stopwords [OPTIONS]

    # Basic usage (scans current directory, writes .stopwords)
    gen-stopwords

    # Specify language and output file
    gen-stopwords --lang en_US --output t/.stopwords

    # Scan specific directories
    gen-stopwords --dir lib --dir bin --dir t

    # Preview without writing
    gen-stopwords --dry-run --verbose

    # Show this help
    gen-stopwords --help

=head1 DESCRIPTION

Scans Perl source files (F<.pm>, F<.pl>, F<.pod>, F<.t>) and uses B<aspell>
to identify words that are not in the standard dictionary.  Those words are
collected into a F<.stopwords> file that your spelling test (e.g.
C<Test::Spelling>) can use to suppress false positives.

The generator:

=over 4

=item * Strips POD formatting codes (C<E<gt>>, C<L<...>>, C<C<...>>, etc.)
before passing lines to aspell, preventing artefacts like C<Egt>.

=item * Uses C<--run-together> so compound identifiers such as C<ResultSet>
and C<PendingChange> are handled correctly.

=item * Optionally seeds the list from your personal aspell wordlist
(F<~/.aspell.en.pws>) so project-specific words already known to you are
included automatically.

=item * Skips build/vendor directories (F<.git>, F<blib>, F<local>, etc.)
to keep the output clean.

=back

=head1 OPTIONS

=over 4

=item B<-l>, B<--lang> I<LANG>

Aspell language code to use.  Defaults to C<en_GB>.

=item B<-o>, B<--output> I<FILE>

Path of the stopwords file to write.  Defaults to C<.stopwords> in the
current directory.

=item B<-p>, B<--pws> I<FILE>

Path to your personal aspell wordlist.  Defaults to
F<~/.aspell.en.pws>.  Use C<--no-global> to skip this entirely.

=item B<-d>, B<--dir> I<DIR>

Directory to scan.  May be specified multiple times.  Defaults to C<.>
(current directory).

=item B<-m>, B<--min-len> I<N>

Minimum word length to include.  Defaults to C<2>.

=item B<-v>, B<--verbose>

Print the name of every file processed and extra detail.

=item B<-q>, B<--quiet>

Suppress all non-error output.

=item B<-n>, B<--dry-run>

Show what would be written without actually creating or modifying the
output file.

=item B<--no-global>

Do not load words from the personal aspell wordlist.

=item B<-V>, B<--version>

Print the version and exit.

=item B<-h>, B<--help>

Print this help message and exit.

=back

=head1 REQUIREMENTS

=over 4

=item * Perl 5.10+

=item * B<aspell> must be installed and on C<$PATH>.

=back

=head1 EXIT STATUS

Exits C<0> on success, C<1> on usage error, and dies with a descriptive
message on fatal errors (missing aspell, unwritable output, etc.).

=head1 WORKFLOW

    # 1. Generate (or regenerate after editing source files)
    gen-stopwords

    # 2. Run your spelling test
    AUTHOR_TESTING=1 perl spelling.t

Your spelling test should warn you when source files are newer than
F<.stopwords>, prompting you to re-run this script.

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-genstopwords>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/App-genstopwords/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::genstopwords

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/App-genstopwords/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-genstopwords>

=item * Search MetaCPAN

L<https://metacpan.org/dist/App-genstopwords/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of App::genstopwords
