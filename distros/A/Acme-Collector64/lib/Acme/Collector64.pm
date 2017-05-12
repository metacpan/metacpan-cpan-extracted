package Acme::Collector64;
use strict;
use warnings;
use 5.008001;
use Carp ();

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $index_table = $args{index_table}
        || join '', ('A'..'Z', 'a'..'z', '0'..'9', '+/=');

    unless (length $index_table == 65) {
        Carp::croak('index_table must be 65-character string.');
    }

    return bless {
        index_table => $index_table,
    }, $class;
}

sub encode {
    my ($self, $input) = @_;

    my $output = '';
    my $i = 0;
    while ($i < length $input) {
        my ($chr1, $chr2, $chr3);
        for my $chr ($chr1, $chr2, $chr3) {
            $chr = $i < length $input ? ord substr($input, $i++, 1) : 0;
        }
        my $enc1 = $chr1 >> 2;
        my $enc2 = (($chr1 & 3) << 4) | ($chr2 >> 4);
        my $enc3 = (($chr2 & 15) << 2) | ($chr3 >> 6);
        my $enc4 = $chr3 & 63;
        if (!$chr2) {
            $enc3 = $enc4 = 64;
        } elsif (!$chr3) {
            $enc4 = 64;
        }
        for my $enc ($enc1, $enc2, $enc3, $enc4) {
            $output .= substr $self->{index_table}, $enc, 1;
        }
    }
    return $output;
}

sub decode {
    my ($self, $input) = @_;

    my $output = '';
    my $i = 0;
    while ($i < length $input) {
        my ($enc1, $enc2, $enc3, $enc4);
        for my $enc ($enc1, $enc2, $enc3, $enc4) {
            $enc = index $self->{index_table}, substr($input, $i++, 1);
        }
        my $chr1 = ($enc1 << 2) | ($enc2 >> 4);
        my $chr2 = (($enc2 & 15) << 4) | ($enc3 >> 2);
        my $chr3 = (($enc3 & 3) << 6) | $enc4;
        $output .= chr $chr1;
        if ($enc3 != 64) {
            $output .= chr $chr2;
        }
        if ($enc4 != 64) {
            $output .= chr $chr3;
        }
    }
    return $output;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Collector64 - Yet Another Base64?

=head1 SYNOPSIS

    use utf8;
    use Acme::Collector64;

    my $japanese64 = Acme::Collector64->new(
        index_table => 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもらりるれろがぎぐげござじずぜぞばびぶべぼぱぴぷぺぽやゆよわ=',
    );

    $japanese64->encode('Hello, world!');
    $japanese64->decode('てきにごふきやごけくほずへれぞりけち==');

=head1 DESCRIPTION

Let's make your own Base64!

=head1 METHODS

=over 4

=item my $c64 = Acme::Collector64->new([\%args])

Create new instance of Acme::Collector64.

=over 4

=item index_table

This is user definable index table. You have to define 65-character string.

index_table by default is "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".

=back

=item $c64->encode($data)

This function takes B<binary string> to encode and return the encoded string.

=item $c64->decode($string)

This function takes B<text string> to decode and return the decoded data.

=back

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym at gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
