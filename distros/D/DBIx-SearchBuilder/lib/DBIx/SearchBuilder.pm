
package DBIx::SearchBuilder;

use strict;
use warnings;

our $VERSION = "1.67";

use Clone qw();
use Encode qw();
use Scalar::Util qw(blessed);
use DBIx::SearchBuilder::Util qw/ sorted_values /;

=head1 NAME

DBIx::SearchBuilder - Encapsulate SQL queries and rows in simple perl objects

=head1 SYNOPSIS

  use DBIx::SearchBuilder;
  
  package My::Things;
  use base qw/DBIx::SearchBuilder/;
  
  sub _Init {
      my $self = shift;
      $self->Table('Things');
      return $self->SUPER::_Init(@_);
  }
  
  sub NewItem {
      my $self = shift;
      # MyThing is a subclass of DBIx::SearchBuilder::Record
      return(MyThing->new);
  }
  
  package main;

  use DBIx::SearchBuilder::Handle;
  my $handle = DBIx::SearchBuilder::Handle->new();
  $handle->Connect( Driver => 'SQLite', Database => "my_test_db" );

  my $sb = My::Things->new( Handle => $handle );

  $sb->Limit( FIELD => "column_1", VALUE => "matchstring" );

  while ( my $record = $sb->Next ) {
      print $record->my_column_name();
  }

=head1 DESCRIPTION

This module provides an object-oriented mechanism for retrieving and updating data in a DBI-accesible database. 

In order to use this module, you should create a subclass of C<DBIx::SearchBuilder> and a 
subclass of C<DBIx::SearchBuilder::Record> for each table that you wish to access.  (See
the documentation of C<DBIx::SearchBuilder::Record> for more information on subclassing it.)

Your C<DBIx::SearchBuilder> subclass must override C<NewItem>, and probably should override
at least C<_Init> also; at the very least, C<_Init> should probably call C<_Handle> and C<_Table>
to set the database handle (a C<DBIx::SearchBuilder::Handle> object) and table name for the class.
You can try to override just about every other method here, as long as you think you know what you
are doing.

=head1 METHOD NAMING

Each method has a lower case alias; '_' is used to separate words.
For example, the method C<RedoSearch> has the alias C<redo_search>.

=head1 METHODS

=cut


=head2 new

Creates a new SearchBuilder object and immediately calls C<_Init> with the same parameters
that were passed to C<new>.  If you haven't overridden C<_Init> in your subclass, this means
that you should pass in a C<DBIx::SearchBuilder::Handle> (or one of its subclasses) like this:

   my $sb = My::DBIx::SearchBuilder::Subclass->new( Handle => $handle );

However, if your subclass overrides _Init you do not need to take a Handle argument, as long
as your subclass returns an appropriate handle object from the C<_Handle> method.  This is
useful if you want all of your SearchBuilder objects to use a shared global handle and don't want
to have to explicitly pass it in each time, for example.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );
    $self->_Init(@_);
    return ($self);
}



=head2 _Init

This method is called by C<new> with whatever arguments were passed to C<new>.  
By default, it takes a C<DBIx::SearchBuilder::Handle> object as a C<Handle>
argument, although this is not necessary if your subclass overrides C<_Handle>.

=cut

sub _Init {
    my $self = shift;
    my %args = ( Handle => undef,
                 @_ );
    $self->_Handle( $args{'Handle'} );

    $self->CleanSlate();
}



=head2 CleanSlate

This completely erases all the data in the SearchBuilder object. It's
useful if a subclass is doing funky stuff to keep track of a search and
wants to reset the SearchBuilder data without losing its own data;
it's probably cleaner to accomplish that in a different way, though.

=cut

sub CleanSlate {
    my $self = shift;
    $self->RedoSearch();
    $self->{'itemscount'}       = 0;
    $self->{'limit_clause'}     = "";
    $self->{'order'}            = "";
    $self->{'alias_count'}      = 0;
    $self->{'first_row'}        = 0;
    $self->{'must_redo_search'} = 1;
    $self->{'show_rows'}        = 0;
    $self->{'joins_are_distinct'} = undef;
    @{ $self->{'aliases'} } = ();

    delete $self->{$_} for qw(
        items
        left_joins
        raw_rows
        count_all
        subclauses
        restrictions
        _open_parens
        _close_parens
        group_by
        columns
        query_hint
    );

    #we have no limit statements. DoSearch won't work.
    $self->_isLimited(0);
}

=head2 Clone

Returns copy of the current object with all search restrictions.

=cut

sub Clone
{
    my $self = shift;

    my $obj = bless {}, ref($self);
    %$obj = %$self;

    delete $obj->{$_} for qw(
        items
    );
    $obj->{'must_redo_search'} = 1;
    $obj->{'itemscount'}       = 0;
    
    $obj->{ $_ } = Clone::clone( $obj->{ $_ } )
        foreach grep exists $self->{ $_ }, $self->_ClonedAttributes;
    return $obj;
}

=head2 _ClonedAttributes

Returns list of the object's fields that should be copied.

If your subclass store references in the object that should be copied while
clonning then you probably want override this method and add own values to
the list.

=cut

sub _ClonedAttributes
{
    return qw(
        aliases
        left_joins
        subclauses
        restrictions
        order_by
        group_by
        columns
        query_hint
    );
}



=head2 _Handle  [DBH]

Get or set this object's DBIx::SearchBuilder::Handle object.

=cut

sub _Handle {
    my $self = shift;
    if (@_) {
        $self->{'DBIxHandle'} = shift;
    }
    return ( $self->{'DBIxHandle'} );
}

=head2 _DoSearch

This internal private method actually executes the search on the database;
it is called automatically the first time that you actually need results
(such as a call to C<Next>).

=cut

sub _DoSearch {
    my $self = shift;

    my $QueryString = $self->BuildSelectQuery();

    # If we're about to redo the search, we need an empty set of items and a reset iterator
    delete $self->{'items'};
    $self->{'itemscount'} = 0;

    my $records = $self->_Handle->SimpleQuery($QueryString);
    return 0 unless $records;

    while ( my $row = $records->fetchrow_hashref() ) {
	my $item = $self->NewItem();
	$item->LoadFromHash($row);
	$self->AddRecord($item);
    }
    return $self->_RecordCount if $records->err;

    $self->{'must_redo_search'} = 0;

    return $self->_RecordCount;
}


