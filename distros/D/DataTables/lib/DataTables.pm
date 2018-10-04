package DataTables;

use 5.008008;
use strict;
use warnings;

use Carp;
use CGI::Simple;
use DBI;
use JSON::XS;
use SQL::Abstract::Limit;
use JQuery::DataTables::Request;

our $VERSION = '0.07';

# Preloaded methods go here.

sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
        tables  => undef,
        columns   => undef,
        dbh => undef,
        query => CGI::Simple->new,
        patterns  => {},
        join_clause  => '',
        where_clause  => '',
        @_,                 # Override previous attributes
    };
    return bless $self, $class;
}




sub tables {
    my $self = shift;
    
    if (@_) {
        my $a_ref = shift;
        croak "tables must be an array ref" unless UNIVERSAL::isa($a_ref,'ARRAY');
        $self->{tables} = $a_ref;
    }
    return $self->{tables};
}




sub columns {
    my $self = shift;
    
    if (@_) {
        my $ref = shift;
        croak "columns_a must be an array or hash ref" unless UNIVERSAL::isa($ref,'ARRAY') or UNIVERSAL::isa($ref,'HASH');
        $self->{columns} = $ref;
    }
    return $self->{columns};
}




sub dbh {
    my $self = shift;
    
    if (@_) {
        my $ref = shift;
        croak "dbh must be a DBI object" unless UNIVERSAL::can($ref,'prepare');
        $self->{dbh} = $ref;
    }
    return $self->{dbh};
}




sub patterns {
    my $self = shift;
    
    if (@_) {
        my $h_ref = shift;
        croak "patterns must be a hash ref" unless UNIVERSAL::isa($h_ref,'HASH');
        $self->{patterns} = $h_ref;
    }
    return $self->{patterns};
}




sub join_clause {
    my $self = shift;
    
    if (@_) {
        $self->{join_clause} = shift;
    }
    return $self->{join_clause};
}




sub where_clause {
    my $self = shift;
    
    if (@_) {
        $self->{where_clause} = shift;
    }
    return $self->{where_clause};
}




sub _columns_arr { 
    my $self = shift;
    my $aColumns;
    my $regular_columns;
    my $as_hash;
    my $tables_hash;

    if(UNIVERSAL::isa($self->columns,'HASH')) { 
        my $columns = $self->columns;

        for my $key (sort {$a <=> $b} keys %{$columns}) { #here we sort by key so columns show in the same order as they on the page
            my $as_exists = undef;

            #if two keys, we assume user passed in AS as a key. We could check for as below in loop, but that limits users from having a column named AS
            if(scalar(keys %{$columns->{$key}} == 2) and exists $columns->{$key}->{'AS'}) { 
                $as_exists = $columns->{$key}->{'AS'};
                delete $columns->{$key}->{'AS'};
            }

            while(my ($column,$table) = each %{$columns->{$key}}) {
                my $column_name = "$table.$column"; 
                push @{$aColumns}, $column_name;    
                
                if($as_exists) {
                    $as_hash->{$column_name} = $as_exists if $as_exists; #add 'AS' value for this column if one exists
                    $column = $as_exists; # we want to change the column name to what it will be selected as out of database so we can do correct pattern matching
                }

                $tables_hash->{$table} = 1;
                push @{$regular_columns}, $column;    
            }
        }    

        my @tables = keys %$tables_hash;
        $self->tables(\@tables);
    }
    elsif(UNIVERSAL::isa($self->columns,'ARRAY')) { 
        $aColumns = $self->columns; 
        $regular_columns = $aColumns;
    }
    else { 
        croak "columns must be a hash or an array ref";
    }

    return ($aColumns,$regular_columns,$as_hash);
}




sub print_json { 
    my $self = shift;
    my $json = $self->json;

    print "Content-type: application/json\n\n";
    print $json;
}




