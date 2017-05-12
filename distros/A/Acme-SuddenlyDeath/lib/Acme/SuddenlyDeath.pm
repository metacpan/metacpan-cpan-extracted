package Acme::SuddenlyDeath;
use strict;
use warnings;
use utf8;

use parent 'Exporter';
use Text::VisualWidth::UTF8;

our @EXPORT = qw/ sudden_death sudden_death_single /;

use version; our $VERSION = '0.09';

sub _generator {
    my $decoded_str = shift;
    my @decoded_lines = split /\n/, $decoded_str;

    my $max_length = 0;
    $max_length = $_ > $max_length ? $_ : $max_length
        for map {Text::VisualWidth::UTF8::width($_)} @decoded_lines;

    my $ascii = [];
    my $frame_length = ($max_length + 2) / 2;
    push @{$ascii}, '＿' . '人' x $frame_length . '＿';
    for my $line (@decoded_lines) {
        my $str_length = $max_length - Text::VisualWidth::UTF8::width($line);
        my ($left, $right) = map{' ' x $_} ($str_length / 2, $str_length / 2);

        $left = $str_length % 2 != 0 ? $left . ' ' : $left;
        push @{$ascii}, '＞ ' . $left . $line . $right . ' ＜';
    }
    push @{$ascii}, '￣' . '^Y' x ($frame_length - 1) . '^￣';

    return $ascii;
}

sub sudden_death {
    my $string = shift;

    my $ascii = _generator($string);
    return join "\n", @{$ascii};
}

sub sudden_death_single {
    my $string = shift;

    my $ascii = _generator($string);
    return join '', @{$ascii};
}

1;
__END__

=encoding utf8

=head1 NAME

Acme::SuddenlyDeath - ASCII Art of sudden death (突然の死) generator

=head1 SYNOPSIS

  use Acme::SuddenlyDeath;

  print sudden_death('突然の死')."\n"
  # outputs =>
  #   ＿人人人人人＿
  #   ＞ 突然の死 ＜
  #   ￣^Y^Y^Y^Y^￣
  print sudden_death("突然の\n死")."\n"
  # outputs =>
  #   ＿人人人人＿
  #   ＞ 突然の ＜
  #   ＞   死   ＜
  #   ￣^Y^Y^Y^￣
  print sudden_death_single('突然の死')."\n"
  # outputs =>
  #   ＿人人人人人＿＞ 突然の死 ＜￣^Y^Y^Y^Y^￣

=head1 DESCRIPTION

Acme::SuddenlyDeath generate the ASCII Art of sudden death from any strings.
If you would like to know about sudden death, please refer to the following web site (Japanese Web Site).

L<http://dic.nicovideo.jp/a/%E7%AA%81%E7%84%B6%E3%81%AE%E6%AD%BB>

=head1 METHODS

=over

=item sudden_death

This method needs a string as parameter.
It returns multiple line ASCII art of 'sudden death' which was generated from string.

=item sudden_death_single

This method needs a string as parameter.
It returns one line ASCII art of 'sudden death' which was generated from string.

=back

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=head1 DEPENDENCIES

Text::VisualWidth 0.02 or later.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
