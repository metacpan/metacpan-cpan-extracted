package Color::Calc::WWW;

use strict;
use utf8;
use warnings;
use Carp;

use Exporter;

use Color::Calc(
  'OutputFormat' => 'html',
  'ColorScheme' => 'WWW'
);

our $VERSION = "1.073";
$VERSION = eval $VERSION;

our @ISA = qw(Exporter);
our @EXPORT = ('color', map { 'color_'.$_ } @Color::Calc::__subs);

1;
__END__

=head1 NAME

Color::Calc::WWW - Simple calculations with colors for the WWW.

=head1 SYNOPSIS

  use Color::Calc::WWW;
  my $background = 'green';
  print 'background: ', color($background),';';
  print 'border-top: solid 1px ', color_light($background),';';
  print 'border-bottom: solid 1px ', color_dark($background),';';
  print 'color: ', color_contrast_bw($background),';';

=head1 DESCRIPTION

The C<Color::Calc::WWW> module implements simple calculations with RGB colors
for the World Wide Web. This can be used to create a full color scheme from a
few colors.

This module is nearly identical to using the following:

  use Color::Calc('ColorScheme' => 'WWW', 'OutputFormat' => 'html');

However, this module also makes the functions available when not imported:

  use Color::Calc::WWW();		# don't import
  Color::Calc::WWW::color('F00');

=head1 USAGE

By default, all functions are imported.

All functions recognize all HTML color keywords (through
L<Graphics::ColorNames::WWW>) and output the results in WWW-compatible formats,
i.e. as one of the 16 basic HTML keywords (see L<Graphics::ColorNames::WWW>) or
as #RRGGBB.

=over

=item color, color_mix, ...

  See L<Color::Calc> for a list of available calculation functions.

=back

=head1 NOTE

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

=head1 LICENSE

Copyright 2004-2010 Claus FE<auml>rber.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
