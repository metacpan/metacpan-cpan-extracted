package Acme::CPANModules::fgets;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-fgets'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => "List of fgets() implementations in Perl",
    description => <<'_',

Reading a line of data from a filehandle in Perl is easy, but Perl will happily
slurp line of any length without limit, even gigabytes which can cause your
script or system to run out of memory.

`fgets()` is a standard I/O C function to get a line of data with a length
limit. In many cases you don't need in this Perl but in some cases you do. The
lack of built-in `fgets()` function in Perl (unlike in, say, PHP) is a bit
annoying, but no worries because there are several CPAN modules that provide you
with just that.

_
    entries => [
        {
            module => 'PerlIO::fgets',
            description => <<'_',

Can handle piped command fine, but doesn't work well in non-blocking mode.

_
        },
        {
            module => 'File::fgets',
            description => <<'_',

XS module. Seems to have trouble dealing with piped command. But works well in
low-throughput situation as well as in non-blocking mode.

_
        },
        {
            module => 'File::GetLineMaxLength',
            description => <<'_',

Pure-Perl module. Different interface (use an OO wrapper) so a bit more
cumbersome to use. Uses a fixed 4096-byte block size so doesn't work well in
low-throughput situation. Doesn't work well in non-blocking mode.

_
        },
    ],
};

1;
# ABSTRACT: List of fgets() implementations in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::fgets - List of fgets() implementations in Perl

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::fgets (from Perl distribution Acme-CPANModules-fgets), released on 2022-03-18.

=head1 DESCRIPTION

Reading a line of data from a filehandle in Perl is easy, but Perl will happily
slurp line of any length without limit, even gigabytes which can cause your
script or system to run out of memory.

C<fgets()> is a standard I/O C function to get a line of data with a length
limit. In many cases you don't need in this Perl but in some cases you do. The
lack of built-in C<fgets()> function in Perl (unlike in, say, PHP) is a bit
annoying, but no worries because there are several CPAN modules that provide you
with just that.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<PerlIO::fgets> - Provides a C<fgets()> like function for PerlIO file handles

Author: L<CHANSEN|https://metacpan.org/author/CHANSEN>

Can handle piped command fine, but doesn't work well in non-blocking mode.


=item * L<File::fgets> - Read either one line or X characters from a file

Author: L<MSCHWERN|https://metacpan.org/author/MSCHWERN>

XS module. Seems to have trouble dealing with piped command. But works well in
low-throughput situation as well as in non-blocking mode.


=item * L<File::GetLineMaxLength> - Get lines from a file, up to a maximum line length

Author: L<ROBM|https://metacpan.org/author/ROBM>

Pure-Perl module. Different interface (use an OO wrapper) so a bit more
cumbersome to use. Uses a fixed 4096-byte block size so doesn't work well in
low-throughput situation. Doesn't work well in non-blocking mode.


=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n fgets

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries fgets | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=fgets -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::fgets -E'say $_->{module} for @{ $Acme::CPANModules::fgets::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-fgets>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-fgets>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-fgets>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
