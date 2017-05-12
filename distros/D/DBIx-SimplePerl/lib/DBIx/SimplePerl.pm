package DBIx::SimplePerl;

use base qw(Class::Accessor);

use 5.008;
use strict;
use warnings;
no strict "subs";
no strict "refs";
use DBI;
use POSIX qw(strftime ceil);
use Data::Dumper;

use constant true 	=> (1==1);
use constant false 	=> (1==0);

our $VERSION = '1.95';


# Preloaded methods go here.
=pod
=head1 NAME

DBIx::SimplePerl - Perlish access to DBI

=head1 ABSTRACT


This module provides DBIx::SimplePerl which is a highly (over)simplified
interface to DBI.  The point of DBIx::SimplePerl is that end programmers
who  want to write their programs which access simple databases in
Perl, should be able to write their programs in Perl and not Perl +
SQL.  This is a different approach as compared to the Tie::DBI. 
This module is not what high end or midrange database programmers
would like or care to use.  It works great for really simple stuff,
like SADU (search, add, delete,  update) on existing tables.  It
follows a basic Keep It Simple(tm) philosophy, in that the
programmer ought to be able to use a database table with very
little effort.  Other modules attempt to make SQL access simple, but
in the end they rely on the user emitting SQL at some point.  This 
module hides the SQL from the end user by automatically generating it
in flight.  The idea being that Perl programmers who need very simple
database access do not necessarily need to write SQL.

=head1 SYNOPSIS

  # Brackets [] represent optional items, not array indices.
  # Elipses ... mean more of the same inputs/options
  
  use DBIx::SimplePerl;
  my $sice = DBIx::SimplePerl->new;
				 
  ...
  # all methods return a hash with two possible keys. 
  # On success, the return is
  #	{ success => true }
  # On failure, the return is
  #	{ failed  => { 
  #                    error => "error_message_from_call", 
  #                    code  => "error_return_code_from_call" 
  #                  } 
  #     }
  
  # sets internal $sice->{_dbh} to open database handle
  $sice->db_open(
  		 dsn => $dsn, 
		 dbuser => $dbuser, 
		 dbpass => $dbpass,
  		 [AutoCommit => 0|1,] 
		 [RaiseError => 0|1 ]
		 ... 
		);
  
  $sice->db_add(
                table 	=> $table_name,
		columns => {
			    field1	=> $data1,
			    [field2	=> $data2,]
			    [...]
			   }
               );
	       
  $sice->db_search(
  		   table => $table_name, 
		  [search => {
			      field1=>$data1, 
			     [field2=>@array2]
					 ...
			     }],
                 [ search_operator => 'AND' | 'OR' ]
 		 [ count 	=>  field ],
		 [ max   	=>  field ],
		 [ min   	=>  field ],
                 [ distinct     => { field1, 
		 		     [field2], ... ]
				    } ],
                 
		 [ columns 	=>  { field1, 
		 		     [field2], ... ]
				    } ],			    
 		 [ order  =>  fieldN]			    
		  );
		  
  $sice->db_update(
  		   table => $table_name,
		   search => {
		   	      field	=> $data1,
			      [field2	=> $data2,]
			      ...
			     },
		   columns=> {
			      field1	=> $data1,
			      ...
	  		     }
	          );
		  
  $sice->db_commit;
  		
  $sice->db_delete(
  		   table => $table_name,
		   search => {
		   	      field	=> $data1,
			      ...
			     }
		  );
  
  # db_next returns the next row as a hash ref		  
  my $x;		  
  while ($x=$sice->db_next )
   {     
     map { printf "key = %s, value =\'%s\'\n",$_,$x{$_} } keys %{$x};
   }
  
  # db_array returns all the rows as an array of hash refs
  my $x;		  
  foreach $x (@{$sice->db_array })
   {     
     map { printf "key = %s, value =\'%s\'\n",$_,$x{$_} } keys %{$x};
   }
  
   
  
  $sice->db_trace(level => $number);	# turn on DBI tracing		   
  $sice->db_rows;			# return rows affected by session handle
  					# note that DBI documentation indicates
					# that the rows method upon which this is
					# based is effectively useless.
  $rc=$sice->db_ping;			# perform a db_ping call
  $sice->{debug} = 1 ; # turn on debugging
  $sice->{debug} = 0 ; # turn off debugging
  $sice->db_rollback;  # roll back a transaction
  
  
  # quoting for table, field, and value is set by default
  # you can override it during or after creating the object.
  $sice->{quote}->{table} = '"';
  $sice->{quote}->{field} = '"';
  $sice->{quote}->{value} = '"';
  
  # SQLite, Postgres, and MySQL are supported, with default
  # quoting assumed for others.  You can change this as needed.
  
  $sice->db_close; 

The session handle is available under the object as $sice->{_sth}

=head2 Methods

=over 4
 
=item db_open(dsn => $dsn, dbuser => $dbuser, dbpass => $dbpass  )

The C<db_open> method returns a database handle attached to
$self->{_dbh}.  RaiseError defaults to 0 and AutoCommit defaults
to 1.  This function attaches the object to a database.
As long as the DBD/DBI supports it, you may have multiple 
independent objects connected to the same database.

=item db_add(table => $table_name,columns => {field1=>$data1,...})

