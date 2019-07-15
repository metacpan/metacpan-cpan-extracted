package Algorithm::CP::IZ::FindFreeVar;
use strict;
use warnings;

use constant {
    Default => 0,
    NbElements => 1,
#    NbElementsMin => 2,
};

1;

__END__

=head1 NAME

Algorithm::CP::IZ::FindFreeVar - FindFreeVar functions

=head1 SYNOPSIS

  use Algorithm::CP::IZ;

  my $iz = Algorithm::CP::IZ->new();

  # create instances of Algorithm::CP::IZ::Int
  # contains domain {0..9}
  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);

  # add constraint
  $iz->Add($v1, $v2)->Eq(12);

  # specify FindFreeVar option value
  my $rc = $iz->search([$v1, $v2],
      { FindFreeVar => Algorithm::CP::IZ::FindFreeVar::Default } );

  if ($rc) {
     print "ok\n";
  }
  else {
    print "ng\n";
  }

=head1 DESCRIPTION

Algorithm::CP::IZ::FindFreeVar provides constants to sepcify search strategy.

=head1 CONSTANTS

=over 2

=item Default

Find first (in order of array) free variable.

=item NbElements

Find free variable having minimum domain size.
If variable having same size domain is found, first (in order of array) one
is used.

=back

=head1 SEE ALSO

L<Algorithm::CP::IZ>
L<Algorithm::CP::IZ::Int>

=head1 AUTHOR

Toshimitsu FUJIWARA, E<lt>tttfjw at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Toshimitsu FUJIWARA

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