=head2 AddRecord RECORD

Adds a record object to this collection.

=cut

sub AddRecord {
    my $self = shift;
    my $record = shift;
    push @{$self->{'items'}}, $record;
}

=head2 _RecordCount

This private internal method returns the number of Record objects saved
as a result of the last query.

=cut

sub _RecordCount {
    my $self = shift;
    return 0 unless defined $self->{'items'};
    return scalar @{ $self->{'items'} };
}



=head2 _DoCount

This internal private method actually executes a counting operation on the database;
it is used by C<Count> and C<CountAll>.

=cut


sub _DoCount {
    my $self = shift;
    my $all  = shift || 0;

    my $QueryString = $self->BuildSelectCountQuery();
    my $records     = $self->_Handle->SimpleQuery($QueryString);
    return 0 unless $records;

    my @row = $records->fetchrow_array();
    return 0 if $records->err;

    $self->{ $all ? 'count_all' : 'raw_rows' } = $row[0];

    return ( $row[0] );
}



=head2 _ApplyLimits STATEMENTREF

This routine takes a reference to a scalar containing an SQL statement. 
It massages the statement to limit the returned rows to only C<< $self->RowsPerPage >>
rows, skipping C<< $self->FirstRow >> rows.  (That is, if rows are numbered
starting from 0, row number C<< $self->FirstRow >> will be the first row returned.)
Note that it probably makes no sense to set these variables unless you are also
enforcing an ordering on the rows (with C<OrderByCols>, say).

=cut


sub _ApplyLimits {
    my $self = shift;
    my $statementref = shift;
    $self->_Handle->ApplyLimits($statementref, $self->RowsPerPage, $self->FirstRow);
    $$statementref =~ s/main\.\*/join(', ', @{$self->{columns}})/eg
	    if $self->{columns} and @{$self->{columns}};
}


=head2 _DistinctQuery STATEMENTREF

This routine takes a reference to a scalar containing an SQL statement. 
It massages the statement to ensure a distinct result set is returned.

=cut

sub _DistinctQuery {
    my $self = shift;
    my $statementref = shift;

    # XXX - Postgres gets unhappy with distinct and OrderBy aliases
    $self->_Handle->DistinctQuery($statementref, $self)
}

=head2 _BuildJoins

Build up all of the joins we need to perform this query.

=cut


sub _BuildJoins {
    my $self = shift;

        return ( $self->_Handle->_BuildJoins($self) );

}


=head2 _isJoined 

Returns true if this SearchBuilder will be joining multiple tables together.

=cut

sub _isJoined {
    my $self = shift;
    if ( keys %{ $self->{'left_joins'} } ) {
        return (1);
    } else {
        return (@{ $self->{'aliases'} });
    }

}




# LIMIT clauses are used for restricting ourselves to subsets of the search.



sub _LimitClause {
    my $self = shift;
    my $limit_clause;

    if ( $self->RowsPerPage ) {
        $limit_clause = " LIMIT ";
        if ( $self->FirstRow != 0 ) {
            $limit_clause .= $self->FirstRow . ", ";
        }
        $limit_clause .= $self->RowsPerPage;
    }
    else {
        $limit_clause = "";
    }
    return $limit_clause;
}



=head2 _isLimited

If we've limited down this search, return true. Otherwise, return false.

=cut

sub _isLimited {
    my $self = shift;
    if (@_) {
        $self->{'is_limited'} = shift;
    }
    else {
        return ( $self->{'is_limited'} );
    }
}




=head2 BuildSelectQuery

Builds a query string for a "SELECT rows from Tables" statement for this SearchBuilder object

=cut

sub BuildSelectQuery {
    my $self = shift;

    # The initial SELECT or SELECT DISTINCT is decided later

    my $QueryString = $self->_BuildJoins . " ";
    $QueryString .= $self->_WhereClause . " "
      if ( $self->_isLimited > 0 );

    my $QueryHint = $self->QueryHintFormatted;

    # DISTINCT query only required for multi-table selects
    # when we have group by clause then the result set is distinct as
    # it must contain only columns we group by or results of aggregate
    # functions which give one result per group, so we can skip DISTINCTing
    if ( my $clause = $self->_GroupClause ) {
        $QueryString = "SELECT" . $QueryHint . "main.* FROM $QueryString";
        $QueryString .= $clause;
        $QueryString .= $self->_OrderClause;
    }
    elsif ( !$self->{'joins_are_distinct'} && $self->_isJoined ) {
        $self->_DistinctQuery(\$QueryString);
    }
    else {
        $QueryString = "SELECT" . $QueryHint . "main.* FROM $QueryString";
        $QueryString .= $self->_OrderClause;
    }

    $self->_ApplyLimits(\$QueryString);

    return($QueryString)

}



=head2 BuildSelectCountQuery

Builds a SELECT statement to find the number of rows this SearchBuilder object would find.

=cut

sub BuildSelectCountQuery {
    my $self = shift;

    #TODO refactor DoSearch and DoCount such that we only have
    # one place where we build most of the querystring
    my $QueryString = $self->_BuildJoins . " ";

    $QueryString .= $self->_WhereClause . " "
      if ( $self->_isLimited > 0 );



    # DISTINCT query only required for multi-table selects
    if ($self->_isJoined) {
        $QueryString = $self->_Handle->DistinctCount(\$QueryString, $self);
    } else {
        my $QueryHint = $self->QueryHintFormatted;

        $QueryString = "SELECT" . $QueryHint . "count(main.id) FROM " . $QueryString;
    }

    return ($QueryString);
}




=head2 Next

Returns the next row from the set as an object of the type defined by sub NewItem.
When the complete set has been iterated through, returns undef and resets the search
such that the following call to Next will start over with the first item retrieved from the database.

=cut



sub Next {
    my $self = shift;
    my @row;

    return (undef) unless ( $self->_isLimited );

    $self->_DoSearch() if $self->{'must_redo_search'};

    if ( $self->{'itemscount'} < $self->_RecordCount ) {    #return the next item
        my $item = ( $self->{'items'}[ $self->{'itemscount'} ] );
        $self->{'itemscount'}++;
        return ($item);
    }
    else {    #we've gone through the whole list. reset the count.
        $self->GotoFirstItem();
        return (undef);
    }
}



=head2 GotoFirstItem

Starts the recordset counter over from the first item. The next time you call Next,
you'll get the first item returned by the database, as if you'd just started iterating
through the result set.

