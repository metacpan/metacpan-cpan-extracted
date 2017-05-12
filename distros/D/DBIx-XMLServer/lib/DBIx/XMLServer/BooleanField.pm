# $Id: BooleanField.pm,v 1.5 2005/05/26 15:01:03 mjb47 Exp $

package DBIx::XMLServer::BooleanField;
use XML::LibXML;
our @ISA = ('DBIx::XMLServer::Field');

=head1 NAME

DBIx::XMLServer::BooleanField - Boolean field type

=head1 DESCRIPTION

This class implements the built-in Boolean field type of
DBIx::XMLServer.  The B<where> and B<value> methods are overridden
from the base class.

=head2 B<where> method

  $sql_expression = $boolean_field->where($condition);

The condition must either be empty, or be equal to one of the following:

  !
  =1
  =y
  =yes
  =true
  =0
  =n
  =no
  =false .

If the condition is empty, then the SQL expression is

  <field> IS NOT NULL .

If the condition is the character '!', then the SQL expression is

  <field> IS NULL .

Otherwise, the SQL expression returned is equal to

  <field> = 'Y'  or  <field> = 'N'

accordingly.

=cut

sub where {
  my $self = shift;
  my $cond = shift;
  my $column = $self->select;
  return "$column IS NOT NULL" if $cond eq '';
  return "$column IS NULL" if $cond eq '!';
  $cond or return "$column = 'Y'";
  $cond =~ s/^=// or die "Unrecognised Boolean condition: $cond";
  $cond =~ /^(1|y(es)?|true)$/i && return "$column = 'Y'";
  $cond =~ /^(0|n(o)?|false)$/i && return "$column = 'N'";
  die "Unrecognised Boolean condition: $cond";
}

=head2 B<value> method

The value is either 'true' or 'false', as required by the B<xsi:boolean>
type in XML Schema.

=cut

our %values = ( 'Y' => 'true', 'N' => 'false' );

sub value {
  shift;
  return $values{shift @{shift()}};
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
