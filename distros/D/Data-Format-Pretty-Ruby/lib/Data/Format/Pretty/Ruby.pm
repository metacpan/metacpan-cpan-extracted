package Data::Format::Pretty::Ruby;

use 5.010001;
use strict;
use warnings;

use Data::Dump::Ruby qw(dump_ruby);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

our $VERSION = '0.02'; # VERSION

sub format_pretty {
    my ($data, $opts) = @_;
    $opts //= {};
    dump_ruby($data);
}

1;
# ABSTRACT: Pretty-print data structure as Ruby code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Format::Pretty::Ruby - Pretty-print data structure as Ruby code

=head1 VERSION

This document describes version 0.02 of Data::Format::Pretty::Ruby (from Perl distribution Data-Format-Pretty-Ruby), released on 2015-02-11.

=head1 SYNOPSIS

 use Data::Format::Pretty::Ruby qw(format_pretty);
 print format_pretty($data);

Some example output:

=over 4

=item * format_pretty({a=>1, b=>2})

 { "a" => 1, "b" => 2 }

=back

=head1 DESCRIPTION

This module uses L<Data::Dump::Ruby> to encode data as Ruby code.

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts)

Return formatted data structure. Currently there are no known formatting
options.

=head1 SEE ALSO

L<Data::Format::Pretty>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Format-Pretty-Ruby>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Format-Pretty-Ruby>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-Ruby>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
