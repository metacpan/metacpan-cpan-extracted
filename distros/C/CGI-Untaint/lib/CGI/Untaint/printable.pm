package CGI::Untaint::printable;

use strict;
use base 'CGI::Untaint::object';

sub _untaint_re {
	qr/^([\040-\377\r\n\t]*)$/;
}

=head1 NAME

CGI::Untaint::printable - validate as a printable value

=head1 SYNOPSIS

  my $name = $handler->extract(-as_printable => 'name');

=head1 DESCRIPTION

This Input Handler verifies that it is dealing with an 'printable'
string i.e. characters in the range \040-\377 (plus \r and \n).

The empty string is taken to be printable.

This is occasionally a useful 'fallback' pattern, but in general you
will want to write your own patterns to be stricter.

=cut

1;
