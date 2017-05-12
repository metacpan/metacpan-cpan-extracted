package CGI::Untaint::uk_postcode;

$VERSION = '1.00';

use strict;
use base 'CGI::Untaint::object';


sub _untaint_re { 
  my @patterns = ('ON NII', 'ONN NII', 'OON NII', 'OONN NII',
                  'ONO NII', 'OONO NII', 'OOO NII');

  foreach (@patterns) {
    s/N/\\d/g;
    s/O/[A-Z]/g; # outward code
    s/I/[ABDEFGHJLNPQRSTUWXYZ]/g; # inward code
    s/ /\\s?/g;
  }

  my $re = join '|', @patterns;
  return qr/^($re)$/i;
}

=head1 NAME

CGI::Untaint::uk_postcode - validate a UK postcode

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $url = $handler->extract( -as_uk_postcode => 'postcode' );

=head1 DESCRIPTION

This CGI::Untaint input handler verifies that it is dealing with a
reasonably plausible UK postcode, according to some checks by the Royal
Mail. 

Due to the complexities of the UK postal code system it is impossible to
accurately check if the postcode is real, or even if it is of a completely
valid format. As such there may be false positives. There should not,
however, be any false negatives, so if you find any valid postcodes that
this rejects, PLEASE let me know.

=head1 SEE ALSO

http://en.wikipedia.org/wiki/Postcode

L<CGI::Untaint>

=head1 AUTHOR

Tony Bowden. Based on original regular expression by Craig Berry.

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-CGI-Untaint-uk_postcode@rt.cpan.org

=head1 COPYRIGHT

  Copyright (C) 2001-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

1;
