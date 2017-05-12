
package 
Class::DBI::Lite::EntityMeta;

use strict;
use warnings 'all';

our %instances = ( );


#==============================================================================
sub new
{
  my ($s, $forClass, $schema, $entity) = @_;

  my $key = join ':', ( $schema, $entity );
  if( my $inst = $instances{$key} )
  {
    return $inst;
  }
  else
  {
    return $instances{$key} = bless {
      table         => $entity, # Class-based
      triggers      => {      # Class-based
        before_create => [ ],
        after_create  => [ ],
        before_update => [ ],
        after_update  => [ ],
        before_delete => [ ],
        after_delete  => [ ],
      },
      has_a_rels    => { },   # Class-based
      has_many_rels => { },   # Class-based,
      columns       => $forClass->get_meta_columns( $schema, $entity ),
      trace         => 0,
    }, $s;
  }# end if()
}# end new()

sub table         { my $s = shift; @_ ? $s->{table}         = shift : $s->{table} }
sub triggers      { my $s = shift; @_ ? $s->{triggers}      = shift : $s->{triggers} }
sub has_a_rels    { my $s = shift; @_ ? $s->{has_a_rels}    = shift : $s->{has_a_rels} }
sub has_many_rels { my $s = shift; @_ ? $s->{has_many_rels} = shift : $s->{has_many_rels} }
sub columns       { my $s = shift; @_ ? $s->{columns}       = shift : $s->{columns} }
sub trace         { my $s = shift; @_ ? $s->{trace}         = shift : $s->{trace} }

1;# return true:

