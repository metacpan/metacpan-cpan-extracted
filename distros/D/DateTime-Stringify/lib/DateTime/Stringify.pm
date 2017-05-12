package DateTime::Stringify;
use strict;
use warnings;
use DateTime;
use vars qw($VERSION);
$VERSION = '4.11';

1;

__END__

=head1 NAME

DateTime::Stringify - DateTime objects (no longer needed)

=head1 SYNOPSIS

  use DateTime;

  my $dt = DateTime->now;
  print "The time is now $dt...\n";
  # The time is now 2004-02-13T16:12:47...

=head1 DESCRIPTION

The DateTime suite of modules are a comprehensive way of representing
and manipulating dates and times. This module used to be needed as
interpolating a DateTime object in a string results in the
not-so-useful "DateTime=HASH(0x800368)" or similar. However, DateTime
has now incorporated the functionality of this module (as of DateTime
0.21). Thus, this module is no longer needed.

This module is just a placeholder now. Just use DateTime instead.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
