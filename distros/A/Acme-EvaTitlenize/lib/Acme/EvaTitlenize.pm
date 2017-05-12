package Acme::EvaTitlenize;
use 5.008005;
use strict;
use warnings;
use utf8;

use Text::VisualWidth::UTF8;

our $VERSION = "0.01";

sub lower_left {
    my ($left, $low) = @_;

    my $evanize;

    $evanize .= join "\n", split //, $left;
    $evanize .= $low;

    return $evanize;
}

sub upper_right {
    my ($up, $right) = @_;

    my $space = ' ' x Text::VisualWidth::UTF8::width($up);
    my $evanize = $up;

    $evanize .= join "\n$space", split //, $right;

    return $evanize;
}

1;

__END__

=encoding utf-8

=head1 NAME

Acme::EvaTitlenize - Generate strings like title of Evangelion

=head1 SYNOPSIS

  print Acme::EvaTitlenize::lower_left(qw/奇跡の 価値は/);
  # output:
  #   奇
  #   跡
  #   の価値は

  print Acme::EvaTitlenize::upper_right(qw/奇跡の 価値は/);
  # output:
  #   奇跡の価
  #         値
  #         は
  

=head1 DESCRIPTION

Acme::EvaTitlenize generate strings like title of Evangelion.

=head1 LICENSE

Copyright (C) Yuuki Tan-nai.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuuki Tan-nai(@saisa6153) E<lt>yuki.tannai@gmail.comE<gt>

=cut

