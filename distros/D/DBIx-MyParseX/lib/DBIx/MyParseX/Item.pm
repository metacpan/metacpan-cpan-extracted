package DBIx::MyParseX::Item;
  our $VERSION = '0.06';
    
  use 5.008008;
  use base 'DBIx::MyParse::Item';
  use DBIx::MyParse;
  use DBIx::MyParse::Item;
  use DBIx::MyParseX;


  1;


# ---------------------------------------------------------------------
# package DBIx::MyParse::Item
#   WE set the package to 'DBIx::MyParse::Item' since this package 
#   provides ONLY extension methods and no methods in its own namespace
#
# Items:
#   FUNC_ITEM, SUM_FUNC_ITEM (c) Yes.  getFuncArgs   
#       getType     
#       getFuncType 
#       getFuncName, hasArguments, getFuncArgs
#       is a collection on args
#
#   FIELD_ITEM, getFieldName
#   
#   REF_ITEM 
#   TABLE_ITEM getTableName
#       
#
#   JOIN_ITEM*(C)
#       getJoinItems: SUBSELECT_ITEM,JOIN_ITEM,TABLE_ITEM
#       getJoinFields
#
#   SUBSELECT_ITEM*
#       getSubselectQuery
#
#   'STRING_ITEM', 'INT_ITEM', 'DECIMAL_ITEM', 'REAL_ITEM' and 'VARBIN_ITEM'
#       getValue()
#
#   $query->each( ITEM_TYPE, function, args );
#       FIELD_ITEM, rename, old_name, new_name  
#   There is a function that will walk the tree 
#   $query->action( CLAUSE | ITEM level, function call, args )
#   action( CLAUSE, function( 
package DBIx::MyParse::Item;

use strict;
use warnings;
use Carp;

use List::MoreUtils qw( any );
use Perl6::Say;
use YAML;
use self;
use Data::Dumper;

# HASHREF to contain the methods for getting the children based on 
#   ITEM_TYPE => sub { .. }
#   These should be the only items that should have children.
#   These Items can have subitems.
my $getChildrenFor = {
    FUNC_ITEM       => sub { getArguments( @_ ) } ,
    SUM_FUNC_ITEM   => sub { getArguments( @_ ) } ,
    JOIN_ITEM       => sub { getJoinItems( @_ ) } ,
    SUBSELECT_ITEM  => sub { getSubselectQuery( @_ ) } ,
};


# ---------------------------------------------------------------------
# _string_to _method
#   converts a method_name to a closure
# ---------------------------------------------------------------------
sub _string_to_method {

    my ( $item, $method_name, $args ) = @_;

    $method_name = __PACKAGE__ ."::$method_name" ;
    my $eval_string = 'sub { $_[0]->' . $method_name . '( @_[ 1 .. $#_ ] ) }';
    my $method = eval( $eval_string );

    return $method;

}



# ---------------------------------------------------------------------
# getItems
#   with DBIx::MyParseX::getItems returns a collapsed list of all 
#   DBIx::MyParse::Items from the query tree
# ---------------------------------------------------------------------
sub getItems {

    my $type = self->getItemType();
    my @items;  # Array of items-refs to return 
    
  # COLLECTION?
    if  ( my $getChildren = $getChildrenFor->{ $type } ) {

        foreach my $subitem ( @{ self->$getChildren } ) {

            if ( 
                ref( $subitem ) eq 'DBIx::MyParse::Item'  or
                ref( $subitem ) eq 'DBIx::MyParse::Query'
            ) { 
                push( @items, $subitem->getItems ) 
            }

        }  

    }   

  # JUST A PLAIN ITEM
    else { 
        push @items, self;
    };

    return @items;

} # END SUB getItems 



# ----------------------------------------------------------------------
# SUB: renameTable
#   USAGE: $table_item->rename( $new_name ) 
#
#   No return value, exist solely for it's side-effects.  Case switches
#   based on the type of item.
#
#   TODO: 
#     x Generalize to any DBIx::MyParse::Item?
#     - Handle subquery objects 
#
# ----------------------------------------------------------------------
    

