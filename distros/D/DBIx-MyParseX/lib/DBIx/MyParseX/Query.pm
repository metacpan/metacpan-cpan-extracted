package DBIx::MyParseX::Query;
  our $VERSION = '0.06';
  use base 'DBIx::MyParse::Query';    
  1;

# ---------------------------------------------------------------------
# package DBIx::MyParse::Query
#   WE set the package to 'DBIx::MyParse::Query' since this package 
#   provides ONLY extension methods and no methods in its own namespace
#
package DBIx::MyParse::Query;   

use 5.008008;
use strict;
use warnings;
use DBIx::MyParse;
use DBIx::MyParse::Query;
use DBIx::MyParseX;
use Perl6::Say;
# use DBIx::MyParseX::Item;
use List::MoreUtils qw(any);
use self;
                            
# --------------------------------------------------------------------- 
# CLAUSES :
#   getChildrenFor: methods for returning the children of a clause
# --------------------------------------------------------------------- 
my $getChildrenFor = {
    SELECT => sub { getSelectItems( @_ ) } ,
    WHERE  => sub { getWhere( @_ )       } ,
    HAVING => sub { getHaving( @_ )      } ,
    ORDER  => sub { getOrder( @_ )       } ,
    LIMIT  => sub { getLimit( @_ )       } ,
    GROUP  => sub { getGroup( @_ )       } ,

    TABLES  => sub { getTables( @_ )      } ,
    FROM   => sub { getTables( @_ )      } ,

    TEST   => sub { print "testing" ; }
};


my @clauses = qw( SELECT FROM WHERE GROUP HAVING ORDER LIMIT ) ;

sub getFrom { getTables(@_) }; # Alias for getTables;


# --------------------------------------------------------------------- 
# Test Methods :
#   Indicates if the Query has one of the following clauses
# --------------------------------------------------------------------- 
sub hasSelect { return 1 if ( self->getSelectItems ); return 0 };
sub hasWhere  { return 1 if ( self->getWhere ); return 0 };
sub hasHaving { return 1 if ( self->getHaving ); return 0 };
sub hasOrder  { return 1 if ( self->getOrder ); return 0 };
sub hasLimit  { return 1 if ( self->getLimit ); return 0 };

sub hasTables { return 1 if ( self->getTables ); return 0};
sub hasTable  { return 1 if ( self->getTables ); return 0};
sub hasFrom   { return 1 if ( self->getTables ); return 0};
sub hasGroup  { return 1 if ( self->getGroup  ); return 0};


# Queries have different clauses.
# Clauses have different items.
# CLAUSES 
#   SELECT          getSelectItems      ARRAY[ITEMS]
#   TABLE           getTables           ARRAY[ITEMS]    getType
#   WHERE, HAVING   getWhere, getHaving ITEM[TREE]
#   GROUP           getGroup            ARRAY[ITEM]
#   ORDER           getOrder            ARRAY[ITEM]
#   LIMIT           getLimit            ARRAY[ITEM,ITEM]
#

# ---------------------------------------------------------------------
# SUB ROUTINE getItems
#   Return an array of refs to the items from the query
# 
#   This routine flattens out the parse tree.
#
# ---------------------------------------------------------------------
sub getItems {

    my ( $q ) = @_;
    my @items; # array to contain the query items;

    foreach my $clause ( @clauses ) {

      # CLAUSE
        my $method = $getChildrenFor->{ $clause };
        foreach my $child ( $q->$method  ) {   # Iterate children 

          # ITEM or QUERY
            if ( 
                ref $child eq 'DBIx::MyParse::Item' 
                or ref $child eq 'DBIx::MyParse::Query'
            ) {
                # push @items , $child->getItems( @_[ 1..$#_ ] ) ;
                push @items , $child->getItems(  args  ) ;
            }

          # ARRAY REF
            elsif ( ref $child eq 'ARRAY' ) {
            
                foreach my $element ( @$child ) {
            
                    if ( 
                        ref $element eq 'DBIx::MyParse::Item' or
                        ref $element eq 'DBIx::MyParse::Query'
                    ) {
                        push @items, $element->getItems( args );
                    } else {
                        carp( "Non-DBIx::Parse object encountered in Parsed Query" );
                    }
                }
            } # END ARRAYREF

        # ARRAY?
        #    else {
        #
        #        use YAML;
        #        # print Dump $child;
        #
        #    }

        } # Iterate children of clause

    } # Iterate clause

    return @items;

} # END SUB: getItems
                          
    
# --------------------------------------------------------------------
# SUB: renameTable 
#   package: DBIx::MyParse::Query
#   Usage:
#       $q->renameTable( old_name, new_name )
#
#   Given a query, will rename all the tables with the new name
#   has no return value, exists for the side-effects.
#
# --------------------------------------------------------------------
sub renameTable {

    carp( "A non DBIx:;MyParse::Query Object was passed to renameTable()" ) 
        if ( ref self  ne 'DBIx::MyParse::Query' );
    
    map { $_->renameTable( args ) } self->getItems;

    return 1;
    
} # END sub: renameTable




1;


__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DBIx::MyParseX::Query - Extended methods to DBIx::MyParse::Query

=head1 SYNOPSIS

    use DBIx::MyParseX;
    my $p = DBIx::MyParse->new();
    my $q = $p->parse( "select ..." );

  # Query Manipulation methods
    $q->renameTable( 'old_table', 'new_table' );  


=head1 DESCRIPTION

This extension provides exteneded functionality for the DBIx::MyParse::Query 
module.  Calls DBIx::MyParse::Query and DBIx::MyParseX.  Extends 
DBIx::MyParse::Query.   

All methods are defined in the DBIx::MyParse::Query package space

=head1 METHODS

=head2 hasSelect

    $query->hasSelect

Indicates that the Query contains a SELECT clause


=head2 hasWhere

Indicates that the query has a WHERE clause.


=head2 hasHaving    

Indicates that the query has a HAVING clause.


=head2 hasOrder

Indicates that the query has a ORDER (BY) clause.


=head2 hasLimit

Indicates that the query has a LIMIT clause.


=head2 hasTable / hasTables

Indicates that the query has tables.  The two forms are identical.


=head2 hasFrom

Indicates that the query has a FROM clause


=head2 hasGroup

Indicates that the query has a GROUP (BY) clause


=head2 getItems

    my @items = $query->getItems;

Returns an array of DBIx::MyParse::Items from the query, in effect 
flatttening the parse tree.


=head2 renameTable

    $query->renameTable( 'old_name', 'new_name' );

Calls getItems and calls renameTable on each of the items.  All 
occurences of 'old_name' are changed to 'new_name'.


=head2 EXPORT

None by default.

=head1 SEE ALSO

L<DBIx::MyParse>, L<DBIx::MyParse::Query>, L<DBIx::MyParseX>,

L<http://www.mysql.com>

L<http://www.opendatagroup.com>


=head1 AUTHOR

Christopher Brown, E<lt>ctbrown@cpan.org<gt>
  
=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Open Data Group

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public Licence.  

=cut
