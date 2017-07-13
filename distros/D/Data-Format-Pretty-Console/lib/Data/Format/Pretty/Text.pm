package Data::Format::Pretty::Text;

use 5.010;
use strict;
use warnings;

use Data::Format::Pretty::Console ();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

our $VERSION = '0.38'; # VERSION

sub content_type { "text/plain" }

sub format_pretty {
    my ($data, $opts) = @_;
    my %opts = $opts ? %$opts : ();
    $opts{interactive} = 1;
    Data::Format::Pretty::Console::format_pretty($data, \%opts);
}

1;
# ABSTRACT: Pretty-print data structure as text

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Format::Pretty::Text - Pretty-print data structure as text

=head1 VERSION

This document describes version 0.38 of Data::Format::Pretty::Text (from Perl distribution Data-Format-Pretty-Console), released on 2017-07-10.

=head1 SYNOPSIS

In your program:

 use Data::Format::Pretty::Text qw(format_pretty);
 print format_pretty($data);

Some example output:

=over 4

=item * format_pretty([qw/foo bar baz qux/])

 +------+
 | foo  |
 | bar  |
 | baz  |
 | qux  |
 '------'

=back

=head1 DESCRIPTION

This module just calls L<Data::Format::Pretty::Console::format_pretty> with
C<interactive>=1 option.

=for Pod::Coverage ^(content_type)$

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts)

Return formatted data structure. See L<Data::Format::Pretty::Console> for
details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Format-Pretty-Console>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Format-Pretty-Console>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-Console>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Format::Pretty::Console>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
