package Config::IOD::INI;

use 5.010001;
use strict;
use warnings;

use parent qw(Config::IOD);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-02'; # DATE
our $DIST = 'Config-IOD'; # DIST
our $VERSION = '0.353'; # VERSION

sub new {
    my ($class, %attrs) = @_;
    $attrs{enable_directive} //= 0;
    $attrs{enable_encoding}  //= 0;
    $attrs{enable_quoting}   //= 0;
    $attrs{enable_bracket}   //= 0;
    $attrs{enable_brace}     //= 0;
    $attrs{enable_tilde}     //= 0;
    $class->SUPER::new(%attrs);
}

1;
# ABSTRACT: Read and write INI configuration files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::IOD::INI - Read and write INI configuration files

=head1 VERSION

This document describes version 0.353 of Config::IOD::INI (from Perl distribution Config-IOD), released on 2022-05-02.

=head1 SYNOPSIS

 use Config::IOD::INI;
 my $iod = Config::IOD->new();

Read INI document from a file or string, return L<Config::IOD::Document> object:

 my $doc = $iod->read_file("/path/to/some.ini");
 my $doc = $iod->read_string("...");

See Config::IOD::Document for methods available for C<$doc>.

=head1 DESCRIPTION

This module is just a L<Config::IOD> subclass. It uses the following defaults to
make the reader's behavior closer to a typical "regular INI files parser".

    enable_directive = 0
    enable_encoding  = 0
    enable_quoting   = 0
    enable_bracket   = 0
    enable_brace     = 0
    enable_tilde     = 0

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD>.

=head1 SEE ALSO

L<Config::IOD>

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

This software is copyright (c) 2022, 2021, 2019, 2017, 2016, 2015, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
