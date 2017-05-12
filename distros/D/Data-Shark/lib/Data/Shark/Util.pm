#
# Data::Shark::Util.pm
#
# Copyright (C) 2007 William Walz. All Rights Reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Util.pm 907 2006-05-19 17:39:37Z bill $
#

package Data::Shark::Util;

use version; our $VERSION = qv('2.1');

use strict;
use base qw( Exporter );

our @EXPORT      = qw( );
our @EXPORT_OK   = qw( mc commify my_money );
our %EXPORT_TAGS = (
    ALL => [@EXPORT, @EXPORT_OK],
);

# 
# Module Functions
#

sub commify {
  local $_  = shift;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
}

sub my_money {
  my ($a,$dash) = @_;

  $a = 0 if !$a;

  return '-' if !$a && $dash;

  $a = sprintf("%0.2f", $a);

  my $b = commify($a);

  $a < 0 && do {
    $b =~ s/-//g;
    return '$(' . $b .')';
  };

  return '$' . $b;
}

sub mc {
  # makes a string Mixed Case
  my $str = lc shift;
  $str =~ s/(\w+)/\u$1/g;
  return $str;
}

1;
__END__

=head1 NAME

Data::Shark::Util - collection of utility functions

=head1 SYNOPSYS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 AUTHOR

    William Walz (Jack)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 William Walz. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
