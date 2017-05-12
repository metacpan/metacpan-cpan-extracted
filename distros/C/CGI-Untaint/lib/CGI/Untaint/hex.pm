package CGI::Untaint::hex;

use strict;
use base 'CGI::Untaint::object';

sub _untaint_re { 
  qr/^\s*([abcdef1234567890]+)\s*$/i
}

=head1 NAME

CGI::Untaint::hex - validate as a hexadecimal value

=head1 SYNOPSIS

  my $id = $handler->extract(-as_hex => 'hexvalue');

=head1 DESCRIPTION

This Input Handler verifies that it is dealing with a hexadecimal
value.

=head1 AUTHOR

Tony Bowden, E<lt>kasei@tmtm.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2001 Tony Bowden. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
