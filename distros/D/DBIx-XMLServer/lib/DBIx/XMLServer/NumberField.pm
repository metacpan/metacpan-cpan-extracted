# $Id: NumberField.pm,v 1.6 2005/05/26 15:01:04 mjb47 Exp $

package DBIx::XMLServer::NumberField;
use XML::LibXML;
our @ISA = ('DBIx::XMLServer::Field');

=head1 NAME

DBIx::XMLServer::NumberField - integer field type

=head1 DESCRIPTION

This class implements the built-in integer field type of
DBIx::XMLServer.  Only the B<where> method is overridden from the base
class.

=head2 B<where> method

  $sql_expression = $number_field->where($condition);

The condition may consist of one of the numeric comparison operators '=',
'>', '<', '>=' or '<=', followed by an integer.  The integer must match the
regular expression '-?\d+'.  The resulting SQL expression is simply

  <field> <condition> <value> .

If the operator is '=', then instead of a single integer a comma-separated
list of integers may be given.  Then the SQL expression is

  <field> IN (<value1>, <value2>, ...) .

Alternatively, the condition may be empty, in which case the SQL expression
is

  <field> IS NOT NULL .

If the condition is the character '!', then the SQL expression is

  <field> IS NULL .

=cut

sub where {
  my $self = shift;
  my $cond = shift;
  my $column = $self->select;
  return "$column IS NOT NULL" if $cond eq '';
  return "$column IS NULL" if $cond eq '!';
  my ($comp, $value) = ($cond =~ /([=<>]+)(.*)/);
  defined($comp) or die "Unrecognised number condition: $cond\n";
  $comp =~ /^(=|[<>]=?)$/ or die "Unrecognised number comparison: $comp\n";
  if($comp eq '=' && $value =~ /^-?\d+(\s*,\s*-?\d+)+$/) {
    return "$column IN ($value)";
  }
  $value =~ /^-?\d+$/ or die "Unrecognised number: $value\n";
  return "$column $comp $value";
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
