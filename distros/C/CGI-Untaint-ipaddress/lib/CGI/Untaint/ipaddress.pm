package CGI::Untaint::ipaddress;

use strict;
use base 'CGI::Untaint::object';

use vars qw/$VERSION/;
$VERSION = '0.01';

sub _untaint_re { 
  return qr/^((?:(?:25[0-5]|2[0-4]\d|[0-1]??\d{1,2})[.](?:25[0-5]|2[0-4]\d|[0-1]??\d{1,2})[.](?:25[0-5]|2[0-4]\d|[0-1]??\d{1,2})[.](?:25[0-5]|2[0-4]\d|[0-1]??\d{1,2})))$/i;
}

=head1 NAME

CGI::Untaint::ipaddress - validate an IP address

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $url = $handler->extract( -as_ipaddress => 'ip' );

=head1 DESCRIPTION

This CGI::Untaint input handler verifies that it is dealing with a
reasonable IP. It does not check that the IP address is routable or reserved.

=head1 SEE ALSO

L<CGI::Untaint>

=head1 AUTHOR

Simon Cozens, C<simon@kasei.com>

=head1 COPYRIGHT

Copyright (C) 2003 Simon Cozens. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
