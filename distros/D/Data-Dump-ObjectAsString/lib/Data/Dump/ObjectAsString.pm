## no critic: (Modules::ProhibitAutomaticExportation

package Data::Dump::ObjectAsString;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-04'; # DATE
our $DIST = 'Data-Dump-ObjectAsString'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'vars', 'subs';
use Exporter qw(import);
our @EXPORT = qw(dd ddx);
our @EXPORT_OK = qw(dump pp quote);

use Data::Dump::Options ();

sub dump {
    local $Data::Dump::Options::OBJECT_AS = 'string';
    Data::Dump::Options::dump(@_);
}

*pp = \&dump;

*quote = \&Data::Dump::Options::quote;

sub dd {
    print &dump(@_), "\n";
}

sub ddx {
    my(undef, $file, $line) = caller;
    $file =~ s,.*[\\/],,;
    my $out = "$file:$line: " . &dump(@_) . "\n";
    $out =~ s/^/# /gm;
    print $out;
}

1;
# ABSTRACT: Like Data::Dump but objects are stringified instead of dumped

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::ObjectAsString - Like Data::Dump but objects are stringified instead of dumped

=head1 VERSION

This document describes version 0.001 of Data::Dump::ObjectAsString (from Perl distribution Data-Dump-ObjectAsString), released on 2020-06-04.

=head1 SYNOPSIS

Use like you would use L<Data::Dump>:

 use Data::Dump::ObjectAsString;
 dd [1,2,3,4];

=head1 DESCRIPTION

This is actually a thin wrapper of L<Data::Dump::Options>. When dumping,
C<$Data::Dump::Options::OBJECT_AS> is locally set to C<string>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-ObjectAsString>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-ObjectAsString>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-ObjectAsString>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Dump::Options>

L<Data::Dump>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