=cut


sub GotoFirstItem {
    my $self = shift;
    $self->GotoItem(0);
}




=head2 GotoItem

Takes an integer N and sets the record iterator to N.  The first time L</Next>
is called afterwards, it will return the Nth item found by the search.

You should only call GotoItem after you've already fetched at least one result
or otherwise forced the search query to run (such as via L</ItemsArrayRef>).
If GotoItem is called before the search query is ever run, it will reset the
item iterator and L</Next> will return the L</First> item.

=cut

sub GotoItem {
    my $self = shift;
    my $item = shift;
    $self->{'itemscount'} = $item;
}



=head2 First

Returns the first item

=cut

sub First {
    my $self = shift;
    $self->GotoFirstItem();
    return ( $self->Next );
}



=head2 Last

Returns the last item

=cut

sub Last {
    my $self = shift;
    $self->_DoSearch if $self->{'must_redo_search'};
    $self->GotoItem( ( $self->Count ) - 1 );
    return ( $self->Next );
}

=head2 DistinctFieldValues

Returns list with distinct values of field. Limits on collection
are accounted, so collection should be L</UnLimit>ed to get values
from the whole table.

Takes paramhash with the following keys:

=over 4

=item Field

Field name. Can be first argument without key.

=item Order

'ASC', 'DESC' or undef. Defines whether results should
be sorted or not. By default results are not sorted.

=item Max

Maximum number of elements to fetch.

=back

=cut

sub DistinctFieldValues {
    my $self = shift;
    my %args = (
        Field  => undef,
        Order  => undef,
        Max    => undef,
        @_%2 ? (Field => @_) : (@_)
    );

    my $query_string = $self->_BuildJoins;
    $query_string .= ' '. $self->_WhereClause
        if $self->_isLimited > 0;

    my $query_hint = $self->QueryHintFormatted;

    my $column = 'main.'. $args{'Field'};
    $query_string = "SELECT" . $query_hint . "DISTINCT $column FROM $query_string";

    if ( $args{'Order'} ) {
        $query_string .= ' ORDER BY '. $column
            .' '. ($args{'Order'} =~ /^des/i ? 'DESC' : 'ASC');
    }

    my $dbh = $self->_Handle->dbh;
    my $list = $dbh->selectcol_arrayref( $query_string, { MaxRows => $args{'Max'} } );
    return $list? @$list : ();
}



=head2 ItemsArrayRef

Return a refernece to an array containing all objects found by this search.

=cut

sub ItemsArrayRef {
    my $self = shift;

    #If we're not limited, return an empty array
    return [] unless $self->_isLimited;

    #Do a search if we need to.
    $self->_DoSearch() if $self->{'must_redo_search'};

    #If we've got any items in the array, return them.
    # Otherwise, return an empty array
    return ( $self->{'items'} || [] );
}




=head2 NewItem

NewItem must be subclassed. It is used by DBIx::SearchBuilder to create record 
objects for each row returned from the database.

=cut

sub NewItem {
    my $self = shift;

    die
"DBIx::SearchBuilder needs to be subclassed. you can't use it directly.\n";
}



=head2 RedoSearch

Takes no arguments.  Tells DBIx::SearchBuilder that the next time it's asked
for a record, it should requery the database

=cut

sub RedoSearch {
    my $self = shift;
    $self->{'must_redo_search'} = 1;
}




=head2 UnLimit

UnLimit clears all restrictions and causes this object to return all
rows in the primary table.

=cut

sub UnLimit {
    my $self = shift;
    $self->_isLimited(-1);
}



=head2 Limit

Limit takes a hash of parameters with the following keys:

=over 4

=item TABLE 

