package CGI::Untaint::integer;

use strict;
use base 'CGI::Untaint::object';
sub _untaint_re { qr/^([+-]?\d+)$/ }

=head1 NAME

CGI::Untaint::integer - validate an integer

=head1 SYNOPSIS

  my $age = $handler->extract(-as_integer => 'age');

=head1 DESCRIPTION

This Input Handler verifies that it is dealing with an integer.
The integer can be positive or negative, but only in a basic format
(i.e. a string of digits). It will not accept exponentials.

=head1 AUTHOR

Tony Bowden, E<lt>kasei@tmtm.comE<gt>. 

=head1 COPYRIGHT

Copyright (C) 2001 Tony Bowden. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
