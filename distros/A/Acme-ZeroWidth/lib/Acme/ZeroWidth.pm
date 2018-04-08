package Acme::ZeroWidth;
use 5.008001;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = "0.01";

our @EXPORT_OK = qw(to_zero_width from_zero_width);

sub to_zero_width {
    my ($visible) = @_;

    my $not_visible = join "\x{200d}",
      map { s/1/\x{200b}/g; s/0/\x{200c}/g; $_ }
      map { unpack 'B*', $_ } split //,
      $visible;

    return $not_visible;
}

sub from_zero_width {
    my ($not_visible) = @_;

    return join '', map { pack 'B*', $_ }
      map { s/\x{200b}/1/g; s/\x{200c}/0/g; $_ } split /\x{200d}/, $not_visible;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::ZeroWidth - Zero-width fingerprinting

=head1 SYNOPSIS

    use Acme::ZeroWidth qw(to_zero_width from_zero_width);

    to_zero_width('vti'); # becomes \x{200b}\x{200c}...

=head1 DESCRIPTION

Acme::ZeroWidth converts any data to zero-width equivalent characters.

=head1 LICENSE

Copyright (C) vti.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

vti E<lt>viacheslav.t@gmail.comE<gt>

=cut