sub table_data {
    my $self = shift;
    
    my %all_query_parameters = $self->_get_query_parameters();
    
    # may croak if client_params isn't recognized as containing DataTables parameters
    my $dt_req = $self->_create_datatables_request( \%all_query_parameters );
    
    # DB HANDLE
    my $dbh = $self->{dbh};
    croak "Database handle not defined" unless defined $dbh;

    #columns to use
    my ($aColumns,$regular_columns,undef) = $self->_columns_arr;

    # check table name(s)
    croak "Tables must be provided for the FROM clause" unless $self->tables;

    #filtering
    my $where_href = $self->_generate_where_clause($dt_req);
    
    #ordering
    my @order = $self->_generate_order_clause($dt_req);

    #paging
    my $limit = $dt_req->length || 10;
    my $offset = $dt_req->start || 0;

    #join
    if($self->join_clause ne '') {
        $where_href = $self->_add_where_clause($where_href, $self->join_clause);
    }

    #SQL queries
    my $sql = SQL::Abstract::Limit->new( limit_dialect => $dbh );
    
    my ($sQuery, @bind) = $sql->select($self->tables, $aColumns, $where_href, \@order, $limit, $offset );
    #die("SQL: " . $sQuery);
	
    #get columns out of db with query we created
    my $result_sth = $dbh->prepare($sQuery);
    $result_sth->execute(@bind) or croak "error in mysql query: $!\n$sQuery";
    
    # Data set length after filtering
    my ($sQuery_cnt_filtered, @bind_cnt_filtered) = $sql->select($self->tables, 'COUNT(*)', $where_href );
    
    my $sth_cnt_filtered = $dbh->prepare($sQuery_cnt_filtered);
    $sth_cnt_filtered->execute(@bind_cnt_filtered) or croak "mysql error: $!";

    my @aResultFilterTotal = $sth_cnt_filtered->fetchrow_array();
    my $iFilteredTotal = $aResultFilterTotal[0];

    
    my $num_tables = scalar(@{$self->tables});

    my ($sQuery_cnt_total, @bind_cnt_total) = $sql->select($self->tables, 'COUNT(*)');
    my $sth_cnt_total = $dbh->prepare($sQuery_cnt_total);
    $sth_cnt_total->execute() or croak "error in query: $!\n$sQuery";

    my @aResultTotal = $sth_cnt_total->fetchrow_array;
    my $iTotal = $aResultTotal[0];

    # output hash
    my %output = ();
    my $sEcho = $dt_req->draw;
    my $version = $dt_req->version( \%all_query_parameters );
    
    
    if( $version eq '1.10' ) {
        # new interface
        
        %output = (
            "draw" => int($sEcho),
            "recordsTotal" => int($iTotal),
            "recordsFiltered" => int($iFilteredTotal),
            "aaData" => [],
        );
        
    }else{
        # old interface
        
        %output = (
            "sEcho" => int($sEcho),
            "iTotalRecords" => int($iTotal),
            "iTotalDisplayRecords" => int($iFilteredTotal),
            "aaData" => [],
        );
        
    }

    my $count = 0;
    my $patterns = $self->patterns;
    while(my @aRow = $result_sth->fetchrow_array) {
        my @row = ();
        for (my $i = 0; $i < @$aColumns; $i++) {
            my $pat_name = $regular_columns->[$i]; #get out the name that would be used in the pattern
            my $val = $aRow[$i];

            # apply user specified pattern for this column if one exists
            if(exists $patterns->{$pat_name}) { 
                my $pattern = $patterns->{$pat_name};
                $pattern =~ s/\[\%\s$pat_name\s\%\]/$val/g;
                $val = $pattern;
            }

            push @row, $val;
        }
        @{$output{'aaData'}}[$count] = [@row];
        $count++;
    }

    unless($count) {
        $output{'aaData'} = ''; #we don't want to have 'null'. will break js
    }

    return \%output;
} # /table_data




sub json {
    my $self = shift;

    my $output_href = $self->table_data;

    return encode_json $output_href;
} # /json




sub _create_datatables_request {
    my $self = shift;
    my $query_params = shift;
    return JQuery::DataTables::Request->new( client_params => $query_params );
}




sub _generate_where_clause {
    my $self = shift;
    my $dt_req = shift;
    
    my ($aColumns,undef,undef) = $self->_columns_arr;
    
    my $where_href = {};
    
    if( $dt_req->search && defined $dt_req->search->{value} ) {
        my $search_string = $dt_req->search->{value}; # the global search value
        
        # XXX: maybe use $dt_req->columns()?
		for( my $i = 0; $i < @$aColumns; $i++ ) {
			# Iterate over each column and check if it is searchable.
			# If so, add a constraint to the where clause restricting the given
			# column. In the query, the column is identified by it's index, we
			# need to translates the index to the column name.
			if ( defined $dt_req->column($i) and $dt_req->column($i)->{searchable} ) {
                # XXX: maybe use $dt_req->column($i)->{name}?
                my $column = $aColumns->[$i];
				push @{$where_href->{'-or'}}, { $column => {-like => '%'.$search_string.'%' } };
            }
		}
	}

    # XXX: merge with previous loop
    #individual column filtering
    for (my $i = 0; $i < @$aColumns; $i++) {
        if( defined $dt_req->column($i) and $dt_req->column($i)->{searchable}
           and ($dt_req->column($i)->{search}->{value} and $dt_req->column($i)->{search}->{value} ne '') ) {
            my $individual_column_search = $dt_req->column($i)->{search}->{value};
            $where_href->{$aColumns->[$i]} = {-like => '%'.$individual_column_search.'%'};
        }
    }

    # add user where if given
    if( $self->where_clause ) {
        $where_href = $self->_add_where_clause($where_href, $self->where_clause);
    }
    
    return $where_href;
} # /_generate_where_clause