sub renameTable {

    # my $item = shift;

    # say "@_";
    my ( $old_table_name, $new_table_name ) = args;

  # TRAP non DBIx::MyParse::Items
    Carp( "Cannot renameTable for non-DBIx::MyParse::Item" ) 
        if ( ref self ne 'DBIx::MyParse::Item' );

  # CASE-SWITCH on DBIx::MyParse::Item::Type

    my $type = self->getItemType;

  # ----------------------------------------------------------
  # CASE: JOIN_ITEM
  #   JOIN_ITEMs contains more than one table therefore, we 
  #   recurse on each subitem.   
  # ----------------------------------------------------------
    if ( $type eq 'JOIN_ITEM' ) {

        foreach my $join_item ( @{ self->getJoinItems } ) {
            
            $join_item->renameTable( $old_table_name, $new_table_name );

        }

    } # END CASE: JOIN_ITEM


  # ---------------------------------------------------------- 
  # CASE: FUNC_ITEM, COND_ITEM, COND_AND_FUNC
  #   similar to JOIN_ITEM.  Dispatch on getArguments
  # ---------------------------------------------------------- 
   if ( 
        any { $type eq $_ }  
        qw( FUNC_ITEM COND_ITEM COND_AND_FUNC ) 
   ) {
           
        foreach my $arg ( @{ self->getArguments } ) {

            $arg->renameTable( $old_table_name, $new_table_name );

        }
          
   } # END CASE: FUNC_ITEM               
                            
            
  # ----------------------------------------------------------
  # CASE: TABLE_ITEM, FIELD_ITEM
  #    match on regular expression match
  # ----------------------------------------------------------
    if ( 
         any { $type eq $_  }  qw( TABLE_ITEM FIELD_ITEM ) 
    ) {
      
      # TEST for match on old table name. 
      # TableName must exist and match for it to be changed otherwise ...
      # there is nothing to change
        if ( 
             self->getTableName && 
             self->getTableName  =~ m/$old_table_name/ 
        ) {

             self->setTableName( $new_table_name );

        }

    } # END CASE: TABLE_ITEM 

} # END SUB: renameTable


# The problem is that the item can be a collection of items or a single item
# map { } self->getItems
# item->doMethod( 'method_name', args );
# item->$_[1]( @[2,.] );
sub renameTablex {

    my $type = self->getItemType;  
    my ( $old_table_name, $new_table_name ) = args;

    
    if ( any { $type eq $_  }  qw( TABLE_ITEM FIELD_ITEM ) ) {

        if ( 
             self->getTableName && 
             self->getTableName  =~ m/$old_table_name/ 
        ) {
             self->setTableName( $new_table_name );
        }  
        
    }

} # renameTable

1;
__END__

=head1 NAME

DBIx::MyParseX::Item - Extensions to DBIx::MyParse::Item

=head1 SYNOPSIS

  use DBIx::MyParseX::Item;

  $item->renameTable( 'old_table', 'new_table' );
  $item->renameTable( 'regex', 'new_table' );

=head1 DESCRIPTION

This extension provides exteneded functionality for the DBIx::MyParse::Item 
module.  It uses DBIx::MyParse, DBIx::MyParseX and DBIx::MyParse::Item.


=head1 METHODS

=head2 renameTable

    $item->renameTable( 'old_name', 'new_name' )

Descends through the parse tree renaming all instances of C<old_name> 
to C<new_name>. 


=head2  getItems

    $item->getItems( );

returns a collapsed list of all DBIx::MyParse::Items from the query 
tree. 


=head1 Disadvantages

Since the orignal DBIx::MyParse package does not make seperate objects for each ot the
items, relying instead on ItemType, we must follow the original framework.



=head2 EXPORT

None by default.



=head1 SEE ALSO

L<DBIx::MyParse>, L<DBIx::MyParse::Item>, L<DBIx::MyParseX>, 

L<http://www.mysql.com> 

L<http://www.opendatagroup.com>


=head1 AUTHOR

Christopher Brown, E<lt>ctbrown@cpan.org<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Open Data Group

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public Licence.


=cut
