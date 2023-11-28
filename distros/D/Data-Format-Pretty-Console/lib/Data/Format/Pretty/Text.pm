package Data::Format::Pretty::Text;

use 5.010;
use strict;
use warnings;

use Data::Format::Pretty::Console ();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-07'; # DATE
our $DIST = 'Data-Format-Pretty-Console'; # DIST
our $VERSION = '0.392'; # VERSION

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

This document describes version 0.392 of Data::Format::Pretty::Text (from Perl distribution Data-Format-Pretty-Console), released on 2023-08-07.

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

=head1 SEE ALSO

L<Data::Format::Pretty::Console>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2017, 2016, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-Console>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