=comment

convert
\%where = {key => value, -or => \@ }
to
\%where = {-and => [{key => value, -or => \@ }, $plus]}

$plus can be a hashref for SQL::Abstract.
$plus can also be scalarref (deprecated).

=cut

sub _add_where_clause {
    my $self = shift;
    my $existing_clauses_href = shift or croak('Missing where clause');
    my $new_clause = shift;
    
    return $existing_clauses_href unless $new_clause;
    
    if( UNIVERSAL::isa($new_clause, 'HASH') ) {
        return {
            -and => [
                $existing_clauses_href,
                $new_clause,
            ],
        };
    }
    
    # Add arbitrary WHERE clause. This might be dangerous.
    return {
        -and => [
            $existing_clauses_href,
            \$new_clause
        ],
    };
} # /_add_where_clause




sub _generate_order_clause {
    my $self = shift;
    my $dt_req = shift;
    
    my ($aColumns,undef,undef) = $self->_columns_arr;
    
    my @order = ();
    
    foreach my $order_instruction ( @{$dt_req->orders()} ) {
        
        # build direction, must be '-asc' or '-desc' (cf. SQL::Abstract)
        # we only get 'asc' or 'desc', so they have to be prefixed with '-'
        my $sortable_column_nr = $order_instruction->{column};
        my $direction =  '-' . $order_instruction->{dir};
        
        # We only get the column index (starting from 0), so we have to
        # translate the index into a column name.
        my $column_name = $aColumns->[$sortable_column_nr];
        push @order, { $direction => $column_name };
        
    }
    
    return @order;
} # /_generate_order_clause




sub _get_query_parameters {
    my $self = shift;

    # CGI OBJECT
    my $q = $self->{query};

    # TODO: available from Perl 5.20.0: get multiple key-value pairs in 1 request, e.g. my %new_hash = %hash{qw/a b/};
    # XXX: encapsulate to make testing easier (re-use the encapsulated method in tests instead of custom code)
    my %all_query_parameters = $q->Vars;
    
    return %all_query_parameters;
} # /_get_query_parameters

1; # /DataTables

__END__

=head1 NAME

DataTables - a server-side solution for the jQuery DataTables plugin

=head1 SYNOPSIS

  use DBI;
  use DataTables;
  my $dbh = DBI->connect('DBI:mysql:databasename:localhost:3306', 'username', 'password') or die("Could not connect to database: $DBI::errstr");
  my $dt = DataTables->new(dbh => $dbh);

  #set table to select from
  $dt->tables(["dinosaurs"]);

  #set columns to select in same order as order of columns on page
  $dt->columns(["height","size","lovability"]);                  

  #print json back to browser
  $dt->print_json;                                               

  #if you wish to do something with the json yourself
  my $json = $dt->json;                                        

  # EXAMPLE WITH JOINS

  # Assume the following two tables:
  
  ----------        ------------
  |  pets  |        |  owners  |
  ----------        ------------
   id               id
   name             name
   owner_id         

  # Now we will join the tables on owners.id=pets.owner_id

  # the first key is a number because
  # order must be kept to match column order
  my %columns = (
                   0=>{"name"=>"owners"},
                   1=>{"name"=>"pets", AS=>"pet_name"}, # renaming isn't necessary here, unless you wish to use patterns
                );

  $dt->columns(\%columns);

  $dt->join_clause("owners.id=pets.owner_id");

  $dt->print_json;

  # Assume in the example above we know that all pets love scooby snacks, and we'd like to represent
  # that in our output. We can do that like so:
  my %patterns = ( 
                      "pet_name"=>"[% pet_name %] loves scooby snacks!", 
                 );
                 # notice if we didn't rename pets.name as "pet_name" in the example above
                 # and we had used name for both owners and pets, both
                 # columns would receive this pattern

  $dt->patterns(\%patterns);

  $dt->print_json;

  # A more realistic example might be putting a '$' before a money value,
  # but personally I find the scooby snacks example more useful

  # NOTE: Any getter/setter method can be set initially when creating the DataTables object can be passed into new()

