package Crypt::Bear::PEM::Decoder;
$Crypt::Bear::PEM::Decoder::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Bear;

1;

# ABSTRACT: A decoder for PEM

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::PEM::Decoder - A decoder for PEM

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $decoder = Crypt::Bear::PEM::Decoder->new(sub {
     my ($banner, $payload) = @_;
	 push @certs, $payload if $banner =~ /CERTIFICATE/;
 });

 while(<>) {
     $decoder->push($_);
 }

 die "PEM file was truncated" if $decoder->entry_in_progress;

=head1 DESCRIPTION

This implements a streaming PEM decoder. In most cases you'll want the non-streaming C<pem_decode> function in L<Crypt::Bear::PEM>.

=head1 METHODS

=head2 new($callback)

This creates a new decoder, and sets a callback that will be called whenever an entry has completed.

=head2 push($data)

This pushes data to the decoder, potentially causing the callback to be called.

=head2 entry_in_progress()

This returns true if the decoder is half-way decoding an entry. This should be false at the end of a PEM stream.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
