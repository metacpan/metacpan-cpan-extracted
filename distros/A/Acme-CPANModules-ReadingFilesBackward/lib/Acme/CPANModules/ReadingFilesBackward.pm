package Acme::CPANModules::ReadingFilesBackward;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-01'; # DATE
our $DIST = 'Acme-CPANModules-ReadingFilesBackward'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => 'Reading files backward (in reverse)',
    description => <<'_',

Probably the fastest way, if you are on a Unix system, is to use the **tac**
command, which can read a file line by line in reverse order, or paragraph by
paragraph, or character by character, or word by word, or by a custom separator
string or regular expression. Example for using it from Perl:

    open my $fh, "tac /etc/passwd |";
    print while <$fh>;

Another convenient way is to use the Perl I/O layer <pm:PerlIO::reverse>. It
only does line-by-line reversing, but you can use the regular Perl API. You
don't even have to `use` the module explicitly (but of course you have to get it
installed first):

    open my $fh, "<:reverse", "/etc/passwd";
    print while <$fh>;

If your file is small (fits in your system's memory), you can also slurp the
file contents first into an array (either line by line, or paragraph by
paragraph, or what have you) and then simply `reverse` the array:

    open my $fh, "<", "/etc/passwd";
    my @lines = <$fh>;
    print for reverse @lines;

If the above solutions do not fit your needs, there are also these modules which
can help: <pm:File::ReadBackward>, <pm:File::Bidirectional>. File::ReadBackward
is slightly faster than File::Bidirectional, but File::Bidirectional can read
forward as well as backward. I now simply prefer PerlIO::reverse because I don't
have to use a custom API for reading files.

_
    'x.app.cpanmodules.show_entries' => 0,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Reading files backward (in reverse)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ReadingFilesBackward - Reading files backward (in reverse)

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::ReadingFilesBackward (from Perl distribution Acme-CPANModules-ReadingFilesBackward), released on 2020-03-01.

=head1 DESCRIPTION

Reading files backward (in reverse).

Probably the fastest way, if you are on a Unix system, is to use the B<tac>
command, which can read a file line by line in reverse order, or paragraph by
paragraph, or character by character, or word by word, or by a custom separator
string or regular expression. Example for using it from Perl:

 open my $fh, "tac /etc/passwd |";
 print while <$fh>;

Another convenient way is to use the Perl I/O layer L<PerlIO::reverse>. It
only does line-by-line reversing, but you can use the regular Perl API. You
don't even have to C<use> the module explicitly (but of course you have to get it
installed first):

 open my $fh, "<:reverse", "/etc/passwd";
 print while <$fh>;

If your file is small (fits in your system's memory), you can also slurp the
file contents first into an array (either line by line, or paragraph by
paragraph, or what have you) and then simply C<reverse> the array:

 open my $fh, "<", "/etc/passwd";
 my @lines = <$fh>;
 print for reverse @lines;

If the above solutions do not fit your needs, there are also these modules which
can help: L<File::ReadBackward>, L<File::Bidirectional>. File::ReadBackward
is slightly faster than File::Bidirectional, but File::Bidirectional can read
forward as well as backward. I now simply prefer PerlIO::reverse because I don't
have to use a custom API for reading files.

=head1 INCLUDED MODULES

=over

=item * L<PerlIO::reverse>

=item * L<File::ReadBackward>

=item * L<File::Bidirectional>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries ReadingFilesBackward | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ReadingFilesBackward -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ReadingFilesBackward>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ReadingFilesBackward>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ReadingFilesBackward>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::PickingRandomLinesFromFile>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
