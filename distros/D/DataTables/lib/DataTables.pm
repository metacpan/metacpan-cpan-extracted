package DataTables;

use 5.008008;
use strict;
use warnings;

use AutoLoader qw(AUTOLOAD);

use Carp;
use CGI;
use DBI;
use JSON::XS;

our $VERSION = '0.03';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
        tables  => undef,
        columns   => undef,
        user  => undef,
        pass  => undef,
        db  => undef,
        host  => "localhost",
        port  => "3306",
        patterns  => {},
        join_clause  => '',
        where_clause  => '',
        index_col  => "id",
        index_cols => undef,
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

sub index_cols {
    my $self = shift;
    
    if (@_) {
        my $h_ref = shift;
        croak "index_cols must be a hash ref" unless UNIVERSAL::isa($h_ref,'HASH');
        $self->{index_cols} = $h_ref;
    }
    return $self->{index_cols};
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

sub user {
    my $self = shift;
    
    if (@_) {
        $self->{user} = shift;
    }
    return $self->{user};
}

sub pass {
    my $self = shift;
    
    if (@_) {
        $self->{pass} = shift;
    }
    return $self->{pass};
}

sub db {
    my $self = shift;
    
    if (@_) {
        $self->{db} = shift;
    }
    return $self->{db};
}

sub host {
    my $self = shift;
    
    if (@_) {
        $self->{host} = shift;
    }
    return $self->{host};
}

sub port {
    my $self = shift;
    
    if (@_) {
        $self->{port} = shift;
    }
    return $self->{port};
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

sub index_col {
    my $self = shift;
    
    if (@_) {
        $self->{index_col} = shift;
    }
    return $self->{index_col};
}

#for some values in the query we build we can't use
#placeholders because they add quotes when they shouldn't.
#So here we use $dbh->quote() to escape these string then we remove
# the ''. Not as good as placeholders, but we need something
sub _special_quote { 
    my ($dbh,$string) = (@_);
    my $ns = $dbh->quote($string);
    $ns = substr $ns, 1;
    $ns= substr $ns, 0,-1;
    return $ns;
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

sub json {     
    use strict;
    my $self = shift;

    # CGI OBJECT
    my $q = new CGI;

    # DB CONFIG VARIABLES
    my $platform = "mysql";
    my $database = $self->{db};
    my $host = $self->{host};
    my $port = $self->{port};
    my $user = $self->{user};
    my $pw = $self->{pass};

    #DATA SOURCE NAME
    my $dsn = "dbi:mysql:$database:$host:3306";

    # get database handle
    my $dbh = DBI->connect($dsn, $user, $pw) or croak "couldn't connect to database: $!";

    #columns to use
    my ($aColumns,$regular_columns,$as_hash) = $self->_columns_arr;

    #this bind array is used for secure database queries
    #in an effort to help prevent sql injection
    my @bind = ();

    croak "Tables must be provided for the FROM clause" unless $self->tables;
    my $sTable = join ",",@{$self->tables};

    #filtering
    my $sWhere = "";
    if ($q->param('sSearch') ne '') {
        $sWhere = "WHERE (";
                
        for(my $i = 0; $i < @$aColumns; $i++) {
            my $search = $q->param('sSearch');
            $search = _special_quote($dbh,$search);
            $sWhere .= "" . $aColumns->[$i] . " LIKE '%$search%' OR ";
        }
                                    
        $sWhere = substr $sWhere,0,-3;
        $sWhere .= ')';
    }

    #individual column filtering
    for (my $i = 0; $i < @$aColumns; $i++) {
        if($q->param('bSearchable_' . $i) ne '' and $q->param('bSearchable_' . $i) eq "true" and $q->param('sSearch_' . $i) ne '') {
            if($sWhere eq "") {
                $sWhere = "WHERE ";
            }
            else {
                $sWhere .= " AND ";
            }
            my $search = $q->param('sSearch_' . $i);
            $search = _special_quote($dbh,$search);
            $sWhere .= "" . $aColumns->[$i] . " LIKE '%$search%' ";
        }
    }

    # add user where if given
    if($self->where_clause ne '') {
        if($sWhere eq "") {
            $sWhere = "WHERE ";
        }
        else {
            $sWhere .= " AND ";
        }
        $sWhere .= " " . $self->where_clause . " ";
    }

    #ordering
    my $sOrder = "";
    if($q->param('iSortCol_0') ne '') {
        $sOrder = "ORDER BY  ";
                    
        for(my $i = 0; $i < $q->param('iSortingCols'); $i++) {
            if($q->param('bSortable_' . $q->param('iSortCol_'.$i)) eq "true") {
                  my $sort_col = $aColumns->[$q->param('iSortCol_' . $i)];
                  my $sort_dir = $q->param('sSortDir_' . $i);
                                                                                
                # cannot use bind because bind puts '' around values.
                # backslash out quotes
                $sort_col = _special_quote($dbh,$sort_col);
                $sort_dir = _special_quote($dbh,$sort_dir);
                                                                                                        
                $sOrder .= "" . $sort_col . " " . $sort_dir . ", ";
            }
        }
                            
        $sOrder = substr $sOrder,0,-2;
        if( $sOrder eq "ORDER BY" ) {
            $sOrder = "";
        }
    }

    #paging
    my $sLimit = "";
    if ($q->param('iDisplayStart') ne '' and $q->param('iDisplayLength') ne '-1') {
        $sLimit = "LIMIT ?,? ";
        push @bind,$q->param('iDisplayStart');
        push @bind,$q->param('iDisplayLength');
    }

    #join
    my $sJoin = '';
    if($self->join_clause ne '') {
        if($sWhere ne '') {
            $sJoin .= ' AND ';
        }
        elsif($sWhere eq '') {
            $sWhere = ' WHERE ';
        }
        $sJoin .= ' ' . $self->join_clause . ' ';
    }

    #SQL queries
    #get data to display
    my $cols = join ", ", @{$aColumns};
    my $sQuery = "SELECT SQL_CALC_FOUND_ROWS " . $cols . " FROM $sTable $sWhere $sJoin $sOrder $sLimit ";

    #get columns out of db with query we created
    my $result_sth = $dbh->prepare($sQuery);
    $result_sth->execute(@bind) or croak "error in mysql query: $!\n$sQuery";

    # Data set length after filtering
    $sQuery = " SELECT FOUND_ROWS() ";
        
    my $sth = $dbh->prepare($sQuery);
    $sth->execute() or croak "mysql error: $!";

    my @aResultFilterTotal = $sth->fetchrow_array();
    my $iFilteredTotal = $aResultFilterTotal[0];

    my $iTotal = 0;

    my $num_tables = scalar(@{$self->tables});
    my $index_h = $self->index_cols;

    for my $table(@{$self->tables}) {
        my $sIndexColumn = '';
        if($num_tables == 1) { 
            $sIndexColumn = $self->index_col;
        }
        else { 
            $sIndexColumn = $index_h->{$table};
            $sIndexColumn = "id" unless $sIndexColumn;
        }
        # Total data set length 
        $sQuery = " SELECT COUNT(`" . $sIndexColumn . "`) FROM   $table ";

        $sth = $dbh->prepare($sQuery);
        $sth->execute() or croak "error in query: $!\n$sQuery\nMost likely related to index columns passed in";

        my @aResultTotal = $sth->fetchrow_array;
        $iTotal += $aResultTotal[0];
    }

    # output hash
    my %output = (
                 "sEcho" => $q->param('sEcho'),
                 "iTotalRecords" => $iTotal,
                    "iTotalDisplayRecords" => $iFilteredTotal,
                 "aaData" => ()
                   );

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

    return encode_json \%output;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DataTables - a server-side solution for the jQuery DataTables plugin

=head1 SYNOPSIS

  use DataTables;
  my $dt = DataTables->new(user=>'user',pass=>'pass',db=>'db'); #set inital values to connect to db

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

  my %index_cols = ( 
                        "pets"=>"id",
                        "owners"=>"id",
                   );

  $dt->columns(\%columns);
  $dt->index_cols(\%index_cols); #Not necessary to set index columns
                                 #since both index columns are id and this is what
                                 #DataTables defaults to

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
    user  => undef,
    pass  => undef,
    db  => undef,
    host  => "localhost",
    port  => "3306",
    patterns  => {},
    join_clause  => '',
    where_clause  => '',
    index_col  => "id",
    index_cols => undef,

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

=head2 index_cols

    $dt->index_cols({"table1"=>"index_col1","table2"=>"index_col2"});

Here you need to provide the indexed columns for all of the tables you 
are selecting from. However, if you do not provide an indexed column for a table,
DataTables will default to using "id". If you are only selecting from one table,
you can just use "index_col".

=head2 index_col

    $dt->index_col("id");

You can use this to set your indexed column if you are only selecting from one
table. It defaults to "id".

=head2 patterns

    $dt->patterns({"column1"=>"[% column1 %] rocks!"});

This method sets the patterns that you want to use for
particular columns. You identify the pattern by using the column
as a key, and then specify where in your pattern you would like the
value to go by placing the name of the column between "[% %]".
The name of the column must be the name that you specified in
"columns". If you used a hashref in columns and specified the "AS" key,
then you must use the value for that "AS" key.

=head2 user

    $dt->user("user");

Sets the user for the database.

=head2 pass

    $dt->pass("password");

Sets the password for the database.

=head2 db

    $dt->db("database");

Sets the database to use.

=head2 host

    $dt->host("localhost");

Sets the host to connet to for the database. Defaults to localhost.

=head2 port

    $dt->port("3306");

Sets the port to connect on for the database. Defaults to 3306.

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

=item 3 L<CGI>

=back

=head2 EXPORT

This module has no exportable functions.

=head1 ERRORS

If there is an error, it will not be reported client side. You will have to check
your web server logs to see what went wrong.

=head1 SEE ALSO

L<DataTables jQuery Plugin|http://datatables.net/>

=head1 AUTHOR

Adam Hopkins <lt>srchulo@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Adam Hopkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
