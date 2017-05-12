# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBI-Simple.t'

#########################

# change 'tests => 3' to 'tests => last_test_to_print';

#use Test::More tests => 3;
use Test::More qw(no_plan);
use Data::Dumper;
BEGIN { use_ok('DBIx::SimplePerl') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my ($sice,$rc,$sice2);

$sice	= DBIx::SimplePerl->new({debug=>1});
$sice2	= DBIx::SimplePerl->new({debug=>1});

isa_ok( $sice, 'DBIx::SimplePerl' );
ok(defined($sice) eq 1,"instantiated");
#
# note:  These tests are overly simplistic.  They will be augmented over
# time


SKIP: {

	eval { require DBD::SQLite };
	skip "DBD::SQLite not installed", 2 if $@;
	my $dbname = sprintf "DBIx-SimplePerl.%i.db",$$;
	$sice->db_open(
                        'dsn' => "dbi:SQLite:dbname=".$dbname,
                        'dbuser'        => "",
                        'dbpass'        => ""
                      );
	
	$rc	= $sice->db_create_table(
					 table=>"test1",
					 columns=>{
					 	    name  => "varchar(30)",
						    number=> "integer",
						    fp    => "number"
					 	  }
					);
	if (defined($rc->{success}))
	   {
	     pass("SQLite db_create_table =".$dbname);	     
	   }
	  else
	   {
	     fail("SQLite db_create_table =".$dbname);
	     exit;
	   }
	   
	undef $rc;
	
	
	
	
	$rc	= $sice->db_add(
					 table=>"test1",
					 columns=>{
					 	    name  => "joe",
						    number=> "2",
						    fp    => "1.2"
					 	  }
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_add");	     
	   }
	  else
	   {
	     fail("SQLite db_add");
	     exit;
	   }

	undef $rc;
	$rc	= $sice->db_add(
					 table=>"test1",
					 columns=>{
					 	    name  => "oje",
						    number=> "3",
						    fp    => "1.4"
					 	  }
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_add");	     
	   }
	  else
	   {
	     fail("SQLite db_add");
	     exit;
	   }

	undef $rc;
	$rc	= $sice->db_add(
					 table=>"test1",
					 columns=>{
					 	    name  => "eoj",
						    number=> "4",
						    fp    => "1.6"
					 	  }
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_add");	     
	   }
	  else
	   {
	     fail("SQLite db_add");
	     exit;
	   }

	undef $rc;
	$rc	= $sice->db_update(
					 table=>"test1",
					 search=>{
					 	    number=>3,
					         },
					 columns=>{
						    fp    => "1.8"
					 	  }
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_update");	     
	   }
	  else
	   {
	     fail("SQLite db_update");
	     exit;
	   }

	undef $rc;
	$rc	= $sice->db_search(
					 table=>"test1",
					 search=>{
					 	    name=>"joe"
					         }
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_update");	     
	   }
	  else
	   {
	     fail("SQLite db_update");
	     exit;
	   }
	my $q=($sice->{_sth}->fetchall_hashref('name'));
	foreach (sort keys %{$q})
         {
	   printf STDERR "%s:\t%s\t%s\n", $_, $q->{$_}->{number}, $q->{$_}->{fp} ;
         }
	undef $q;
	undef $rc;

	$rc	= $sice->db_delete(
					 table=>"test1",
					 search=>{
					 	    name=>"joe"
					         }
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_update");	     
	   }
	  else
	   {
	     fail("SQLite db_update");
	     exit;
	   }
        
	undef $rc;
	$rc	= $sice->db_close;
 	if (defined($rc->{error}))
	   {
	     fail("SQLite db_close");
	     exit;
	   }
	
	$sice->db_open(
                        'dsn' => "dbi:SQLite:dbname=".$dbname,
                        'dbuser'        => "",
                        'dbpass'        => "",
			'AutoCommit'	=> 0
                      );

	undef $rc;
 	$rc	= $sice->db_create_table(
					 table=>"test2",
					 columns=>{
					 	    name  => "text",
						    number=> "integer",
						    fp    => "number",
						    q	  => "text"
					 	  }
					);
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_create_table with autocommit off");	     
	   }
	  else
	   {
	     fail("SQLite db_create_table with autocommit off");
	     exit;
	   }
	   
	undef $rc;
        $rc	= $sice->db_commit; #make the table
 	if (defined($rc->{failed}))	   
	   {
	     fail("SQLite db_create_table commit: ".$rc->{failed});
	     exit;
	   }
	undef $rc;
	for(my $i=0;$i<100;$i++)
	 {
	  $q	= rand();
	  $rc	= $sice->db_add(
				table=>"test2",
				columns=>{
					  name  => (sprintf "a%i-b",$i),
					  number=> $i,
					  fp    => 1.1*$i,
					  q	=> (($q > 0.5) ? "a" : "b")
					 }
				);

 	  if (defined($rc->{failed}))
	     {
	       fail("SQLite db_add without commit: ".$rc->{failed});
	       exit;
	     }	  
	 }
	 
	 
	undef $rc;
        $rc	= $sice->db_commit; #commit the table
 	if (defined($rc->{failed}))	   
	   {
	     fail("SQLite db_commit: commit the db_add: ".$rc->{failed});
	     exit;
	   }
	undef $rc;
		$rc	= $sice->db_search(
					 table=>"test1",
					 count=>"number"
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_search with count");	     
	   }
	  else
	   {
	     fail("SQLite db_search with count ");
	     exit;
	   }
	
	printf STDERR "**************************  DISTINCT *********** \n";   
	undef $rc;
        $rc	= $sice->db_search(
					 table		=> "test2",
					 distinct	=> "number",
					
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_search with distinct");	     
	   }
	  else
	   {
	     fail("SQLite db_search with distinct ");
	     exit;
	   }
	   
	  while (my $q=$sice->db_next()) 
	  {  printf STDERR "distinct return=%s\n",Dumper($q); }
	  
	  
	undef $rc;
        $rc	= $sice->db_search(
					 table		=> "test2",
					 search		=> { 
					 	"number" => "10" },
					 search_operator=> "OR"
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_search with search_operator");	     
	   }
	  else
	   {
	     fail("SQLite db_search with search_operator ");
	     exit;
	   }
	while (my $q=$sice->db_next()) 
	 {  printf STDERR "search_operator return=%s\n",Dumper($q); }
	 
	
	undef $rc;
	$rc	= $sice->db_search(
					 table=>"test1",
					 max=>"fp"
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_search with max");	     
	   }
	  else
	   {
	     fail("SQLite db_search with max ");
	     exit;
	   }
	undef $rc;
	$rc	= $sice->db_search(
					 table=>"test2",
					 max=>"fp",
					 columns => { q => 'b' }
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_search with max and select");	     
	   }
	  else
	   {
	     fail("SQLite db_search with max and select ");
	     exit;
	   }
	undef $rc;
	$rc	= $sice->db_search(
					 table=>"test1",
					 min=>"fp",
					 
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_search with min ");	     
	   }
	  else
	   {
	     fail("SQLite db_search with min  ");
	     exit;
	   }

	undef $rc;
	$rc	= $sice->db_search(
					 table=>"test2",
					 min=>"fp",
					 columns => { q => 'b' }
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_search with min and select");	     
	   }
	  else
	   {
	     fail("SQLite db_search with min and select ");
	     exit;
	   }
	undef $rc;
	$rc	= $sice->db_search(
					 table=>"test1",
					 search=>{"number" => [1,2,3,4,5]}
					);
	
 	if (defined($rc->{success}))
	   {
	     pass("SQLite db_search with vector_in");	     
	   }
	  else
	   {
	     fail("SQLite db_search with vector_in ");
	     exit;
	   }

	undef $rc;
	$rc	= $sice->db_ping();
	
 	if ($rc)
	   {
	     pass("SQLite db_ping");	     
	   }
	  else
	   {
	     fail("SQLite db_ping ");
	     exit;
	   }

	undef $rc;
	$rc	= $sice->db_search(
					 table=>"test2",
					 search=>{"number" => [10,20,30]}
					);
        my $rows=$sice->db_rows;
        printf STDERR "rows=%s\n",$rows; 
        my $count=0;
	while (my $q=$sice->db_next()) { $count++;printf STDERR "return=%s\n",Dumper($q); }
 	if ($count == 3)
	   {
	     pass("SQLite db_next");	     
	   }
	  else
	   {
	     fail("SQLite db_next count=$count ");
	     exit;
	   }

printf STDERR "\n\n## ERROR TESTS... these are to make sure we can catch/report
## error conditions properly
## incorrect table name, should fail.... without killing the program\n\n";
	undef $rc;	
	$rc	= $sice->db_search(
					 table=>"test3",
					 min=>"fp"
					);
	printf "T[%s] error detection test return %s\n",$$,$rc->{failed}->{error};
 	if (defined($rc->{failed}))
	   {
	     pass("SQLite erroneous db_search to flag error condition worked\n$rc->{failed}->{error}\n");	     
	   }
	  else
	   {
	     fail("SQLite erroneous db_search to flag error condition did not work, error condition not flagged");
	     exit;
	   }

# incorrect table name, should fail....
	undef $rc;	
	$rc	= $sice->db_delete( table=>"test3" );
	
 	if (defined($rc->{failed}))
	   {
	     pass("SQLite erroneous db_delete to flag error condition worked\n$rc->{failed}->{error}\n");	     
	   }
	  else
	   {
	     fail("SQLite erroneous db_delete to flag error condition did not work, error condition not flagged");
	     exit;
	   }

# incorrect table name, should fail....
	undef $rc;	
	$rc	= $sice->db_update( 
				   table=>"test3",
				   search  => {
                                                username => "1"
                                              },
                              	   columns => {
                                                homedir => "2"
                                              }
                                  );
	
 	if (defined($rc->{failed}))
	   {
	     pass("SQLite erroneous db_update to flag error condition worked\n$rc->{failed}->{error}\n");	     
	   }
	  else
	   {
	     fail("SQLite erroneous db_update to flag error condition did not work, error condition not flagged");
	     exit;
	   }

# incorrectly built object, should fail....
	undef $rc;
	my $sice2 =	
	$rc	= $sice->db_update( 
				   table=>"test3", 
				   search  => {
                                                username => "1"
                                              },
                              	   columns => {
                                                homedir => "2"
                                              }
                                  );
	
 	if (defined($rc->{failed}))
	   {
	     pass("SQLite db_update to flag unopened database error condition worked\n$rc->{failed}->{error}\n");	     
	   }
	  else
	   {
	     fail("SQLite db_update to flag unopened database error condition did not work, error condition not flagged");
	     exit;
	   }

###


	
	$rc	= $sice->db_close;
 	if (defined($rc->{failed}))
	   {
	     fail("SQLite db_close: ".$rc->{failed});
	     exit;
	   }
	
	
	

	unlink $dbname;
      }
