package Data::Format::Pretty::PHPSerialization;

use 5.010001;
use strict;
use warnings;

use PHP::Serialization qw(serialize);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(format_pretty);

our $VERSION = '0.03'; # VERSION

sub content_type { "application/vnd.php.serialized" }

sub format_pretty {
    my ($data, $opts) = @_;
    $opts //= {};
    serialize($data);
}

1;
# ABSTRACT: Pretty-print data structure as PHP serialization format

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Format::Pretty::PHPSerialization - Pretty-print data structure as PHP serialization format

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Data::Format::Pretty::PHPSerialization qw(format_pretty);
 print format_pretty($data);

Some example output:

=over 4

=item * format_pretty({a=>1, b=>2})

 a:2:{s:1:"a";i:1;s:1:"b";i:2;}

=back

=head1 DESCRIPTION

This module uses L<PHP::Serialization> to encode data as PHP serialization
format, which I frankly wouldn't call as a "pretty" format, but added for
completeness sake (used by e.g. L<Perinci::Access::HTTP::Server>).

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts)

Return formatted data structure as PHP serialization format. Currently there are
no known options.

=head1 SEE ALSO

L<Data::Format::Pretty>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Format-Pretty-PHPSerialization>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Data-Format-Pretty-PHPSerialization>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Format-Pretty-PHPSerialization>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