The C<db_add> method will take a record (the hash pointed to by 
the columns field, generate the necessary SQL, and do an insert into
the table indicated.  That is, if we have a table named "users", and
we want to add a record with a username, password, home directory,
and shell, we can do something like this:

    use DBIx::SimplePerl;
    my $sice = DBIx::SimplePerl->new;        
    $sice->db_open(
                    'dsn'    => "dbi:SQLite:dbname=/etc/cluster/cluster.db",
                    'dbuser' => "",
                    'dbpass' => ""
                  );
  
    $sice->db_add(
    		   table   =>"users",
		   columns => {
		   		username	=> $username,
				password	=> $password,
				homedir		=> $homedir,
				shell		=> $shell
		   	      }
		 );

and the method will generate the appropriate SQL to insert this 
record:

   insert into "users" ("username","password","homedir","shell") \
   values ("$username","$password","$homedir","$shell");

If the insert operation failed or generated errors or warnings, you
will be able to check for the existence of and inspect $sice->{failed}.
As each DBD is different, no two different DBDs will generate the same 
error messages or error codes.  

If you would like to see the SQL the method generates, then set
the debug attribute to a non-zero value

  $sice->{debug} = 1;

and it will emit the SQL it generates on the STDERR.

=item db_search(table => $table_name,search => {field1=>$data1,...})

The C<db_search> method will perform a select with an
appropriate where clause, generated by the hash pointed to by 
the search field.  That is, if we have a table named "users", and
we want to find a set of one or more records with a particular 
username, we can do something like this:

    use DBIx::SimplePerl;
    my $sice = DBIx::SimplePerl->new;        
    $sice->db_open(
                    'dsn'    => "dbi:SQLite:dbname=/etc/cluster/cluster.db",
                    'dbuser' => "",
                    'dbpass' => ""
                  );
  
    $sice->db_search(
    		   table   =>"users",
		   search => { username => $username }
		 );

and the method will generate the appropriate SQL to perform this 
select:

   select from "users" where "username"="$username";

If you provide an array to the search field (username in this example)
the module will do the right thing and generate 

   select from "users" where "username" in ( "@{$username}[0]" ,
   "@{$username}[1]" , ... , "@{$username}[N]");
   
So if you performed this call like this:

    $sice->db_search(
    		   table	=>"users",
		   search 	=> { 
		   		    username => [
				    		 "Tom",
						 "Dick",
						 "Harry"
						] 
				   }
		 );

the module will generate the query as

   select from "users" where "username" in ("Tom", "Dick", "Harry");
   
This functionality is not yet in other methods than the search module.  
This may change in future releases.

Also, if you want to return only some of the columns in the database,
you could use the columns => "comma,separated,list,of,columns,to,return"
option

    $sice->db_search(
    		   table	=>"users",
		   search 	=> { 
		   		    username => [
				    		 "Tom",
						 "Dick",
						 "Harry"
						] 
				   },
		   columns	=> "name,date,uid,homedir"
		 );

And if you wanted to pre-order the output records, use the order=>field
option

    $sice->db_search(
    		   table	=>"users",
		   search 	=> { 
		   		    username => [
				    		 "Tom",
						 "Dick",
						 "Harry"
						] 
				   },
		   columns	=> "name,date,uid,homedir",
		   order	=> "uid"
		 );

or

    $sice->db_search(
    		   table	=>"users",
		   search 	=> { 
		   		    username => [
				    		 "Tom",
						 "Dick",
						 "Harry"
						] 
				   },
		   order	=> "uid"
		 );



If the select operation failed or generated errors or warnings, you
will be able to check for the existence of and inspect 
$sice->{failed}->{error} and if the DBD developer provided an error 
code, it would be in $sice->{failed}->{code}.  As each DBD is 
different, no two different DBDs will generate the same error 
messages or error codes.  

As many fields as are relevant in the  particular table may be used.  The
search=> may be completely omitted  to give a "SELECT * from table"
effect.  The results are returned as a DBI session handle within the 
object instance.  To extract the data, use the db_next method. 

while ($sice->db_next)
 {
  # do something with the $_ hashref to the query results
 }

or if you prefer dealing with arrays, you can use a foreach with
db_array

foreach (@$sice->db_array)
 {
  # do something with the $_ hashref to the query results  
 }
  
If the select succeeds, then the $sice->db_search... will 
return an anonymous hash with a key named "success".  Testing
for the existence of this key is sufficent for determining if the
method call succeeded.  Error messages (if generated) would be 
stored in the anonymous hash's "failed" key.  Lack of existence of
this key is another indicator of success.  There is more than one
way to do it, and these should always be consistent.

Of course though, they are not (yet) consistent.  DBI returns 

	function(column) => 'value'
	
for the min, max, and count functions.  So if you do a search for the 
maximum of a set of columns

   $sice->db_search(
    		     table	=> "users",
		     max 	=> "uid"
		   );

then when you query the returned results, be aware that they will
show up as 

	'max(uid)'	=> value
	
using the hashrefs.  Since you don't care about the key, you can  
extract the first value.

	$max	= (values %{$sice->db_next} )[0];
	
This is somewhat convoluted, so assume that this interface will change.


=item db_update( table => $table_name, 
                 search => {field1=>$data1,...}, 
		 columns=> {field1=>$data1,...});


The C<db_update> method will perform an update with an
appropriate where clause, generated by the hash pointed to by 
the search field, using the column hash to insert the updated
values.  Fields not specified in the column hash will not be
changed.  That is, if we have a table named "users", and
we want to update a set of one or more records with a particular 
username, we can do something like this:

    use DBIx::SimplePerl;
    my $sice = DBIx::SimplePerl->new;        
    $sice->db_open(
		  'dsn'    => "dbi:SQLite:dbname=/etc/cluster/cluster.db",
		  'dbuser' => "",
	          'dbpass' => ""
                  );
  
    $sice->db_update(
    		   table   =>"users",
		   search  => { username => $username    },
		   columns => { homedir  => $new_homedir }
		 );

and the method will generate the appropriate SQL to perform this 
update.:

   update  "users" set "homedir"="$new_homedir" \
                   where "username"="$username";

If the update operation failed or generated errors or warnings, you
will be able to check for the existence of and inspect $sice->{error}.
As many fields as are relevant in the particular table may be used 
in the search hash or the column hash.  The results are returned as
a DBI session handle, and any of the DBI methods may be used to
extract the data at this point.
  
If the update succeeds, then the $sice->db_update... will 
return an anonymous hash with a key named "success".  Testing
for the existence of this key is sufficent for determining if the
method call succeeded.  Error messages (if generated) would be 
stored in the anonymous hash's "failed" key.  Lack of existence of
this key is another indicator of success. 


=item db_commit

The C<db_commit> method will perform an explicit commit on the 
db handle.  This is useful when AutoCommit is set to 0.  Note that 
this means that if you disconnect on an AutoCommit => 0 db before
doing a db_close, that your state changes will likely be lost.  

B<Caveat Programmer>

You would need to perform the db_commit after some group of operations
on an AutoCommit => 0 to insure that they are in fact committed to 
disk.  If AutoCommit => 0, this is entirely your responsibility.  
Turning off AutoCommit can speed things up tremendously, though 
it will do it at the expense of granularity.  Your changes will be 
much larger grained.  This is why we default to AutoCommit => 1, so
you do not need to think about this for most cases.

If the commit operation failed or generated errors or warnings, you
will be able to check for the existence of and inspect $sice->{error}.

=item db_delete(table => $table_name, search => {field1=>$data1,...})


The C<db_delete> method will perform a record delete with an
appropriate where clause, generated by the hash pointed to by 
the search field.  This will not delete the table itself, just the
record.  That is, if we have a table named "users", and
we want to delete a set of one or more records with a particular 
username, we can do something like this:

    use DBIx::SimplePerl;
    my $sice = DBIx::SimplePerl->new;        
    $sice->db_open(
                    'dsn'    => "dbi:SQLite:dbname=/etc/cluster/cluster.db",
                    'dbuser' => "",
                    'dbpass' => ""
                  );
  
    $sice->db_delete(
    		   table   =>"users",
		   search  => {
		   		username => $username		
		   	      }
		 );

and the method will generate the appropriate SQL to perform this 
update.:

   delete from "users" where "username"="$username";

Note that if more than one field is used in the search, the fields 
will use as the conditional, in order,

1) $sice->{search_conditional} (with values of "AND", "OR", or any other
SQL accepted operator for delete statements.

2) "AND" which is the default unless overridden in this object by point 1.

