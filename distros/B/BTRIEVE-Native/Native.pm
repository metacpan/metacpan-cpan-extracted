package BTRIEVE::Native;

require DynaLoader;

@ISA = 'DynaLoader';

$VERSION = '0.04';

bootstrap BTRIEVE::Native $VERSION;

# -----------------------------------------------------------------------------
1;

=head1 NAME

BTRIEVE::Native - Interface to Btrieve ISAM file manager

=head1 SYNOPSIS

  use BTRIEVE::Native();

  $B = \&BTRIEVE::Native::Call;

  $p = "\0" x 128;
  $d = "\0";
  $l = 0;
  $k = 'TEST.BTR';

  $B->( 0, $p, $d, $l, $k, 0 );

  $l = 13;
  $d = "\0" x $l;
  $k = "\0" x 255;

  $\ = "\n";
  $, = ':';
  print unpack 'A3A10', $d while !$B->( 24, $p, $d, $l, $k, 0 );

=head1 DESCRIPTION

This is a simple wrapper for the Btrieve single function API.

=head2 Btrieve Functions

The Call() function of this module allows you to make Btrieve calls:

  $Status = BTRIEVE::Native::Call( ... );

It's a wrapper for Btrieve's BTRV (or BTRCALL) function. Btrieve's
BTRVID function is currently not supported.

=head2 Btrieve Function Parameters

The Call() function expects the following parameters:

  Operation Code
  Position Block
  Data Buffer
  Data Buffer Length
  Key Buffer
  Key Number

Every Call() returns a numeric status code which indicates success or a
specific error.

=head2 Btrieve Operations

The Operation Code parameter of the Call() function is a numeric code that
determines the Btrieve operation, e.g.:

  14  Create
   0  Open
   1  Close

  33  Step First
  34  Step Last
  24  Step Next
  35  Step Previous

  12  Get First
  13  Get Last
   5  Get Equal
   8  Get Greater
   6  Get Next
   7  Get Previous

Consult the Btrieve API reference manual for detailed information.
At the time this was written, Pervasive Software Inc. made available
the online documentation at

  http://www.pervasive.com/library/prog_api/BtrIntro.html

=head1 AUTHOR

Steffen Goeldner <sgoeldner@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003, 2014 Steffen Goeldner. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=cut
