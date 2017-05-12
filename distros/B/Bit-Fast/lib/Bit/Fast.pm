package Bit::Fast;

use strict;
use warnings;

require Exporter;
use Config;

our @ISA = qw(Exporter);

my @funcs = qw(popcount);
if ($Config{longsize} == 8) {
    push @funcs, qw(popcountl);
}

our %EXPORT_TAGS = ( 'all' => \@funcs );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Bit::Fast', $VERSION);

1;

__END__

=head1 NAME

Bit::Fast - A set of fast bit manupulation routines

=head1 SYNOPSIS

  use Bit::Fast qw(popcount popcountl);
  my $count = popcount(33);
  print $count, "\n";               # prints 2

  # 8-byte integer value:
  $count = popcountl(33 << 33);
  print $count, "\n";               # prints 2

=head1 DESCRIPTION

The goal of this module is provide B<fast> bit manipulation routines.

=head2 popcount($v)

Returns the number of 1-bits in $v.  Works on 32-bit integers.

=head2 popcountl($v)

Returns the number of 1-bits in $v.  Works on 64-bit integers.  (This
function is not provided on 32-bits builds of perl.)

=head1 AUTHOR

Dmitri Tikhonov, E<lt>dmitri@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Dmitri Tikhonov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
