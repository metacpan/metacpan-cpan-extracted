package Crypt::Bear::PEM;
$Crypt::Bear::PEM::VERSION = '0.003';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/pem_encode pem_decode/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Crypt::Bear;

1;

# ABSTRACT: A decoder for PEM

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::PEM - A decoder for PEM

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Crypt::Bear::PEM 'pem_decode', 'pem_encode';

 my @raw_certs;
 my @input = pem_decode($input);
 while (my ($banner, $payload) = splice @input, 0, 2) {
     push @raw_certs, $payload if $banner =~ /CERTIFICATE/;
 }

 for my $raw_cert (@raw_certs) {
     print $out pem_encode('CERTIFICATE', $raw_cert);
 }

=head1 DESCRIPTION

This class contains two functions C<pem_decode> to decode PEM, and C<pem_encode> to encode PEM. Both are optionally exported.

=head1 FUNCTIONS

=head2 pem_decode($data)

This will decode the data, and return it as C<$banner, $payload> pairs.

If you need to decode asynchronously, see L<Crypt::Bear::PEM::Decoder|Crypt::Bear::PEM::Decoder>.

=head2 pem_encode($banner, $data, @flags)

This PEM encodes some piece of C<$data> with the given C<$banner>. If flags are given they will affect the output. Valid values are:

=over 4

=item * 'line64'

If set, line-breaking will occur after every 64 characters of output, instead of the default of 76

=item * 'crlf'

If set, end-of-line sequence will use CR+LF instead of a single LF.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