This allows you to have  

    $sice->db_delete(
                   table   =>"users",
                   search  => {
                                username => $username,
				dir	 => $dir
                              }
                 );

become (by default)

   delete from "users" where "username"="$username" AND "dir"=$dir;



If the delete operation failed or generated errors or warnings, you
will be able to check for the existence of and inspect $sice->{error}.
As many fields as are relevant in the particular table may be used 
in the search hash.  The results are returned as
a DBI session handle, and any of the DBI methods may be used to
extract the data at this point.
  
If the delete succeeds, then the $sice->db_update... will 
return an anonymous hash with a key named "success".  Testing
for the existence of this key is sufficent for determining if the
method call succeeded.  Error messages (if generated) would be 
stored in the anonymous hash's "failed" key.  Lack of existence of
this key is another indicator of success. 

=item db_create_table(table => $table_name,columns => {field1=>"type1",...})

The C<db_create_table> method will take a record (the hash pointed to by 
the columns field, generate the necessary SQL, and do an create table into
the attached database handle.  That is, if we want to create a table 
named "users", with columns of username, password, home directory, uid,
shell, and date we can do something like this:

    use DBIx::SimplePerl;
    my $sice = DBIx::SimplePerl->new;        
    $sice->db_open(
                    'dsn'    => "dbi:SQLite:dbname=/etc/cluster/cluster.db",
                    'dbuser' => "",
                    'dbpass' => ""
                  );
  
    $sice->db_create_table(
    		   table   =>"users",
		   columns => {
		   		username	=> "varchar(30)",
				password	=> "varchar(30)",
				homedir		=> "varchar(255)",
				shell		=> "varchar(30)",
				uid		=> "integer",
				date		=> "datetime"
		   	      }
		 );

and the method will generate the appropriate SQL to create this 
table:

   create table "users" 
   	(
	  "username"	varchar(30),
	  "password"	varchar(30),
	  "homedir"	varchar(255) ,
	  "shell"	varchar(30),
	  "uid"		integer,
	  "date"	datetime
	);

If the create operation failed or generated errors or warnings, you
will be able to check for the existence of and inspect $sice->{failed}.
As each DBD is different, no two different DBDs will generate the same 
error messages or error codes.  

If you would like to see the SQL the method generates, then set
the debug attribute to a non-zero value

  $sice->{debug} = 1;

and it will emit the SQL it generates on the STDERR.


=cut
sub db_open
    {
      my ($self,%args) = @_;
      my ($dsn,$dbuser,$dbpass,$options,%rc,$dbh,$tmp,$name,$autocommit);
      my ($remaining,$raiseerror,@opts,%attr);      
      
      printf STDERR "D[%s] db_open: args -> \'%s\'\n",$$,join(":",keys(%args)) if ($self->{debug});
	
      # quick error check    
      foreach (qw(dsn dbuser dbpass))
        {
	 if (exists($args{$_})) 
            { 
	      $dsn	= $args{$_} if ($_ eq 'dsn');
	      $dbuser	= $args{$_} if ($_ eq 'dbuser');
	      $dbpass	= $args{$_} if ($_ eq 'dbpass');
	      delete $args{$_};
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	}
      foreach (keys %args)
       {
        $attr{$_}=$args{$_} if (
				($_ ne "dsn") && 
				($_ ne "dbuser") && 
				($_ ne "dbpass")
			       ) ;	 
       }      
      # construct remaining arg string
      $remaining	= "";
      $attr{'AutoCommit'} = 1 if (!defined($attr{AutoCommit}));
      $attr{'RaiseError'} = 0 if (!defined($attr{RaiseError}));
      map { push @opts,(sprintf "%s => %s",$_,$attr{$_}) } (keys %attr) ;

      $remaining = join(", ",@opts);
      printf STDERR "D[%s] db_open: open optional args -> \'%s\'\n",$$,$remaining if ($self->{debug});
	 
      # connect to DB
      $self->{_dbh}	= false;
      #$self->{_sth} 	= false;
       
      $self->{_dbh}= DBI->connect(
	    			  $dsn, 
				  $dbuser, 
				  $dbpass, 
				  \%attr
				 );
	  
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      
      printf STDERR "D[%s]: DBIx::SimplePerl database connection succeeded\n",$$ if ($self->{debug});   
      %rc= ( 'success' => true );
      printf STDERR "D[%s]: DBIx::SimplePerl database connection dump = %s\n",$$,Dumper($self) if ($self->{debug});   
      # handle field quoting
      if (!defined($self->{quote}))
         {
          if ($dsn =~ /dbi:Pg/i)
	     { # postgresql
	       $self->{quote}->{table}='"';
	       $self->{quote}->{field}='"';
	       $self->{quote}->{value}="\'";
	     }
	  elsif ($dsn =~ /dbi:SQLite/i)
	     { # sqlite
	       $self->{quote}->{table}='"';
	       $self->{quote}->{field}="";
	       $self->{quote}->{value}='"';
	     }
	  elsif ($dsn =~ /DBI:mysql/i)
	     { # mysql
	       $self->{quote}->{table}="";
	       $self->{quote}->{field}="";
	       $self->{quote}->{value}='"';
	     }
	  else
	     { # default
	       $self->{quote}->{table}='"';
	       $self->{quote}->{field}="\'";
	       $self->{quote}->{value}='"';
	     }	     
         }
      return \%rc;
    }

 
sub db_add
    {
      my ($self,%args)=@_;
      my ($table,$q_table,$columns,$prep,%rc,@fields,@q_fields,@values);
      
      # quick error check    
      foreach (qw(table columns))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $self->_quote_table($args{$_}) if ($_ eq 'table');
	      $columns	= $args{$_} if ($_ eq 'columns');
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	} 
      
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" } );
	   return \%rc;
	 }

      # extract fields and values from the columns
      @fields=(keys %{$columns});    
      map { push @values,$self->_quote_value($columns->{$_}) } @fields;
      map { push @q_fields,$self->_quote_field($_) } @fields;
      
      # create the SQL for the insert
      $prep  = sprintf 'INSERT INTO %s (',$table;
      $prep .= join(",",@q_fields). ') VALUES (';
      foreach (0 .. $#values)
        {
	  $prep .= sprintf "%s",$values[$_];
	  $prep .= "," if ($_ < $#values);
	}
      $prep .= ')';

      printf STDERR "D[%s] db_add: prepare = \'%s\' \n",
	   $$,$prep  if ($self->{debug});
      # compile it
      $self->{_sth} = $self->{_dbh}->prepare($prep) ;
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      
      printf STDERR "D[%s] db_add: prepare succeeded\n",$$ if ($self->{debug});   
	       
      # execute it ...
      $self->{_sth}->execute(); 
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      
      printf STDERR "D[%s] db_add: execute succeeded\n",$$ if ($self->{debug});   	            
      %rc= ( 'success' => true );
      return \%rc;
    }   
 
sub db_search
    {
      my ($self,%args)=@_;
      my ($table,$search,$prep,%rc,@fields,@values,@q_fields,$order);
      my ($count, $max, $min, $boolean, $in_variant,$v_values,$cols);
      my ($complex_cols,$specials,$distinct,$operator);
      
      $cols     = "*";
      $operator = "AND";
 
     # quick error check    
      
      foreach (qw(table search order count max min boolean columns distinct search_operator))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $self->_quote_table($args{$_}) if ($_ eq 'table');
	      $search	= $args{$_} if ($_ eq 'search');
	      $order	= $args{$_} if ($_ eq 'order');
	      $cols	= $args{$_} if ($_ eq 'columns');
	      $distinct	= $args{$_} if ($_ eq 'distinct');
	      $operator	= $args{$_} if ($_ eq 'search_operator');
	      $count	= $args{$_} if ($_ eq 'count');
	      $max	= $args{$_} if ($_ eq 'max');
	      $min	= $args{$_} if ($_ eq 'min');
	    }
	} 
      if (!defined($table))      
	    {
	      %rc= ( 'failed' => {'error' => "no table specified" } );
	      return \%rc;
	    }
	    
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" });
	   return \%rc;
	 }

      # only one of max, min, count.
      $specials=0;
      $specials++ if (defined($count));
      $specials++ if (defined($min));
      $specials++ if (defined($max));
      if ( $specials > 1 )
         {
	   %rc= ( 'failed' => { 'error' => "only one of MAX, MIN, COUNT can be used at a time in a query" } );
	   return \%rc;
	 }
      # if search is not defined, then use simpler form of 
      # search (e.g. select * from table; )
      if (!defined($search))
         {
	  if ( (!defined($count)) && (!defined($min)) && (!defined($max)) && (!defined($distinct)) )
	   {
	    $prep  = sprintf 'SELECT %s FROM %s',$cols,$table;
	   }
	  elsif (defined($count))
	   {
	     $prep  = sprintf 'SELECT count(%s) FROM %s',$count,$table;
	   }
	  elsif (defined($max))
	   {
	     $prep  = sprintf 'SELECT max(%s) FROM %s',$max,$table;
	   }
	  elsif (defined($min))
	   {
	     $prep  = sprintf 'SELECT min(%s) FROM %s',$min,$table;
	   }
          elsif (defined($distinct))
           {
             $prep .= sprintf 'SELECT DISTINCT %s FROM %s',$distinct,$table;
           }
	 }
	elsif (
	      (defined($search)) && 
	      (
	       (!defined($count)) && 
	       (!defined($min)) && 
	       (!defined($max))
	      )
	     )
	   {
	  $prep  = sprintf 'SELECT %s FROM %s WHERE ',$cols,$table;      
	  # extract fields and values from the columns
	  @fields=(keys %{$search});
          map { push @q_fields,$self->_quote_field($_) } @fields;
	  $in_variant	=  (1==0);	#force it to false
	  
	  # see if we are dealing with a field => [array of values]
	  # if this is the case, the we need to construct the search
	  # using the where field in ('value1', 'value2', ... , 'valueN')
	  map { 
	        $in_variant = (1==1) if (ref($search->{$_}) eq "ARRAY");
	      } @fields;
	      
	  if (!$in_variant)
	   {
	    # normal method, using simple scalar values for fields
            map { push @values,$self->_quote_value($search->{$_}) } @fields;

	    # create the SQL for the insert
	    foreach (0 .. $#q_fields)
              {
	       $prep .= (defined($self->{search_condition}) ? $self->{search_condition} : " AND ") if ($_ > 0);
	       $prep .= sprintf "%s=%s",$q_fields[$_],$values[$_];
	      }
	   }
	   else
	   {
	    # more complex method.  First scan through the non-array bits
	    # and add them.  Then 
	    
	    my $_count=1;
	    foreach (@fields)
	     { 
	      $prep .= " AND " if ($_count > 1);
	      if (ref($search->{$_}) ne "ARRAY")
	       {
	        $prep .= sprintf "%s=%s",$self->_quote_field($_),
		$self->_quote_value($search->{$_});
	       }
	       else
	       {
	        my $_in_="(";
		my $_field_=$_;
		foreach (@{$search->{$_}})
		 {
		  $_in_ .= (sprintf "%s, ",$self->_quote_value($_));		  
		 }
		$_in_ .= ")";
		$_in_ =~ s/\,\s+\)$/\)/; # clean up the last comma
		$prep .= sprintf "%s in %s",$self->_quote_field($_field_),$_in_;
	       }
	      $_count++;
	     }  
	   }
	  }
	 elsif (
		(defined($search)) && 
		(
		 (defined($count)) ||
		 (defined($min)) ||
		 (defined($max))
		)
	       )
	   {
	  $complex_cols	= sprintf "MAX(%s)",$max if (defined($max));
	  $complex_cols	= sprintf "MIN(%s)",$min if (defined($min));
	  $complex_cols	= sprintf "COUNT(%s)",$count if (defined($count));
	   
	  $prep  = sprintf 'SELECT %s FROM %s WHERE ',$complex_cols,$table;      
	  # extract fields and values from the columns
	  @fields=(keys %{$search});
          map { push @q_fields,$self->_quote_field($_) } @fields;
	  $in_variant	=  (1==0);	#force it to false
	  
	  # see if we are dealing with a field => [array of values]
	  # if this is the case, the we need to construct the search
	  # using the where field in ('value1', 'value2', ... , 'valueN')
	  map { 
	        $in_variant = (1==1) if (ref($search->{$_}) eq "ARRAY");
	      } @fields;
	      
	  if (!$in_variant)
	   {
	    # normal method, using simple scalar values for fields
            map { push @values,$self->_quote_value($search->{$_}) } @fields;

	    # create the SQL for the insert
	    foreach (0 .. $#q_fields)
              {
	       $prep .= (sprintf " %s ",$operator) if ($_ > 0);
	       $prep .= sprintf "%s=%s",$q_fields[$_],$values[$_];
	      }
	   }
	   else
	   {
	    # more complex method.  First scan through the non-array bits
	    # and add them.  Then 
	    
	    my $_count=1;
	    foreach (@fields)
	     { 
	      $prep .= (sprintf " %s ",$operator) if ($_count > 1);
	      if (ref($search->{$_}) ne "ARRAY")
	       {
	        $prep .= sprintf "%s=%s",$self->_quote_field($_),
		$self->_quote_value($search->{$_});
	       }
	       else
	       {
	        my $_in_="(";
		my $_field_=$_;
		foreach (@{$search->{$_}})
		 {
		  $_in_ .= (sprintf "%s, ",$self->_quote_value($_));		  
		 }
		$_in_ .= ")";
		$_in_ =~ s/\,\s+\)$/\)/; # clean up the last comma
		$prep .= sprintf "%s in %s",$self->_quote_field($_field_),$_in_;
	       }
	      $_count++;
	     }  
	   } 
#############	  
         }
      if (defined($order))      { $prep .= (sprintf " ORDER BY %s ",$order)}
      printf STDERR "D[%s] db_search: prepare = \'%s\' \n",
	   $$,$prep  if ($self->{debug});

      # compile it
      $self->{_sth} = $self->{_dbh}->prepare($prep);
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});

      printf STDERR "D[%s] db_search: prepare succeeded\nprepare: %s\n",$$,$prep if ($self->{debug});   
	 
      
      # execute it ...
      printf STDERR "D[%s] db_search: executing search\n",$$ if ($self->{debug});
      $self->{_sth}->execute();
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      printf STDERR "D[%s] db_search: execute succeeded\n",$$ if ($self->{debug});   	
      
      %rc= ( 'success' => true );
      return \%rc;
    }   
 
sub db_update
    {
      my ($self,%args)=@_;
      my ($table,$search,$columns,$prep,%rc,@sfields,@svalues,@cfields,@cvalues);
      my (@q_sfields,@q_cfields);     
      
      # quick error check    
      foreach (qw(table search columns))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $self->_quote_table($args{$_}) if ($_ eq 'table');
	      $search	= $args{$_} if ($_ eq 'search');
	      $columns	= $args{$_} if ($_ eq 'columns');
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	} 
      
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" } );
	   return \%rc;
	 }

      # extract fields and values from the columns
      @sfields=(keys %{$search});
      map { push @svalues,$self->_quote_value($search->{$_}) } @sfields;
      map { push @q_sfields,$self->_quote_field($_) } @sfields;
      @cfields=(keys %{$columns});
      map { push @cvalues,$self->_quote_value($columns->{$_}) } @cfields;
      map { push @q_cfields,$self->_quote_field($_) } @cfields;
      
      # create the SQL for the insert
      $prep  = sprintf 'UPDATE %s  SET ',$table;      
      foreach (0 .. $#cfields)
        {
	 $prep .= "," if ($_ > 0);
	 $prep .= sprintf "%s=%s",$q_cfields[$_],$cvalues[$_];
	}
      $prep .= ' WHERE ';
      foreach (0 .. $#sfields)
        {
	 $prep .= "," if ($_ > 0);
	 $prep .= sprintf "%s=%s",$q_sfields[$_],$svalues[$_];
	}
      printf STDERR "D[%s] db_update: prepare = \'%s\' \n",
	   $$,$prep  if ($self->{debug});
      

      # compile it
      $self->{_sth} = $self->{_dbh}->prepare($prep) ;
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      printf STDERR "D[%s] db_update: prepare succeeded\n",$$ if ($self->{debug});   
	
      
      # execute it ...
      $self->{_sth}->execute();
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      printf STDERR "D[%s] db_update: execute succeeded\n",$$ if ($self->{debug});   
      
      %rc= ( 'success' => true );
      return \%rc;
    }   

sub db_delete
    {
      my ($self,%args)=@_;
      my ($table,$search,$prep,%rc,@fields,@values,@q_fields);
      
      # quick error check    
      foreach (qw(table search))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $self->_quote_table($args{$_}) if ($_ eq 'table');
	      $search	= $args{$_} if ($_ eq 'search');
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	} 
      
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" } );
	   return \%rc;
	 }

      # extract fields and values from the columns
      @fields=(keys %{$search});
      map { push @values,$self->_quote_value($search->{$_}) } @fields;
      map { push @q_fields,$self->_quote_field($_) } @fields;
      
      
      # create the SQL for the delete
      $prep  = sprintf 'DELETE FROM %s WHERE ',$table;      
      foreach (0 .. $#fields)
        {
	 $prep .= " AND " if ($_ > 0);
	 $prep .= sprintf "%s=%s",$q_fields[$_],$values[$_];
	}
      printf STDERR "D[%s] db_delete: SQL=\'%s\'\n",$$,$prep  if ($self->{debug});
     

      # compile it
      $self->{_sth} = $self->{_dbh}->prepare($prep);
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      printf STDERR "D[%s] db_delete: prepare succeeded\n",$$ if ($self->{debug});   
      
      # execute it ...
      $self->{_sth}->execute();
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      printf STDERR "D[%s] db_delete: execute succeeded\n",$$ if ($self->{debug});         
      
      %rc= ( 'success' => true );
      return \%rc;
    }   

sub db_next
    {	
      my ($self,%args)=@_;
      my $rc;      
      # quick sanity check: return undef if no session handle to query from
      return undef if (!($self->{_sth}));
      printf STDERR "D[%s] db_next: returning hashref\n",$$ if ($self->{debug});  
      $rc= $self->{_sth}->fetchrow_hashref;
      return $rc;
    }   

sub db_array
    {	
      my ($self,%args)=@_;
      my $rc;      
      # quick sanity check: return undef if no session handle to query from
      return undef if (!($self->{_sth}));
      printf STDERR "D[%s] db_array: returning array of hashes\n",$$ if ($self->{debug});  
      $rc= $self->{_sth}->fetchall_arrayref({});
      return $rc;
    }   
    
sub db_rows
    {
      my ($self,%args)=@_;
      my $rc; 
      # quick sanity check: return undef if no session handle to query from
      return undef if (!($self->{_sth}));
      $rc=$self->{_sth}->rows;
      printf STDERR "D[%s] db_rows: returning %s\n",$$,$rc if ($self->{debug});  
      return $rc;
    }

sub db_ping
    {
      my ($self,%args)=@_;
      # quick sanity check: return undef if no db handle set up
      return undef if (!($self->{_dbh}));
      return $self->{_dbh}->ping;
    }    

sub db_rollback
    {
      my ($self,%args)=@_;
      # quick sanity check: return undef if no db handle set up
      return undef if (!($self->{_dbh}));
      eval { $self->{_dbh}->rollback; };
      return $@;
    }      
    
sub db_trace
    {
      my ($self,%args)=@_;
      my ($level,$file);
      if (!($self->{_dbh}))
       {
        my %rc= ( 'failed' => {'error' => "no database connection to trace" } );
	return \%rc;
       }
      foreach (qw(level file))
        {
	 if (exists($args{$_})) 
            { 
	     $level	= $args{$_} if ($_ eq 'level');
	     $file	= $args{$_} if ($_ eq 'file');
	    }
	   else
	    {
	     my %rc= ( 'failed' => {'error' => "no $_ specified" } );
	     return \%rc;
	    }
	} 
      if (!$file)
       {
        $self->{_dbh}->trace($level);
       }
       else
       {
        $self->{_dbh}->trace($level,$file);
       
       }
      # quick sanity check: return undef if no session handle to query from
      return $self->{_sth}->fetchrow_hashref;
    }   
sub db_close
    {
      my ($self )=shift;
      my %rc;
      if (defined($self->{_sth})) { undef $self->{_sth} ; }
      $self->{_dbh}->disconnect();      
      printf STDERR "D[%s] db_close\n",$$ if ($self->{debug});
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      
      %rc= (  'success' => true );
      return \%rc;	 
    } 

