# $Id: DateTimeField.pm,v 1.5 2005/10/05 20:39:34 mjb47 Exp $

package DBIx::XMLServer::DateTimeField;
use XML::LibXML;
use Date::Manip qw( Date_Init UnixDate );
our @ISA = ('DBIx::XMLServer::Field');

=head1 NAME

DBIx::XMLServer::DateTimeField - date and time field type

=head1 DESCRIPTION

This class implements the built-in date and time field type of
DBIx::XMLServer.  The B<where> and B<value> methods are overridden
from the base class.

=head2 B<where> method

  $sql_expression = $date_time_field->where($condition);

The condition may consist of one of the numeric comparison operators
'=', '>', '<', '>=' or '<=', followed by a date and time.  The date
and time may be in any format understood by the C<Date::Manip>
package, such as '2003-11-03 21:29:10' or 'yesterday at midnight'.

Alternatively, the condition may be empty, in which case the SQL expression
is

  <field> IS NOT NULL .

If the condition is the character '!', then the SQL expression is

  <field> IS NULL .

=cut

sub BEGIN { Date_Init("DateFormat = EU"); }

sub where {
  my $self = shift;
  my $cond = shift;
  return "$column IS NOT NULL" if $cond eq '';
  return "$column IS NULL" if $cond eq '!';
  my $column = $self->select;
  my ($comp, $date) = ($cond =~ /([=<>]+)(.*)/);
  defined $comp or die "Unrecognised date condition: $cond\n";
  $comp =~ /^(=|[<>]=?)$/ or die "Unrecognised date/time comparison: $comp\n";
  my $date1 = UnixDate($date, '%q') or die "Unrecognised date/time: $date\n";
  return "$column $comp " . $date1;
}

=head2 B<value> method

The date and time is returned in the format 'YYYY-mm-ddThh:mm:ss', as 
required by the B<xsi:datetime> type in XML Schema.

=cut

sub value {
  shift;
  return UnixDate(shift @{shift()}, '%Y-%m-%dT%T');
}

1;

__END__

=head1 SEE ALSO

L<DBIx::XMLServer::Field>

=head1 AUTHOR

Martin Bright E<lt>martin@boojum.org.ukE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2003-4 Martin Bright

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
