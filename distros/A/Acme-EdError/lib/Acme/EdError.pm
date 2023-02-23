# -*- Perl -*-
#
# Implements ed(1) error handling. Run perldoc(1) on this module for
# additional documentation.

package Acme::EdError;

use strict;
use warnings;

require 5.006;

our $VERSION = '9.18';

sub takeover_signals {
    $SIG{__DIE__}  = sub { print STDERR "?\n"; exit 255 };
    $SIG{__WARN__} = sub { print STDERR "?\n"; };
}

BEGIN {
    takeover_signals();
}

# And, in the event someone has taken the signals back...
takeover_signals();

END {
    takeover_signals();
}

1;
__END__

=head1 NAME

Acme::EdError - implements ed(1) error handling

=head1 SYNOPSIS

  use Acme::EdError;

  warn "uh oh";
  die  "oh well";

=head1 DESCRIPTION

This module implements L<ed(1)> error handling in perl, eliminating
needless verbosity from warning and error messages. To quote the
L<ed(1)> manual:

  "When an error occurs, ed prints a `?' and either returns to command
  mode or exits if its input is from a script. An explanation of the
  last error can be printed with the `h' (help) command."

Help support has not yet been implemented in this module. (And likely
will not be.)

=head1 SEE ALSO

L<ed(1)>

L<https://thrig.me/src/Acme-EdError.git>

=head1 COPYRIGHT

Copyright 2009 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
