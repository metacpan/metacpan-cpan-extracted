package IntrospectM2M;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->mk_classdata( _m2m_metadata => {} );

sub many_to_many {
  my $class = shift;
  my ($meth_name, $link, $far_side) = @_;
  my $store = $class->_m2m_metadata;
  die "You are overwritting another relationship's metadata"
    if exists $store->{$meth_name};

  my $attrs = {
    accessor => $meth_name,
    relation => $link, #"link" table or immediate relation
    foreign_relation => $far_side, #'far' table or foreign relation
    (@_ > 3 ? (attrs => $_[3]) : ()), #only store if exist
  };

  #inheritable data workaround
  $class->_m2m_metadata({ $meth_name => $attrs, %$store});
  $class->next::method(@_);
}

1;
