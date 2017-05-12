package Acme::Current::Forever;
use strict;

use vars qw/$VERSION/;
$VERSION = '1.00';
use Acme::Current;

1;

__END__

=head1 NAME

Acme::Current::Forever - Acme::Current workalike that doesn't require you to update every bloody day

=head1 SYNOPSIS

  use Acme::Current;
  printf "It's now %04d/%02d/%02d.\n",
    $Acme::Current::YEAR,
    $Acme::Current::MONTH,
    $Acme::Current::DAY;
  if ($Acme::Current::MONTH == 12 and $Acme::Current::DAY == 25) {
    print "Merry Christmas!\n";
  }

=head1 DESCRIPTION

This module replaces Randal L Schwartz' Acme::Current with a module 
with an identical API that never needs updating.

C<Acme::Current> gives you all the power of those myriad of date/time
modules without all that complexity, as long as all you want is the
current date (GMT-based), and you keep the module up to date.

=head1 EXPORT

Nothing.  You need to use C<$Acme::Current::YEAR> to get the year,
and so on.

=head1 BUGS

None known.

=head1 SEE ALSO

C<Date::Manip>, and a hundred other date and time modules.

See L<http://training.perl.org> for all your Perl training
needs.

=head1 AUTHOR

Jesse Vincent <jesse@cpan.org> based on an inane acme module by

Randal L. Schwartz, E<lt>merlyn@stonehenge.comE<gt>,
L<http://www.stonehenge.com/merlyn/>.

Based on an idea from a conversation with Joshua Hoblitt.

=head1 COPYRIGHT AND LICENSE

Portions Copyright 2003 by Jesse Vincent

Portions Copyright 2003 by Randal L. Schwartz, Stonehenge Consulting Services, Inc.


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