Can be set to something different than this table if a join is
wanted (that means we can't do recursive joins as for now).  

=item ALIAS

Unless ALIAS is set, the join criterias will be taken from EXT_LINKFIELD
and INT_LINKFIELD and added to the criterias.  If ALIAS is set, new
criterias about the foreign table will be added.

=item LEFTJOIN

To apply the Limit inside the ON clause of a previously created left
join, pass this option along with the alias returned from creating
the left join. ( This is similar to using the EXPRESSION option when
creating a left join but this allows you to refer to the join alias
in the expression. )

=item FIELD

Column to be checked against.

=item FUNCTION

Function that should be checked against or applied to the FIELD before
check. See L</CombineFunctionWithField> for rules.

=item VALUE

Should always be set and will always be quoted. 

=item OPERATOR

OPERATOR is the SQL operator to use for this phrase.  Possible choices include:

=over 4

=item "="

=item "!="

=item "LIKE"

In the case of LIKE, the string is surrounded in % signs.  Yes. this is a bug.

=item "NOT LIKE"

=item "STARTSWITH"

STARTSWITH is like LIKE, except it only appends a % at the end of the string

=item "ENDSWITH"

ENDSWITH is like LIKE, except it prepends a % to the beginning of the string

=item "MATCHES"

MATCHES is equivalent to the database's LIKE -- that is, it's actually LIKE, but
doesn't surround the string in % signs as LIKE does.

=item "IN" and "NOT IN"

VALUE can be an array reference or an object inherited from this class. If
it's not then it's treated as any other operator and in most cases SQL would
be wrong. Values in array are considered as constants and quoted according
to QUOTEVALUE.

If object is passed as VALUE then its select statement is used. If no L</Column>
is selected then C<id> is used, if more than one selected then warning is issued
and first column is used.

=back

=item ENTRYAGGREGATOR 

Can be C<AND> or C<OR> (or anything else valid to aggregate two clauses in SQL).
Special value is C<none> which means that no entry aggregator should be used.
The default value is C<OR>.

=item CASESENSITIVE

on some databases, such as postgres, setting CASESENSITIVE to 1 will make
this search case sensitive

=item SUBCLAUSE

Subclause allows you to assign tags to Limit statements.  Statements with
matching SUBCLAUSE tags will be grouped together in the final SQL statement.

Example:

Suppose you want to create Limit statments which would produce results
the same as the following SQL:

   SELECT * FROM Users WHERE EmailAddress OR Name OR RealName OR Email LIKE $query;

You would use the following Limit statements:

    $folks->Limit( FIELD => 'EmailAddress', OPERATOR => 'LIKE', VALUE => "$query", SUBCLAUSE => 'groupsearch');
    $folks->Limit( FIELD => 'Name', OPERATOR => 'LIKE', VALUE => "$query", SUBCLAUSE => 'groupsearch');
    $folks->Limit( FIELD => 'RealName', OPERATOR => 'LIKE', VALUE => "$query", SUBCLAUSE => 'groupsearch');

=back

=cut

sub Limit {
    my $self = shift;
    my %args = (
        TABLE           => $self->Table,
        ALIAS           => undef,
        FIELD           => undef,
        FUNCTION        => undef,
        VALUE           => undef,
        QUOTEVALUE      => 1,
        ENTRYAGGREGATOR => undef,
        CASESENSITIVE   => undef,
        OPERATOR        => '=',
        SUBCLAUSE       => undef,
        LEFTJOIN        => undef,
        @_    # get the real argumentlist
    );

    unless ( $args{'ENTRYAGGREGATOR'} ) {
        if ( $args{'LEFTJOIN'} ) {
            $args{'ENTRYAGGREGATOR'} = 'AND';
        } else {
            $args{'ENTRYAGGREGATOR'} = 'OR';
        }
    }


    #since we're changing the search criteria, we need to redo the search
    $self->RedoSearch();

    if ( $args{'OPERATOR'} ) {
        #If it's a like, we supply the %s around the search term
        if ( $args{'OPERATOR'} =~ /LIKE/i ) {
            $args{'VALUE'} = "%" . $args{'VALUE'} . "%";
        }
        elsif ( $args{'OPERATOR'} =~ /STARTSWITH/i ) {
            $args{'VALUE'}    = $args{'VALUE'} . "%";
        }
        elsif ( $args{'OPERATOR'} =~ /ENDSWITH/i ) {
            $args{'VALUE'}    = "%" . $args{'VALUE'};
        }
        elsif ( $args{'OPERATOR'} =~ /\bIN$/i ) {
            if ( blessed $args{'VALUE'} && $args{'VALUE'}->isa(__PACKAGE__) ) {
                # if no columns selected then select id
                local $args{'VALUE'}{'columns'} = $args{'VALUE'}{'columns'};
                unless ( $args{'VALUE'}{'columns'} ) {
                    $args{'VALUE'}->Column( FIELD => 'id' );
                } elsif ( @{ $args{'VALUE'}{'columns'} } > 1 ) {
                    warn "Collection in '$args{OPERATOR}' with more than one column selected, using first";
                    splice @{ $args{'VALUE'}{'columns'} }, 1;
                }
                $args{'VALUE'} = '('. $args{'VALUE'}->BuildSelectQuery .')';
                $args{'QUOTEVALUE'} = 0;
            }
            elsif ( ref $args{'VALUE'} ) {
                if ( $args{'QUOTEVALUE'} ) {
                    my $dbh = $self->_Handle->dbh;
                    $args{'VALUE'} = join ', ', map $dbh->quote( $_ ), @{ $args{'VALUE'} };
                } else {
                    $args{'VALUE'} = join ', ', @{ $args{'VALUE'} };
                }
                $args{'VALUE'} = "($args{VALUE})";
                $args{'QUOTEVALUE'} = 0;
            }
            else {
                # otherwise behave in backwards compatible way
            }
        }
        $args{'OPERATOR'} =~ s/(?:MATCHES|ENDSWITH|STARTSWITH)/LIKE/i;

        if ( $args{'OPERATOR'} =~ /IS/i ) {
            $args{'VALUE'} = 'NULL';
            $args{'QUOTEVALUE'} = 0;
        }
    }

    if ( $args{'QUOTEVALUE'} ) {
        #if we're explicitly told not to to quote the value or
        # we're doing an IS or IS NOT (null), don't quote the operator.

        $args{'VALUE'} = $self->_Handle->dbh->quote( $args{'VALUE'} );
    }

    my $Alias = $self->_GenericRestriction(%args);

    warn "No table alias set!"
      unless $Alias;

    # We're now limited. people can do searches.

    $self->_isLimited(1);

    if ( defined($Alias) ) {
        return ($Alias);
    }
    else {
        return (1);
    }
}



sub _GenericRestriction {
    my $self = shift;
    my %args = ( TABLE           => $self->Table,
                 FIELD           => undef,
                 FUNCTION        => undef,
                 VALUE           => undef,
                 ALIAS           => undef,
                 LEFTJOIN        => undef,
                 ENTRYAGGREGATOR => undef,
                 OPERATOR        => '=',
                 SUBCLAUSE       => undef,
                 CASESENSITIVE   => undef,
                 QUOTEVALUE     => undef,
                 @_ );

    #TODO: $args{'VALUE'} should take an array of values and generate
    # the proper where clause.

    #If we're performing a left join, we really want the alias to be the
    #left join criterion.

    if ( defined $args{'LEFTJOIN'} && !defined $args{'ALIAS'} ) {
        $args{'ALIAS'} = $args{'LEFTJOIN'};
    }

    # if there's no alias set, we need to set it

    unless ( $args{'ALIAS'} ) {

        #if the table we're looking at is the same as the main table
        if ( $args{'TABLE'} eq $self->Table ) {

            # TODO this code assumes no self joins on that table.
            # if someone can name a case where we'd want to do that,
            # I'll change it.

            $args{'ALIAS'} = 'main';
        }

        # if we're joining, we need to work out the table alias
        else {
            $args{'ALIAS'} = $self->NewAlias( $args{'TABLE'} );
        }
    }

    # Set this to the name of the field and the alias, unless we've been
    # handed a subclause name

    my $ClauseId = $args{'SUBCLAUSE'} || ($args{'ALIAS'} . "." . $args{'FIELD'});

    # If we're trying to get a leftjoin restriction, lets set
    # $restriction to point htere. otherwise, lets construct normally

    my $restriction;
    if ( $args{'LEFTJOIN'} ) {
        if ( $args{'ENTRYAGGREGATOR'} ) {
            $self->{'left_joins'}{ $args{'LEFTJOIN'} }{'entry_aggregator'} = 
                $args{'ENTRYAGGREGATOR'};
        }
        $restriction = $self->{'left_joins'}{ $args{'LEFTJOIN'} }{'criteria'}{ $ClauseId } ||= [];
    }
    else {
        $restriction = $self->{'restrictions'}{ $ClauseId } ||= [];
    }

    my $QualifiedField = $self->CombineFunctionWithField( %args );

    # If it's a new value or we're overwriting this sort of restriction,

    if ( $self->_Handle->CaseSensitive && defined $args{'VALUE'} && $args{'VALUE'} ne ''  && $args{'VALUE'} ne "''" && ($args{'OPERATOR'} !~/IS/ && $args{'VALUE'} !~ /^null$/i)) {

        unless ( $args{'CASESENSITIVE'} || !$args{'QUOTEVALUE'} ) {
               ( $QualifiedField, $args{'OPERATOR'}, $args{'VALUE'} ) =
                 $self->_Handle->_MakeClauseCaseInsensitive( $QualifiedField,
                $args{'OPERATOR'}, $args{'VALUE'} );
        }

    }

    my $clause = {
        field => $QualifiedField,
        op => $args{'OPERATOR'},
        value => $args{'VALUE'},
    };

    # Juju because this should come _AFTER_ the EA
    my @prefix;
    if ( $self->{_open_parens}{ $ClauseId } ) {
        @prefix = ('(') x delete $self->{_open_parens}{ $ClauseId };
    }

    if ( lc( $args{'ENTRYAGGREGATOR'} || "" ) eq 'none' || !@$restriction ) {
        @$restriction = (@prefix, $clause);
    }
    else {
        push @$restriction, $args{'ENTRYAGGREGATOR'}, @prefix, $clause;
    }

    return ( $args{'ALIAS'} );

}


sub _OpenParen {
    my ($self, $clause) = @_;
    $self->{_open_parens}{ $clause }++;
}

# Immediate Action
sub _CloseParen {
    my ( $self, $clause ) = @_;
    my $restriction = ($self->{'restrictions'}{ $clause } ||= []);
    push @$restriction, ')';
}


sub _AddSubClause {
    my $self      = shift;
    my $clauseid  = shift;
    my $subclause = shift;

    $self->{'subclauses'}{ $clauseid } = $subclause;

}



sub _WhereClause {
    my $self = shift;

    #Go through all the generic restrictions and build up the "generic_restrictions" subclause
    # That's the only one that SearchBuilder builds itself.
    # Arguably, the abstraction should be better, but I don't really see where to put it.
    $self->_CompileGenericRestrictions();

    #Go through all restriction types. Build the where clause from the
    #Various subclauses.
    my $where_clause = '';
    foreach my $subclause ( grep $_, sorted_values($self->{'subclauses'}) ) {
        $where_clause .= " AND " if $where_clause;
        $where_clause .= $subclause;
    }

    $where_clause = " WHERE " . $where_clause if $where_clause;

    return ($where_clause);
}


#Compile the restrictions to a WHERE Clause

sub _CompileGenericRestrictions {
    my $self = shift;

    my $result = '';
    #Go through all the restrictions of this type. Buld up the generic subclause
    foreach my $restriction ( grep @$_, sorted_values($self->{'restrictions'}) ) {
        $result .= " AND " if $result;
        $result .= '(';
        foreach my $entry ( @$restriction ) {
            unless ( ref $entry ) {
                $result .= ' '. $entry . ' ';
            }
            else {
                $result .= join ' ', @{$entry}{qw(field op value)};
            }
        }
        $result .= ')';
    }
    return ($self->{'subclauses'}{'generic_restrictions'} = $result);
}


=head2 OrderBy PARAMHASH

Orders the returned results by ALIAS.FIELD ORDER.

Takes a paramhash of ALIAS, FIELD and ORDER.  
ALIAS defaults to C<main>.
FIELD has no default value.
ORDER defaults to ASC(ending). DESC(ending) is also a valid value for OrderBy.

FIELD also accepts C<FUNCTION(FIELD)> format.

=cut

sub OrderBy {
    my $self = shift;
    $self->OrderByCols( { @_ } );
}

=head2 OrderByCols ARRAY

OrderByCols takes an array of paramhashes of the form passed to OrderBy.
The result set is ordered by the items in the array.

=cut

sub OrderByCols {
    my $self = shift;
    my @args = @_;

    $self->{'order_by'} = \@args;
    $self->RedoSearch();
}

=head2 _OrderClause

returns the ORDER BY clause for the search.

=cut

sub _OrderClause {
    my $self = shift;

    return '' unless $self->{'order_by'};

    my $nulls_order = $self->_Handle->NullsOrder;

    my $clause = '';
    foreach my $row ( @{$self->{'order_by'}} ) {

        my %rowhash = ( ALIAS => 'main',
			FIELD => undef,
			ORDER => 'ASC',
			%$row
		      );
        if ($rowhash{'ORDER'} && $rowhash{'ORDER'} =~ /^des/i) {
	    $rowhash{'ORDER'} = "DESC";
            $rowhash{'ORDER'} .= ' '. $nulls_order->{'DESC'} if $nulls_order;
        }
        else {
	    $rowhash{'ORDER'} = "ASC";
            $rowhash{'ORDER'} .= ' '. $nulls_order->{'ASC'} if $nulls_order;
        }
        $rowhash{'ALIAS'} = 'main' unless defined $rowhash{'ALIAS'};

        if ( defined $rowhash{'ALIAS'} and
	     $rowhash{'FIELD'} and
             $rowhash{'ORDER'} ) {

	    if ( length $rowhash{'ALIAS'} && $rowhash{'FIELD'} =~ /^(\w+\()(.*\))$/ ) {
		# handle 'FUNCTION(FIELD)' formatted fields
		$rowhash{'ALIAS'} = $1 . $rowhash{'ALIAS'};
		$rowhash{'FIELD'} = $2;
	    }

            $clause .= ($clause ? ", " : " ");
            $clause .= $rowhash{'ALIAS'} . "." if length $rowhash{'ALIAS'};
            $clause .= $rowhash{'FIELD'} . " ";
            $clause .= $rowhash{'ORDER'};
        }
    }
    $clause = " ORDER BY$clause " if $clause;

    return $clause;
}

=head2 GroupByCols ARRAY_OF_HASHES

Each hash contains the keys FIELD, FUNCTION and ALIAS. Hash
combined into SQL with L</CombineFunctionWithField>.

=cut

sub GroupByCols {
    my $self = shift;
    my @args = @_;

    $self->{'group_by'} = \@args;
    $self->RedoSearch();
}

=head2 _GroupClause

Private function to return the "GROUP BY" clause for this query.

=cut

sub _GroupClause {
    my $self = shift;
    return '' unless $self->{'group_by'};

    my $clause = '';
    foreach my $row ( @{$self->{'group_by'}} ) {
        my $part = $self->CombineFunctionWithField( %$row )
            or next;

        $clause .= ', ' if $clause;
        $clause .= $part;
    }

    return '' unless $clause;
    return " GROUP BY $clause ";
}

=head2 NewAlias

Takes the name of a table and paramhash with TYPE and DISTINCT.

Use TYPE equal to C<LEFT> to indicate that it's LEFT JOIN. Old
style way to call (see below) is also supported, but should be
B<avoided>:

    $records->NewAlias('aTable', 'left');

True DISTINCT value indicates that this join keeps result set
distinct and DB side distinct is not required. See also L</Join>.

Returns the string of a new Alias for that table, which can be used to Join tables
or to Limit what gets found by a search.

=cut

sub NewAlias {
    my $self  = shift;
    my $table = shift || die "Missing parameter";
    my %args = @_%2? (TYPE => @_) : (@_);

    my $type = $args{'TYPE'};

    my $alias = $self->_GetAlias($table);

    unless ( $type ) {
        push @{ $self->{'aliases'} }, "$table $alias";
    } elsif ( lc $type eq 'left' ) {
        my $meta = $self->{'left_joins'}{"$alias"} ||= {};
        $meta->{'alias_string'} = " LEFT JOIN $table $alias ";
        $meta->{'type'} = 'LEFT';
        $meta->{'depends_on'} = '';
    } else {
        die "Unsupported alias(join) type";
    }

    if ( $args{'DISTINCT'} && !defined $self->{'joins_are_distinct'} ) {
        $self->{'joins_are_distinct'} = 1;
    } elsif ( !$args{'DISTINCT'} ) {
        $self->{'joins_are_distinct'} = 0;
    }

    return $alias;
}



# _GetAlias is a private function which takes an tablename and
# returns a new alias for that table without adding something
# to self->{'aliases'}.  This function is used by NewAlias
# and the as-yet-unnamed left join code

sub _GetAlias {
    my $self  = shift;
    my $table = shift;

    $self->{'alias_count'}++;
    my $alias = $table . "_" . $self->{'alias_count'};

    return ($alias);

}



=head2 Join

Join instructs DBIx::SearchBuilder to join two tables.  

The standard form takes a param hash with keys ALIAS1, FIELD1, ALIAS2 and 
FIELD2. ALIAS1 and ALIAS2 are column aliases obtained from $self->NewAlias or
a $self->Limit. FIELD1 and FIELD2 are the fields in ALIAS1 and ALIAS2 that 
should be linked, respectively.  For this type of join, this method
has no return value.

Supplying the parameter TYPE => 'left' causes Join to preform a left join.
in this case, it takes ALIAS1, FIELD1, TABLE2 and FIELD2. Because of the way
that left joins work, this method needs a TABLE for the second field
rather than merely an alias.  For this type of join, it will return
the alias generated by the join.

Instead of ALIAS1/FIELD1, it's possible to specify EXPRESSION, to join
ALIAS2/TABLE2 on an arbitrary expression.

It is also possible to join to a pre-existing, already-limited
L<DBIx::SearchBuilder> object, by passing it as COLLECTION2, instead
of providing an ALIAS2 or TABLE2.

By passing true value as DISTINCT argument join can be marked distinct. If
all joins are distinct then whole query is distinct and SearchBuilder can
avoid L</_DistinctQuery> call that can hurt performance of the query. See
also L</NewAlias>.

=cut

sub Join {
    my $self = shift;
    my %args = (
        TYPE        => 'normal',
        FIELD1      => undef,
        ALIAS1      => 'main',
        TABLE2      => undef,
        COLLECTION2 => undef,
        FIELD2      => undef,
        ALIAS2      => undef,
        @_
    );

    $self->_Handle->Join( SearchBuilder => $self, %args );

}

=head2 Pages: size and changing

Use L</RowsPerPage> to set size of pages. L</NextPage>,
L</PrevPage>, L</FirstPage> or L</GotoPage> to change
pages. L</FirstRow> to do tricky stuff.

=head3 RowsPerPage

Get or set the number of rows returned by the database.

Takes an optional integer which restricts the # of rows returned
in a result. Zero or undef argument flush back to "return all
records matching current conditions".

Returns the current page size.

=cut

sub RowsPerPage {
    my $self = shift;

    if ( @_ && ($_[0]||0) != $self->{'show_rows'} ) {
        $self->{'show_rows'} = shift || 0;
        $self->RedoSearch;
    }

    return ( $self->{'show_rows'} );
}

=head3 NextPage

Turns one page forward.

=cut

sub NextPage {
    my $self = shift;
    $self->FirstRow( $self->FirstRow + 1 + $self->RowsPerPage );
}

=head3 PrevPage

Turns one page backwards.

=cut

sub PrevPage {
    my $self = shift;
    if ( ( $self->FirstRow - $self->RowsPerPage ) > 0 ) {
        $self->FirstRow( 1 + $self->FirstRow - $self->RowsPerPage );
    }
    else {
        $self->FirstRow(1);
    }
}

=head3 FirstPage

Jumps to the first page.

=cut

sub FirstPage {
    my $self = shift;
    $self->FirstRow(1);
}

=head3 GotoPage

Takes an integer number and jumps to that page or first page if
number omitted. Numbering starts from zero.

=cut

sub GotoPage {
    my $self = shift;
    my $page = shift || 0;

    $self->FirstRow( 1 + $self->RowsPerPage * $page );
}

=head3 FirstRow

Get or set the first row of the result set the database should return.
Takes an optional single integer argrument. Returns the currently set integer
minus one (this is historical issue).

Usually you don't need this method. Use L</RowsPerPage>, L</NextPage> and other
methods to walk pages. It only may be helpful to get 10 records starting from
5th.

=cut

sub FirstRow {
    my $self = shift;
    if (@_ && ($_[0]||1) != ($self->{'first_row'}+1) ) {
        $self->{'first_row'} = shift;

        #SQL starts counting at 0
        $self->{'first_row'}--;

        #gotta redo the search if changing pages
        $self->RedoSearch();
    }
    return ( $self->{'first_row'} );
}


=head2 _ItemsCounter

Returns the current position in the record set.

=cut

sub _ItemsCounter {
    my $self = shift;
    return $self->{'itemscount'};
}


=head2 Count

Returns the number of records in the set.

=cut

sub Count {
    my $self = shift;

    # An unlimited search returns no tickets    
    return 0 unless ($self->_isLimited);


    # If we haven't actually got all objects loaded in memory, we
    # really just want to do a quick count from the database.
    if ( $self->{'must_redo_search'} ) {

        # If we haven't already asked the database for the row count, do that
        $self->_DoCount unless ( $self->{'raw_rows'} );

        #Report back the raw # of rows in the database
        return ( $self->{'raw_rows'} );
    }

    # If we have loaded everything from the DB we have an
    # accurate count already.
    else {
        return $self->_RecordCount;
    }
}



=head2 CountAll

Returns the total number of potential records in the set, ignoring any
L</RowsPerPage> settings.

=cut

# 22:24 [Robrt(500@outer.space)] It has to do with Caching.
# 22:25 [Robrt(500@outer.space)] The documentation says it ignores the limit.
# 22:25 [Robrt(500@outer.space)] But I don't believe thats true.
# 22:26 [msg(Robrt)] yeah. I
# 22:26 [msg(Robrt)] yeah. I'm not convinced it does anything useful right now
# 22:26 [msg(Robrt)] especially since until a week ago, it was setting one variable and returning another
# 22:27 [Robrt(500@outer.space)] I remember.
# 22:27 [Robrt(500@outer.space)] It had to do with which Cached value was returned.
# 22:27 [msg(Robrt)] (given that every time we try to explain it, we get it Wrong)
# 22:27 [Robrt(500@outer.space)] Because Count can return a different number than actual NumberOfResults
# 22:28 [msg(Robrt)] in what case?
# 22:28 [Robrt(500@outer.space)] CountAll _always_ used the return value of _DoCount(), as opposed to Count which would return the cached number of 
#           results returned.
# 22:28 [Robrt(500@outer.space)] IIRC, if you do a search with a Limit, then raw_rows will == Limit.
# 22:31 [msg(Robrt)] ah.
# 22:31 [msg(Robrt)] that actually makes sense
# 22:31 [Robrt(500@outer.space)] You should paste this conversation into the CountAll docs.
# 22:31 [msg(Robrt)] perhaps I'll create a new method that _actually_ do that.
# 22:32 [msg(Robrt)] since I'm not convinced it's been doing that correctly


sub CountAll {
    my $self = shift;

    # An unlimited search returns no tickets    
    return 0 unless ($self->_isLimited);

    # If we haven't actually got all objects loaded in memory, we
    # really just want to do a quick count from the database.
    # or if we have paging enabled then we count as well and store it in count_all
    if ( $self->{'must_redo_search'} || ( $self->RowsPerPage && !$self->{'count_all'} ) ) {
        # If we haven't already asked the database for the row count, do that
        $self->_DoCount(1);

        #Report back the raw # of rows in the database
        return ( $self->{'count_all'} );
    }
    
    # if we have paging enabled and have count_all then return it
    elsif ( $self->RowsPerPage ) {
        return ( $self->{'count_all'} );
    }

    # If we have loaded everything from the DB we have an
    # accurate count already.
    else {
        return $self->_RecordCount;
    }
}


=head2 IsLast

Returns true if the current row is the last record in the set.

=cut

sub IsLast {
    my $self = shift;

    return undef unless $self->Count;

    if ( $self->_ItemsCounter == $self->Count ) {
        return (1);
    }
    else {
        return (0);
    }
}


=head2 Column

Call to specify which columns should be loaded from the table. Each
calls adds one column to the set.  Takes a hash with the following named
arguments:

=over 4

=item FIELD

Column name to fetch or apply function to.

=item ALIAS

Alias of a table the field is in; defaults to C<main>

=item FUNCTION

A SQL function that should be selected instead of FIELD or applied to it.

=item AS

The B<column> alias to use instead of the default.  The default column alias is
either the column's name (i.e. what is passed to FIELD) if it is in this table
(ALIAS is 'main') or an autogenerated alias.  Pass C<undef> to skip column
aliasing entirely.

=back

C<FIELD>, C<ALIAS> and C<FUNCTION> are combined according to
L</CombineFunctionWithField>.

If a FIELD is provided and it is in this table (ALIAS is 'main'), then
the column named FIELD and can be accessed as usual by accessors:

    $articles->Column(FIELD => 'id');
    $articles->Column(FIELD => 'Subject', FUNCTION => 'SUBSTR(?, 1, 20)');
    my $article = $articles->First;
    my $aid = $article->id;
    my $subject_prefix = $article->Subject;

Returns the alias used for the column. If FIELD was not provided, or was
from another table, then the returned column alias should be passed to
the L<DBIx::SearchBuilder::Record/_Value> method to retrieve the
column's result:

    my $time_alias = $articles->Column(FUNCTION => 'NOW()');
    my $article = $articles->First;
    my $now = $article->_Value( $time_alias );

To choose the column's alias yourself, pass a value for the AS parameter (see
above).  Be careful not to conflict with existing column aliases.

=cut

sub Column {
    my $self = shift;
    my %args = ( TABLE => undef,
               ALIAS => undef,
               FIELD => undef,
               FUNCTION => undef,
               @_);

    $args{'ALIAS'} ||= 'main';

    my $name = $self->CombineFunctionWithField( %args ) || 'NULL';

    my $column = $args{'AS'};

    if (not defined $column and not exists $args{'AS'}) {
        if (
            $args{FIELD} && $args{ALIAS} eq 'main'
            && (!$args{'TABLE'} || $args{'TABLE'} eq $self->Table )
        ) {
            $column = $args{FIELD};

            # make sure we don't fetch columns with duplicate aliases
            if ( $self->{columns} ) {
                my $suffix = " AS \L$column";
                if ( grep index($_, $suffix, -length $suffix) >= 0, @{ $self->{columns} } ) {
                    $column .= scalar @{ $self->{columns} };
                }
            }
        }
        else {
            $column = "col" . @{ $self->{columns} ||= [] };
        }
    }
    push @{ $self->{columns} ||= [] }, defined($column) ? "$name AS \L$column" : $name;
    return $column;
}

=head2 CombineFunctionWithField

Takes a hash with three optional arguments: FUNCTION, FIELD and ALIAS.

Returns SQL with all three arguments combined according to the following
rules.

=over 4

=item *

FUNCTION or undef returned when FIELD is not provided

=item *

'main' ALIAS is used if not provided

=item *

ALIAS.FIELD returned when FUNCTION is not provided

=item *

NULL returned if FUNCTION is 'NULL'

=item *

If FUNCTION contains '?' (question marks) then they are replaced with
ALIAS.FIELD and result returned.

=item *

If FUNCTION has no '(' (opening parenthesis) then ALIAS.FIELD is
appended in parentheses and returned.

=back

Examples:

    $obj->CombineFunctionWithField()
     => undef

    $obj->CombineFunctionWithField(FUNCTION => 'FOO')
     => 'FOO'

    $obj->CombineFunctionWithField(FIELD => 'foo')
     => 'main.foo'

    $obj->CombineFunctionWithField(ALIAS => 'bar', FIELD => 'foo')
     => 'bar.foo'

    $obj->CombineFunctionWithField(FUNCTION => 'FOO(?, ?)', FIELD => 'bar')
     => 'FOO(main.bar, main.bar)'

    $obj->CombineFunctionWithField(FUNCTION => 'FOO', ALIAS => 'bar', FIELD => 'baz')
     => 'FOO(bar.baz)'

    $obj->CombineFunctionWithField(FUNCTION => 'NULL', FIELD => 'bar')
     => 'NULL'

