package DBIx::Class::ResultSet::ProxyField;
use base 'DBIx::Class::ResultSet';

#use Data::Dumper 'Dumper';

=head2 create

Class function

re defined defined create to adapt object field before create

=cut

sub create
{
  my ($class, $attrs) = @_;
#print "ProxiField create\n";
  $result_class = $class->_get_result_class();
  $result_class->class_adaptator_to_bdd($attrs);
  return $class->next::method($attrs);
}

=head2 search

Class function

re defined search to adapt search attribute before search

=cut

sub search
{
  my ($class, $attrs, $additional_attributes) = @_;
#print "ProxiField search\n";
  $result_class = $class->_get_result_class();
  $result_class->class_adaptator_to_bdd($attrs) if defined $attrs;
  return $class->next::method($attrs, $additional_attributes);
}

=head2 _get_result_class

Protected Class function

=cut

sub _get_result_class
{
  my $class = shift;
  my $result_class = ref $class;
  $result_class =~ s/ResultSet/Result/g;
  return $result_class;
}

1;
