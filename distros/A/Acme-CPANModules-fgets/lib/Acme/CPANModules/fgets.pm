package Acme::CPANModules::fgets;

our $DATE = '2018-02-05'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "fgets() implementations in Perl",
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
# ABSTRACT: fgets() implementations in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::fgets - fgets() implementations in Perl

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::fgets (from Perl distribution Acme-CPANModules-fgets), released on 2018-02-05.

=head1 DESCRIPTION

fgets() implementations in Perl.

Reading a line of data from a filehandle in Perl is easy, but Perl will happily
slurp line of any length without limit, even gigabytes which can cause your
script or system to run out of memory.

C<fgets()> is a standard I/O C function to get a line of data with a length
limit. In many cases you don't need in this Perl but in some cases you do. The
lack of built-in C<fgets()> function in Perl (unlike in, say, PHP) is a bit
annoying, but no worries because there are several CPAN modules that provide you
with just that.

=head1 INCLUDED MODULES

=over

=item * L<PerlIO::fgets>

Can handle piped command fine, but doesn't work well in non-blocking mode.


=item * L<File::fgets>

XS module. Seems to have trouble dealing with piped command. But works well in
low-throughput situation as well as in non-blocking mode.


=item * L<File::GetLineMaxLength>

Pure-Perl module. Different interface (use an OO wrapper) so a bit more
cumbersome to use. Uses a fixed 4096-byte block size so doesn't work well in
low-throughput situation. Doesn't work well in non-blocking mode.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-fgets>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-fgets>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-fgets>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
