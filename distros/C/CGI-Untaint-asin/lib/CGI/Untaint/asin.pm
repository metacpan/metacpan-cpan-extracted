package CGI::Untaint::asin;

$VERSION = '1.02';

use strict;
use base 'CGI::Untaint::object';

sub _untaint_re { 
  qr/^([\d\w]\d{3}[\d\w]{6})$/i;
}

1;

=head1 NAME

CGI::Untaint::asin - validate an Amazon ID

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $url = $handler->extract( -as_asin => 'id' );

=head1 DESCRIPTION

This CGI::Untaint input handler verifies that it is dealing with a
plausible Amazon ID (asin). It does not (yet?) check that this is a *real*
asin, just that it looks like one.

=head1 SEE ALSO

L<CGI::Untaint>

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-CGI-Untaint-asin@rt.cpan.org

=head1 COPYRIGHT

  Copyright (C) 2004-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut
