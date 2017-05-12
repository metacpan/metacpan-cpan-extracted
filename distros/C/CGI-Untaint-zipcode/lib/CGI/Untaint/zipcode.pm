package CGI::Untaint::zipcode;

use strict;
use warnings;

use base 'CGI::Untaint::object';

use vars qw/$VERSION/;
$VERSION = '0.02';

sub _untaint_re { 

  return qr/^(\d{5}(-\d{4})?)$/;

}

=head1 NAME

CGI::Untaint::zipcode - validate a US zipcode

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $zipcode = $handler->extract( -as_zipcode => 'zip' );

=head1 DESCRIPTION

This CGI::Untaint input handler verifies that it is dealing with a
reasonable United States zipcode, in either the five- or nine-digit
format. It does not check whether the zipcode is real.

=head1 SEE ALSO

L<CGI::Untaint>

=head1 AUTHOR

Jesse Sheidlower, C<jester@panix.com>

=head1 COPYRIGHT

Copyright (C) 2004 Jesse Sheidlower. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