sub db_commit
    {
      my ($self )=shift;
      my %rc;
      $self->{_dbh}->commit() if (defined($self->{_dbh}));      
      printf STDERR "D[%s] db_commit\n",$$ if ($self->{debug});
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});

      %rc= (  'success' => true );
      return \%rc;
    }
    
sub db_create_table
    {
      my ($self,%args)=@_;
      my ($table,$columns,$prep,%rc,@fields,%types,@q_fields);
      
      # quick error check    
      foreach (qw(table columns))
        {
	 if (exists($args{$_})) 
            { 
	      $table	= $self->_quote_table($args{$_}) if ($_ eq 'table');
	      $columns	= $args{$_} if ($_ eq 'columns');
	    }
	   else
	    {
	      %rc= ( 'failed' => {'error' => "no $_ specified" } );
	      return \%rc;
	    }
	} 
      
      if ( !defined( $self->{_dbh} ) )
         {
	   %rc= ( 'failed' => { 'error' => "Database handle does not exist" } );
	   return \%rc;
	 }

      # extract fields and values from the columns
      @fields=(keys %{$columns});
      map { $types{$_}=$columns->{$_} } @fields;
      map { push @q_fields,$self->_quote_field($_) } @fields;
     
      # create the SQL for the insert
      $prep  = sprintf 'CREATE TABLE %s (',$table;
      $prep .= "\n";
      
      foreach (0 .. $#fields)
        {
	  $prep .= sprintf "\t%s   %s",$q_fields[$_],$types{$fields[$_]};
	  $prep .= ",\n" if ($_ < $#fields);
	}
      $prep .= ')';
      printf STDERR "D[%s] db_create_table: SQL=\'%s\'\n",$$,$prep  if ($self->{debug});

      # compile it
      $self->{_sth} = $self->{_dbh}->prepare($prep);
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});           
      printf STDERR "D[%s] db_create_table: prepare succeeded\n",$$ if ($self->{debug});   	
      
      # execute it ...
      $self->{_sth}->execute(); 
      %rc=%{$self->_check_and_return_if_error};
      return \%rc if ($rc{failed});
      printf STDERR "D[%s] db_create_table: execute succeeded\n",$$ if ($self->{debug});   
 
      %rc= ( 'success' => true );
      return \%rc;
    }   

sub _quote_table
    {
      my ($self,$value) = @_;
      my $_x = sprintf "%s%s%s",
      			$self->{quote}->{table},
			$value,
			$self->{quote}->{table};
      return $_x;
    }
