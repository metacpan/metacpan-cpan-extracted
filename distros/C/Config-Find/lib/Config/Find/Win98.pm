package Config::Find::Win98;

use strict;
use warnings;

use Config::Find::WinAny

our @ISA = qw(Config::Find::WinAny);

1;

__END__

=encoding latin1

=head1 NAME

Config::Find::Win98 - Win98 idiosyncrasies for Config::Find

=head1 SYNOPSIS

  # don't use Config::Find::Win98 directly
  use Config::Find;

=head1 ABSTRACT

Implements Win98 specific features for Config::Find

=head1 DESCRIPTION

Contains any idiosyncrasies found within Win98, that do not apply to the 
standard Win32 base.

=head1 SEE ALSO

L<Config::Find>, L<Config::Find::WinAny>, L<Config::Find::Any>

=head1 AUTHOR

Salvador FandiE<ntilde>o GarcE<iacute>a, E<lt>sfandino@yahoo.comE<gt>

=head1 CONTRIBUTORS

Barbie, E<lt>barbie@missbarbell.co.ukE<gt> (some bug fixes and documentation)

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2015 by Salvador FandiE<ntilde>o GarcE<iacute>a (sfandino@yahoo.com)
Copyright 2015 by Barbie (barbie@missbarbell.co.uk)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
