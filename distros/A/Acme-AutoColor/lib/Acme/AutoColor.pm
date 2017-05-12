package Acme::AutoColor;

use 5.006;
use strict;
use warnings;

use Graphics::ColorNames 0.32;

our $VERSION = '0.03';

our $Colors;

sub import {
  my $class = shift;
  # TODO: parse version numbers
  $Colors = Graphics::ColorNames->new(@_);
}

package main;

use Carp qw( croak );
use Graphics::ColorNames qw( hex2tuple );

our $AUTOLOAD;

sub AUTOLOAD {
  my $class = shift;
  $AUTOLOAD =~ /.*::(\w+)/;

  my $cname = $1;

  if($cname eq "OCTARINE") {
     # Discworlds eigth color. Can't display it yet,
     # but as far as we know, R, G and B are zero,
     # and O is 255
     if(wantarray) {
       return(0,0,0,255);
     } else {
       return "000000ff";
     }
  }

  my $value = $Acme::AutoColor::Colors->FETCH($1);
  if (defined $value) {
    return wantarray ? hex2tuple($value) : $value;
  } else {
    croak "Unknown method: $cname";
  }
}

1;
__END__


=head1 NAME

Acme::AutoColor - automatic color names

=head1 SYNOPSIS

  use Acme::AutoColor;

  $red   = RED();    # 'ff0000'
  @green = GREEN();  # (0, 255, 0)

=head1 DESCRIPTION

This module uses an AUTOLOAD function which assumes unrecognized methods
are color names.

Color names are case-insensitive, though style-wise one should
probably use all capitals.

It returns a hex string or a an array of RGB triplets depending on the
calling context.

Color schemes may be specified in the use line:

  use Acme::AutoColor qw( X HTML );

=head1 OCTARINE

Octarine is the discworlds eigth color. It can't actually displayed with a RGB color scheme,
but as far as we know, its R, G and B components are all zero and O is 0xff. But you can use it
anyway:

  $octarine   = OCTARINE();    # '000000ff'

Beware: Using OCTARINE() may - depending on your location, status as wizard and general thaumic
background radiation levels - reconfigure your computer to display itself. This may result in
damage to your system, secondary thaumic events, creatures from the dungeon dimensions appearing
or the universe collapsing on itself.

=head1 SEE ALSO

L<Graphics::ColorNames>

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

current Maintainer: Rene Schickbauer <rene.schickbauer at gmail.com>

=head1 REPORTING BUGS

We don't know of any bugs, but that doesn't mean there aren't any. Please
the CPAN bugtracker or mail Rene Schickbauer directly.

=head1 LICENSE

Copyright (c) 2005 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Now maintained by Rene Schickbauer, so i guess everything after version 0.01
is (C) 2010 Rene Schickbauer

=cut