sub _quote_field
    {
      my ($self,$value) = @_;
      my $_x = sprintf "%s%s%s",
      			$self->{quote}->{field},
			$value,
			$self->{quote}->{field};
      return $_x;
    }
sub _quote_value
    {
      my ($self,$value) = @_;
      my $_x = sprintf "%s%s%s",
      			$self->{quote}->{value},
			$value,
			$self->{quote}->{value};
      return $_x;
    }

sub _check_and_return_if_error
    {
      my ($self) = @_;
      my %rc;
      if ( 
	  (defined($self->{_dbh}->err))	&& 
	  ($self->{_dbh}->err)
	 )
	 {
	   printf STDERR "D[%s]: DBIx::SimplePerl database error \'%s\'\n",$$,$self->{_dbh}->err  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_dbh}->errstr , 
			      'code'	=> $self->{_dbh}->err 
			     } 
		);
           return \%rc;
	 }
	 
      if (
          (defined($self->{_sth} )) 	&& 
	  (defined($self->{_sth}->err))	&& 
	  ($self->{_sth}->err)
	 )
	 {
	   printf STDERR "D[%s]: DBIx::SimplePerl session handle error \'%s\'\n",$$,$self->{_sth}->err  if ($self->{debug});
	   %rc= ( 
	   	 'failed' => {
		 	      'error'	=> $self->{_sth}->errstr , 
			      'code'	=> $self->{_sth}->err 
			     } 
		);
           return \%rc;
	 }
    }
=cut
=pod
=back

=head1 EXAMPLE

Suppose you have a nice database, a SQLite in this case, though it
will work perfectly well with Mysql, Postgres, and anything else
DBI supports.  This database has a list of host names and MAC
addresses, and you want to list them from the database.  

The table has been created using:


 CREATE TABLE hosts (
        mac_address      text,
        ip_address       text,
        dhcp_ipaddress   text,
        host_name        text,
        host_domain      text,
        net_device       text,
        gateway          text,
        netmask          text,
        mtu              text,
        options          text
        );


and the script looks like this


 #!/usr/bin/perl

 use strict;
 use DBIx::SimplePerl;
 my ($dbh,$err,$sice);
 my ($rc,$debug,$q);

 $debug	= 1;
 $sice   = SICE->new( { debug=>$debug } );
 $sice->db_open(
                 'dsn'           => "dbi:SQLite:dbname=/etc/cluster/cluster.db",
                 'dbuser'        => "",
                 'dbpass'        => ""
               );

 printf "Machines in cluster.db\n" ;
 $rc     = $sice->db_search('table' => 'hosts');
 if (defined($rc->{success}))
    {
       printf "mac\t\t\tip\t\thostname\n" ;
       $q=($sice->{_sth}->fetchall_hashref('mac_address'));
       foreach (sort keys %{$q})
	{
         printf "%s\t%s\t%s\n", $_,
	 			$q->{$_}->{ip_address},
				$q->{$_}->{host_name} ;
	}
    }
   else
    {
       printf "WARNING: the search did not succeed.\n
       	       DB returned the following error:\n\n%s\n\n",
	       $rc->{failed};
    }
 $sice->db_close;

The db_search does the query, and stores the result in a session
handle stored  as $object_name->{_sth}.  You can then use your
favorite DBI method to pull  out the records.  What DBI Simple
saves you is writing SQL.  It will do that portion for you.  If you
turn debugging by creating the object with  debug=>1, then you can
watch the SQL that is generated.

=head1 WHY

Why hide SQL?  That question should answer itself, especially in
programs not requiring the full firepower of a Class::DBI,
DBIx::Class or most of the DBI methods.   It is fairly easy to
make a mistake in the SQL you generate, and debugging  it can be
annoying.  This was the driving force behind this particular 
module.  The SQL that is generated is fairly simple minded.  It
is executed,  and results returned.  If it fails, this is also
caught and what DBI thinks is the reason it failed is returned as
the $object->{failed} message.

This module is not for the folks who need the full firepower of
most of the rest of DBI.  This module is for simple programs.  If
you exceed the  capabilities of this module, then please look to
one of the other modules that do DBs.  

The approach to this module is simplicity.  It is intended to be
robust  for basic applications, and it is used in a few commercial
products.

=head1 AUTHOR

Joe Landman (landman@scalableinformatics.com)


=head1 COPYRIGHT

Copyright (c) 2003-2007 Scalable Informatics LLC.  All rights
reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either Perl version
5.8.6 or, at your option, any later version of Perl 5 you may have
available.

=head1 SEE ALSO

perl(1), DBI, Class::Accessor

=head1 BUGS

Well, quite likely.  SQL is a standard, and standards are open to
interpretation.  This means that some things may not work as
expected. We have run into issues in quoting fields and values,
where DBD::Mysql happily accepted input that DBD::Pg croaked on.  
This module is known to work without noticable issues on DBD::SQLite,
DBD::Mysql, DBD::Pg.  Others may or may not work, depending upon
how compatible they are with the specs in DBI for DBD module writers.

Note: as of 1.50, RaiseError is set to 0.  If you want the code to 
throw a signal upon an error, set this to 1 when you create the object.
Also, the handles now are all outside of evals.  This is to make error 
handling saner.
=cut

1;
__END__
