package Acme::KemonoFriends::Color;
use 5.008001;
use strict;
use warnings;
use utf8;
use Encode qw( encode );
use Exporter 'import';
our @EXPORT = qw( printk );
our $VERSION = "0.01";

my @KemonoFriends_color = qw(
    35   112  208  202
    36   198   39   32
    248  253  196  190
    126  207
);

sub printk {
    my $message = shift;
    my @strings = split('',$message);
    print encode('utf-8', _escaped_message($_)) for @strings;
}

sub _get_color_code {
    my $code = $KemonoFriends_color[int( rand($#KemonoFriends_color) )];

    return '1;38;5;'.$code;
}

sub _escaped_message {
    my $message = shift;

    my $begin = "\e[" . _get_color_code() . "m";
    my $end   = "\e[m";
    return  $begin . $message . $end;
}

1;
__END__

=encoding utf-8

=for stopwords ja

=head1 NAME

Acme::KemonoFriends::Color - Colorfull output.

=head1 SYNOPSIS

    use Acme::KemonoFriends::Color;
    use utf8;

    # It is randomly displayed in the color of Kemono Friends.
    printk('Welcome to ようこそジャパリパーク!');

=head1 DESCRIPTION

Kemono Friends is one of the most famous Japanese TV animation. Acme::KemonoFriends::Color provides colorfull output like Kemono Friends.

Please use a terminal compatible with 256 colors

=head1 LICENSE

Copyright (C) yukinea.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yukinea E<lt>yuki.931322@gmail.comE<gt>

=cut

