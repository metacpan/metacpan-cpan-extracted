# $Id: TextField.pm,v 1.5 2005/05/26 15:01:04 mjb47 Exp $

package DBIx::XMLServer::TextField;
use XML::LibXML;
our @ISA = ('DBIx::XMLServer::Field');

=head1 NAME

DBIx::XMLServer::TextField - text field type

=head1 DESCRIPTION

This class implements the built-in text field type of DBIx::XMLServer.
Only the B<where> method is overridden from the base class.

=head2 B<where> method

  $sql_expression = $text_field->where($condition);

This field type understands three types of condition:  a string comparison
with wildcards; a regular expression test; and a not-null test.

=over

=item Condition: C<=wild*card?expression>

If the first character of the condition is '=', then the rest of the
condition is interpreted as a string, possible containing wildcards,
to which the column is to be compared.  First the string is escaped by
the DBI system; then any characters '%' and '_' are escaped by
prefixing with '\'; then the characters '*' and '?'  are replaced by
'%' and '_' respectively.  The resulting SQL expression is one of
the following:

  <field> = <string>
  <field> LIKE <string>

depending on whether the string contains any wildcards.

=item Condition: C<~regex>

If the first character of the condition is a tilde '~', then the rest of
the condition is interpreted as a regular expression.  It is escaped by
the DBI system, and the SQL expression is

  <field> RLIKE <string> .

=item Condition: C<> (empty)

If the condition is empty, then the SQL expression is

  <field> IS NOT NULL .

=item Condition: C<!>

If the condition is the single character '!', then the SQL expression is

  <field> IS NULL .

=back

=cut

sub where {
  my $self = shift;
  my $cond = shift;
  my $column = $self->select;
  return "$column IS NOT NULL" if $cond eq '';
  return "$column IS NULL" if $cond eq '!';
  for ($cond) {
    s/^=// && do {
      $_ = $self->{XMLServer}->{dbh}->quote($_);
      s/([%_])/\\$1/g; # Escape any SQL special characters
      return (tr/*?/%_/) ? # Turn wildcards into SQL ones
        "$column LIKE $_" : "$column = $_";
    };
    s/^~// && return "$column RLIKE " . $self->{XMLServer}->{dbh}->quote($_);
    /^$/ && return "$column IS NOT NULL";
    die "Unrecognised condition: $_\n";
  }
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