=cut



sub CombineFunctionWithField {
    my $self = shift;
    my %args = (
        FUNCTION => undef,
        ALIAS    => undef,
        FIELD    => undef,
        @_
    );

    unless ( $args{'FIELD'} ) {
        return $args{'FUNCTION'} || undef;
    }

    my $field = ($args{'ALIAS'} || 'main') .'.'. $args{'FIELD'};
    return $field unless $args{'FUNCTION'};

    my $func = $args{'FUNCTION'};
    if ( $func =~ /^DISTINCT\s*COUNT$/i ) {
        $func = "COUNT(DISTINCT $field)";
    }

    # If we want to substitute
    elsif ( $func =~ s/\?/$field/g ) {
        # no need to do anything, we already replaced
    }

    # If we want to call a simple function on the column
    elsif ( $func !~ /\(/ && lc($func) ne 'null' )  {
        $func = "\U$func\E($field)";
    }

    return $func;
}




=head2 Columns LIST

Specify that we want to load only the columns in LIST

=cut

sub Columns {
    my $self = shift;
    $self->Column( FIELD => $_ ) for @_;
}

=head2 AdditionalColumn

Calls L</Column>, but first ensures that this table's standard columns are
selected as well.  Thus, each call to this method results in an additional
column selected instead of replacing the default columns.

Takes a hash of parameters which is the same as L</Column>.  Returns the result
of calling L</Column>.

=cut

sub AdditionalColumn {
    my $self = shift;
    $self->Column( FUNCTION => "main.*", AS => undef )
        unless grep { /^\Qmain.*\E$/ } @{$self->{columns}};
    return $self->Column(@_);
}

=head2 Fields TABLE

Return a list of fields in TABLE.  These fields are in the case
presented by the database, which may be case-sensitive.

=cut

sub Fields {
    return (shift)->_Handle->Fields( @_ );
}


=head2 HasField  { TABLE => undef, FIELD => undef }

Returns true if TABLE has field FIELD.
Return false otherwise

Note: Both TABLE and FIELD are case-sensitive (See: L</Fields>)

=cut

sub HasField {
    my $self = shift;
    my %args = ( FIELD => undef,
                 TABLE => undef,
                 @_);

    my $table = $args{TABLE} or die;
    my $field = $args{FIELD} or die;
    return grep { $_ eq $field } $self->Fields($table);
}


=head2 Table [TABLE]

If called with an argument, sets this collection's table.

Always returns this collection's table.

=cut

sub Table {
    my $self = shift;
    $self->{table} = shift if (@_);
    return $self->{table};
}

=head2 QueryHint [Hint]

If called with an argument, sets a query hint for this collection.

Always returns the query hint.

When the query hint is included in the SQL query, the C</* ... */> will be
included for you. Here's an example query hint for Oracle:

    $sb->QueryHint("+CURSOR_SHARING_EXACT");

=cut

sub QueryHint {
    my $self = shift;
    $self->{query_hint} = shift if (@_);
    return $self->{query_hint};
}

=head2 QueryHintFormatted

Returns the query hint formatted appropriately for inclusion in SQL queries.

=cut

sub QueryHintFormatted {
    my $self = shift;
    my $QueryHint = $self->QueryHint;
    return $QueryHint ? " /* $QueryHint */ " : " ";
}

=head1 DEPRECATED METHODS

=head2 GroupBy

DEPRECATED. Alias for the L</GroupByCols> method.

=cut

sub GroupBy { (shift)->GroupByCols( @_ ) }

=head2 SetTable

DEPRECATED. Alias for the L</Table> method.

=cut

sub SetTable {
    my $self = shift;
    return $self->Table(@_);
}

=head2 ShowRestrictions

DEPRECATED AND DOES NOTHING.

=cut

sub ShowRestrictions { }

=head2 ImportRestrictions

DEPRECATED AND DOES NOTHING.

=cut

sub ImportRestrictions { }

# not even documented
sub DEBUG { warn "DEBUG is deprecated" }


if( eval { require capitalization } ) {
	capitalization->unimport( __PACKAGE__ );
}

1;
__END__



=head1 TESTING

In order to test most of the features of C<DBIx::SearchBuilder>, you need
to provide C<make test> with a test database.  For each DBI driver that you
would like to test, set the environment variables C<SB_TEST_FOO>, C<SB_TEST_FOO_USER>,
and C<SB_TEST_FOO_PASS> to a database name, database username, and database password,
where "FOO" is the driver name in all uppercase.  You can test as many drivers
as you like.  (The appropriate C<DBD::> module needs to be installed in order for
the test to work.)  Note that the C<SQLite> driver will automatically be tested if C<DBD::Sqlite>
is installed, using a temporary file as the database.  For example:

  SB_TEST_MYSQL=test SB_TEST_MYSQL_USER=root SB_TEST_MYSQL_PASS=foo \
    SB_TEST_PG=test SB_TEST_PG_USER=postgres  make test


=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-DBIx-SearchBuilder@rt.cpan.org|mailto:bug-DBIx-SearchBuilder@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-SearchBuilder>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2001-2014, Best Practical Solutions LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

DBIx::SearchBuilder::Handle, DBIx::SearchBuilder::Record.

=cut