=head1 DESCRIPTION

This module is an easy way to integrate server-side with the jQuery L<DataTables|http://datatables.net/> plugin. 
Currently this module is designed to work with legacy DataTables 1.9 and lower, and with DataTables 1.10. 
It supports basic features like displaying columns
from a single table, but also supports more advanced features such as:

=over

=item 1

Selecting columns from multiple tables via join

=item 2

Formatting output of returned columns

=item 3

Adding extra conditions to the where and join clauses

=item 4

Uses DBI place holders to help prevent SQL injection

=back

=head1 METHODS

=head2 new(...)

Creates and returns a new DataTables object.

    my $dt = DataTables->new();

DataTables has options that allow you to receive your data
exactly as you want it. Any of the method names below can be
used in your new declaration to help initialize your object.

Here is an explicit list of all of the options and their defaults:

    tables  => undef,
    columns   => undef,
    dbh  => undef,
    patterns  => {},
    join_clause  => '',
    where_clause  => '',

=head2 tables
    
    $dt->tables(["table1","table2"]);

This method allows you to set which tables you want to select
from in your SQL query. However, if you set "columns" to a
hashref and not an arrayref, there is no need to set "tables".

=head2 columns

Columns can take in an arrayref or a hashref.
    
Arrayref: 

    $dt->columns(["column1","column2"]);

OR if you are joining among multiple tables: 

    $dt->columns(["table1.column1","table2.column2"]);

Keep in mind that if you use the patterns feature of this module,
the column name given as the key of the pattern must match what you call
the column here. So if you put "table1.column1", you must identify
the pattern with that name. Also, you should list the columns in the 
order that they are on your page.

Hashref:

    my %columns = (
                        0=>{"column1"=>"table1"},
                        1=>{"column2"=>"table1"},
                        2=>{"column3"=>"table2", AS=>"new_col"},
                    );
    $dt->columns(\%columns);

Here the numbers are necessary because hashes don't keep order,
so you must use numbers in order to specify the ordering of the
columns on the page. The AS key allows you to specify what you would
like to call that column (this relates to the SQL "AS" feature).
This could be useful if you wanted to use the patterns feature
of this module and had two columns in different tables named the same
thing, because then they would both get the pattern! Also, if you
provide a hashref for "columns", there is no need to supply the
tables; DataTables will figure that out for you.

=head2 patterns

    $dt->patterns({"column1"=>"[% column1 %] rocks!"});

This method sets the patterns that you want to use for
particular columns. You identify the pattern by using the column
as a key, and then specify where in your pattern you would like the
value to go by placing the name of the column between "[% %]".
The name of the column must be the name that you specified in
"columns". If you used a hashref in columns and specified the "AS" key,
then you must use the value for that "AS" key.

=head2 dbh

    $dt->dbh(DBI->connect(...));

Sets the database handle that should be used for the server-side requests.

=head2 join_clause

    $dt->join_clause("table1.id=table2.table1_id");

This lets you specify the condition that you want to join
on if you are joining multiple tables. You can extend it
with AND's and OR's if you wish.

=head2 where_clause

    $dt->where_clause("account_id=5");

This lets you specify extra conditions for the where clause,
if you feel you need to specify more than what DataTables already
does.

=head2 print_json

    $dt->print_json();

I recommend using this method to display the information
back to the browser once you've set up the DataTables object.
It not only prints the json out, but also takes care of printing
the content-type header back to the browser.

=head2 json

    my $json = $dt->json();
    print "Content-type: application/json\n\n";
    print $json;

The json() method returns the json to you that the jQuery DataTables plugin
is expecting. What I wrote above is essentially what the print_json() method does,
so I suggest that you just use that.

=head1 REQUIRES

=over

=item 1 L<DBI>

=item 2 L<JSON::XS>

=item 3 L<CGI::Simple>

=item 4 L<SQL::Abstract::Limit>

=item 5 L<JQuery::DataTables::Request>

=back

=head2 EXPORT

This module has no exportable functions.

=head1 ERRORS

If there is an error, it will not be reported client side. You will have to check
your web server logs to see what went wrong.

=head1 SEE ALSO

L<DataTables jQuery Plugin|http://datatables.net/>

L<JQuery::DataTables::Request>, a library for handling DataTables request parameters.

=head1 AUTHOR

Adam Hopkins <lt>srchulo@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Adam Hopkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
