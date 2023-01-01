package Color::Palette::Types 0.100004;
use strict;
use warnings;
# ABSTRACT: type constraints for use with Color::Palette

#pod =head1 BEAR WITH ME
#pod
#pod I'm not yet sure how best to document a type library.
#pod
#pod =head1 TYPES
#pod
#pod The following types are defined:
#pod
#pod   Color     - a Graphics::Color object
#pod   Palette   - a Color::Palette::Color object
#pod   ColorName - a valid color name: /\A[a-z][-a-z0-9]*\z/i
#pod
#pod   ColorDict - a hash mapping ColorName to Color
#pod   RecursiveColorDict - a hash mapping ColorName to (Color | ColorName)
#pod
#pod   HexColorStr - a string like #000 or #ababab
#pod   ArrayRGB    - an ArrayRef of three Bytes
#pod   Byte        - and Int from 0 to 255
#pod
#pod Colors can be coerced from ArrayRGB or HexColorStr, and dicts of colors try to
#pod coerce, too.
#pod
#pod =cut

use Graphics::Color::RGB;

use List::Util 1.33 qw(all);

use MooseX::Types -declare => [ qw(
  Color Palette
  ColorName
  ColorDict
  RecursiveColorDict
  HexColorStr
  ArrayRGB
  Byte
) ];

use MooseX::Types::Moose qw(Str Int ArrayRef HashRef);

class_type Color,   { class => 'Graphics::Color::RGB' };
class_type Palette, { class => 'Color::Palette' };

subtype ColorName, as Str, where { /\A[a-z][-a-z0-9]*\z/i };

subtype HexColorStr, as Str, where { /\A#?(?:[0-9a-f]{3}|[0-9a-f]{6})\z/i };

subtype Byte, as Int, where { $_ >= 0 and $_ <= 255 };

subtype ArrayRGB, as ArrayRef[Byte], where { @$_ == 3 };

coerce Color, from ArrayRGB, via {
  Graphics::Color::RGB->new({
    red   => $_->[0] / 255,
    green => $_->[1] / 255,
    blue  => $_->[2] / 255,
  })
};

coerce Color, from HexColorStr, via {
  my $copy = $_;
  $copy =~ s/\A#//;
  my $width = length $copy == 3 ? 2 : 1;

  my @rgb = $copy =~ /\A([0-9a-f]{1,2})([0-9a-f]{1,2})([0-9a-f]{1,2})\z/;
  Graphics::Color::RGB->new({
    red   => hex($rgb[0] x $width) / 255,
    green => hex($rgb[1] x $width) / 255,
    blue  => hex($rgb[2] x $width) / 255,
  });
};

subtype ColorDict, as HashRef[ Color ], where {
  all { is_ColorName($_) } keys %$_;
};

coerce ColorDict, from HashRef, via {
  my $input = $_;
  return { map {; $_ => to_Color($input->{$_}) } keys %$_ };
};

subtype RecursiveColorDict, as HashRef[ Color | ColorName ], where {
  all { is_ColorName($_) } keys %$_
};

coerce RecursiveColorDict, from HashRef, via {
  my $input = $_;
  my %output;
  for my $name (keys %$input) {
    my $val = $input->{ $name };
    $output{ $name } = $val, next unless ref $val or is_HexColorStr($val);
    $output{ $name } = to_Color($val);
  }

  return \%output
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::Palette::Types - type constraints for use with Color::Palette

=head1 VERSION

version 0.100004

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 BEAR WITH ME

I'm not yet sure how best to document a type library.

=head1 TYPES

The following types are defined:

  Color     - a Graphics::Color object
  Palette   - a Color::Palette::Color object
  ColorName - a valid color name: /\A[a-z][-a-z0-9]*\z/i

  ColorDict - a hash mapping ColorName to Color
  RecursiveColorDict - a hash mapping ColorName to (Color | ColorName)

  HexColorStr - a string like #000 or #ababab
  ArrayRGB    - an ArrayRef of three Bytes
  Byte        - and Int from 0 to 255

Colors can be coerced from ArrayRGB or HexColorStr, and dicts of colors try to
coerce, too.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
