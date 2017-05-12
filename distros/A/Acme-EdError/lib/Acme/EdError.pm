# -*- Perl -*-
#
# Implements ed(1) error handling. Run perldoc(1) on this module for
# additional documentation.
#
# Copyright 2009,2012-2013,2015 by Jeremy Mates.
#
# This module is free software; you can redistribute it and/or modify it
# under the Artistic license.

package Acme::EdError;

use strict;
use warnings;

require 5.006;

our $VERSION = '9.17';

sub takeover_signals {
  $SIG{__DIE__} = sub { print STDERR "?\n"; exit 255 };
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

L<http://github.com/thrig/Acme-EdError>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT

Copyright 2009,2012-2013,2015 by Jeremy Mates.

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
