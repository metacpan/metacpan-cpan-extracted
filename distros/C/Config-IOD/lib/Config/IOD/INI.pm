package Config::IOD::INI;

our $DATE = '2019-01-17'; # DATE
our $VERSION = '0.350'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Config::IOD);

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

This document describes version 0.350 of Config::IOD::INI (from Perl distribution Config-IOD), released on 2019-01-17.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Config::IOD>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
