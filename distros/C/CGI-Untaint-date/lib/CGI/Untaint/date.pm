package CGI::Untaint::date;

$VERSION = '1.00';

use strict;
use base 'CGI::Untaint::printable';
use Date::Manip;
use Date::Simple;

sub is_valid {
  my $self = shift;
  local $SIG{__WARN__} = sub {};
  local *Date::Manip::Date_TimeZone = sub { 'GMT' };
  Date_Init(sprintf 'DateFormat=%s' => $self->date_format);
  my $date = ParseDate($self->value) or return;
  my @date = unpack "A4A2A2", $date;
  my $ds = eval { Date::Simple->new(@date) } or return;
  $self->value($ds);
  return $ds;
}

sub date_format { 'UK' }

=head1 NAME

CGI::Untaint::date - validate a date

=head1 SYNOPSIS

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $date = $handler->extract(-as_date => 'date');

=head1 DESCRIPTION

=head2 is_valid

This Input Handler verifies that it is dealing with a reasonable
date. Reasonably means anything that Date::Manip thinks is
sensible, so you could use any of (for example):
  "December 12, 2001"
  "12th December, 2001"
  "2001-12-12"
  "next Tuesday"
  "third Wednesday in March"

See L<Date::Manip> for much more information on what date formats are
acceptable.

The resulting date will be a Date::Simple object. 
L<Date::Simple> for more information on this.

=head2 date_format

By default ambiguous dates of the format 08/09/2001 will be treated as
UK style (i.e. 8th September rather than 9th August)

If you want to change this, subclass it and override date_format()

=head1 WARNING

Date::Manip does not play nicely with taint mode. In order to work
around this we locally clobber Date::Manip's 'timezone' code. As we're
only interested in dates rather than times, this shouldn't be much of
an issue. If it is, then please let me know!

=head1 SEE ALSO

L<Date::Simple>. L<Date::Manip>.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-CGI-Untaint-date@rt.cpan.org

=head1 COPYRIGHT and LICENSE

Copyright (C) 2001-2005 Tony Bowden. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
