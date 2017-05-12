=head1 NAME

DBD::Sprite - Perl extension for DBI, providing database emmulation via flat files.  

=head1 AUTHOR

    This module is Copyright (C) 2000-2015 by

		Jim Turner
		
        Email: jim.turner@lmco.com

    All rights reserved.

    You may distribute this module under the terms of either the GNU General
    Public License or the Artistic License, as specified in the Perl README
    file.

	JSprite.pm is a derived work by Jim Turner from Sprite.pm, a module 
	written and copyrighted (c) 1995-1998, by Shishir Gurdavaram 
	(shishir@ora.com).

=head1 SYNOPSIS

     use DBI;
     $dbh = DBI->connect("DBI:Sprite:spritedb",'user','password')
         or die "Cannot connect: " . $DBI::errstr;
     $sth = $dbh->prepare("CREATE TABLE a (id INTEGER, name CHAR(10))")
         or die "Cannot prepare: " . $dbh->errstr();
     $sth->execute() or die "Cannot execute: " . $sth->errstr();
     $sth->finish();
     $dbh->disconnect();

=head1 DESCRIPTION

DBD::Sprite is a DBI extension module adding database emulation via flat-files 
to Perl's database-independent database interface.  Unlike other DBD::modules, 
DBD::Sprite does not require you to purchase or obtain a database.  Every 
thing you need to prototype database-independent applications using Perl and 
DBI are included here.  You will, however, probably wish to obtain a real 
database, such as "mysql", for your production and larger data needs.  This 
is because emulating databases and SQL with flat text files gets very slow as 
the size of your "database" grows to a non-trivial size (a few dozen records 
or so per table).  

DBD::Sprite is built upon an old Perl module called "Sprite", written by 
Shishir Gurdavaram.  This code was used as a starting point.  It was completly 
reworked and many new features were added, producing a module called 
"JSprite.pm" (Jim Turner's Sprite).  This was then merged in to DBI::DBD to 
produce what you are installing now.  (DBD::Sprite).  JSprite.pm is included 
in this module as a separate file, and is required.

Many thanks go to Mr. Gurdavaram.

The main advantage of DBD::Sprite is the ability to develop and test 
prototype applications on personal machines (or other machines which do not 
have an Oracle licence or some other "mainstream" database) before releasing 
them on "production" machines which do have a "real" database.  This can all 
be done with minimal or no changes to your Perl code.

Another advantage of DBD::Sprite is that you can use Perl's regular 
expressions to search through your data.  Maybe, someday, more "real" 
databases will include this feature too!

DBD::Sprite provides the ability to emulate basic database tables
and SQL calls via flat-files.  The primary use envisioned
for this to permit website developers who can not afford
to purchase an Oracle licence to prototype and develop Perl 
applications on their own equipment for later hosting at 
larger customer sites where Oracle is used.  :-)

DBD::Sprite attempts to do things in as database-independent manner as possible, 
but where differences occurr, JSprite most closely emmulates Oracle, for 
example "sequences/autonumbering".  JSprite uses tiny one-line text files 
called "sequence files" (.seq).  and "seq_file_name.NEXTVAL" function to 
insert into autonumbered fields.  The reason for this is that the Author 
works in an Oracle shop and wrote this module to allow himself to work on 
code on his PC, and machines which did not have Oracle on them, since 
obtaining Oracle licences was sometimes time-consuming.

DBD::Sprite is similar to DBD::CSV, but differs in the following ways:  

	1) It creates and works on true "databases" with user-ids and passwords,
	real datatypes like numeric, varchar, blob, etc. with max. precisions and 
	scales.

	2) The	database author specifies the field delimiters, record delimiters, 
	user, password, table file path, AND extension for each database. 

	3) Transactions (commits and rollbacks) are fully supported! 

	4) Autonumbering and user-defined functions are supported.

	5) You don't need any other modules or databases.  (NO prerequisites 
	except Perl 5 and the DBI module!

	6) Quotes are not used around data.

	7) It is not necessary to call the "$dbh->quote()" method all the time 
	in your sql.

	8) NULL is handled as an empty string.

	9) Users can "register" their own data-conversion functions for use in
	sql.  See "fn_register" method below.

	10) Optional data encryption.

	11) Optional table storage in XML format.
	
	12) Two-table joins now supported!


=head1 INSTALLATION

    Installing this module (and the prerequisites from above) is quite
    simple. You just fetch the archive, extract it with

        gzip -cd DBD-Sprite-0.1000.tar.gz | tar xf -

    (this is for Unix users, Windows users would prefer WinZip or something
    similar) and then enter the following:

        cd DBD-Sprite-#.###
        perl Makefile.PL
        make
        make test

    If any tests fail, let me know. Otherwise go on with

        make install

    Note that you almost definitely need root or administrator permissions.
    If you don't have them, read the ExtUtils::MakeMaker man page for
    details on installing in your own directories. the ExtUtils::MakeMaker
    manpage.

	NOTE:  You may also need to copy "makesdb.pl" to /usr/local/bin or 
	somewhere in your path.

=head1 GETTING STARTED:

	1) cd to where you wish to store your database.
	2) run makesdb.pl to create your database, ie.
	
		Database name: mydb
		Database user: me
		User password: mypassword
		Database path: .
		Table file extension (default .stb): 
		Record delimiter (default \n): 
		Field delimiter (default ::): 

		This will create a new database text file (mydb.sdb) in the current 
		directory.  This ascii file contains the information you enterred 
		above.  To add additional user-spaces, simply rerun makesdb.pl with 
		"mydb" as your database name, and enter additional users (name, 
		password, path, extension, and delimiters).  For an example, after 
		running "make test", look at the file "test.sdb".		
		
		When connecting to a Sprite database, Sprite will look in the current 
		directory, then, if specified, the path in the SPRITE_HOME environment 
		variable.

		The database name, user, and password are used in the "db->connect()" 
		method described below.  The "database path" is where your tables will 
		be created and reside.  Table files are ascii text files which will 
		have, by default, the extension ".stb" (Sprite table).  By default, 
		each record will be written to a single line (separated by \n -- 
		Windows users should probably use "\r\n").  Each field datum will be 
		written without quotes separated by the "field delimiter (default: 
		double-colon).  The first line of the table file consists of the 
		a field name, an equal ("=") sign, an asterisk if it is a key field, 
		then the datatype and size.  This information is included for each 
		field and separated by the field separator.  For an example, after 
		running "make test", look at the file "testtable.stb".		

	3) write your script to use DBI, ie:
	
		#!/usr/bin/perl
		use DBI;
		
		$dbh = DBI->connect('DBI:Sprite:mydb','me','mypassword') || 
				die "Could not connect (".$DBI->err.':'.$DBI->errstr.")!";
		...
		#CREATE A TABLE, INSERT SOME RECORDS, HAVE SOME FUN!
		
	4) get your application working.
	
	5) rehost your application on a "production" machine and change "Sprite" 
	to a DBI driver for a "real" database!

=head1 CREATING AND DROPPING TABLES

    You can create and drop tables with commands like the following:

        $dbh->do("CREATE TABLE $table (id INTEGER, name CHAR(64))");
        $dbh->do("DROP TABLE $table");

    Column names, datatypes, precision, scales, and autonumber sequences are 
    stored on the top line as COLUNM_NAME(PRECISION[,SCALE])=DEFAULT_VALUE

    A drop just removes the file without any warning.

    See the DBI(3) manpage for more details.

    Table names cannot be arbitrary, due to restrictions of the SQL syntax.
    I recommend that table names are valid SQL identifiers: The first
    character is alphabetic, followed by an arbitrary number of alphanumeric
    characters. If you want to use other files, the file names must start
    with '/', './' or '../' and they must not contain white space.

=head1 INSERTING, FETCHING AND MODIFYING DATA

    The following examples insert some data in a table and fetch it back:
    First all data in the string:

        $dbh->do("INSERT INTO $table VALUES (1, 'foobar')");

    Note the use of the quote method for escaping the word 'foobar'. Any
    string must be escaped, even if it doesn't contain binary data.

    Next an example using parameters:

        $dbh->do("INSERT INTO $table VALUES (?, ?)", undef,
                 2, "It's a string!");

    To retrieve data, you can use the following:

        my($query) = "SELECT * FROM $table WHERE id > 1 ORDER BY id";
        my($sth) = $dbh->prepare($query);
        $sth->execute();
        while (my $row = $sth->fetchrow_hashref) {
            print("Found result row: id = ", $row->{'id'},
                  ", name = ", $row->{'name'});
        }
        $sth->finish();

    Again, column binding works: The same example again.

        my($query) = "SELECT * FROM $table WHERE id > 1 ORDER BY id";
        my($sth) = $dbh->prepare($query);
        $sth->execute();
        my($id, $name);
        $sth->bind_columns(undef, \$id, \$name);
        while ($sth->fetch) {
            print("Found result row: id = $id, name = $name\n");
        }
        $sth->finish();

    Of course you can even use input parameters. Here's the same example for
    the third time:

        my($query) = "SELECT * FROM $table WHERE id = ?";
        my($sth) = $dbh->prepare($query);
        $sth->bind_columns(undef, \$id, \$name);
        for (my($i) = 1;  $i <= 2;   $i++) {
            $sth->execute($id);
            if ($sth->fetch) {
                print("Found result row: id = $id, name = $name\n");
            }
            $sth->finish();
        }

    See the DBI(3) manpage for details on these methods. See the
    SQL::Statement(3) manpage for details on the WHERE clause.

    Data rows are modified with the UPDATE statement:

        $dbh->do("UPDATE $table SET id = 3 WHERE id = 1");

    Likewise you use the DELETE statement for removing rows:

        $dbh->do("DELETE FROM $table WHERE id > 1");

I<fn_register>

Method takes 2 arguments:  Function name and optionally, a
package name (default is "main").

		$dbh->fn_register ('myfn','mypackage');
  
-or-

		use JSprite;
		JSprite::fn_register ('myfn',__PACKAGE__);

Then, you could say in sql:

	insert into mytable values (myfn(?))
	
and bind some value to "?", which is passed to "myfn", and the return-value 
is inserted into the database.  You could also say (without binding):

	insert into mytable values (myfn('mystring'))
	
-or (if the function takes a number)-

	select field1, field2 from mytable where field3 = myfn(123) 
	
I<Return Value>

	None

=head1 ERROR HANDLING

    In the above examples we have never cared about return codes. Of course,
    this cannot be recommended. Instead we should have written (for
    example):

        my($query) = "SELECT * FROM $table WHERE id = ?";
        my($sth) = $dbh->prepare($query)
            or die "prepare: " . $dbh->errstr();
        $sth->bind_columns(undef, \$id, \$name)
            or die "bind_columns: " . $dbh->errstr();
        for (my($i) = 1;  $i <= 2;   $i++) {
            $sth->execute($id)
                or die "execute: " . $dbh->errstr();
            if ($sth->fetch) {
                print("Found result row: id = $id, name = $name\n");
            }
        }
        $sth->finish($id)
            or die "finish: " . $dbh->errstr();

    Obviously this is tedious. Fortunately we have DBI's *RaiseError*
    attribute:

        $dbh->{'RaiseError'} = 1;
        $@ = '';
        eval {
            my($query) = "SELECT * FROM $table WHERE id = ?";
            my($sth) = $dbh->prepare($query);
            $sth->bind_columns(undef, \$id, \$name);
            for (my($i) = 1;  $i <= 2;   $i++) {
                $sth->execute($id);
                if ($sth->fetch) {
                    print("Found result row: id = $id, name = $name\n");
                }
            }
            $sth->finish($id);
        };
        if ($@) { die "SQL database error: $@"; }

    This is not only shorter, it even works when using DBI methods within
    subroutines.

=head1 METADATA

    The following attributes are handled by DBI itself and not by DBD::File,
    thus they should all work as expected:  I have only used the last 3.

I<Active>

I<ActiveKids>

I<CachedKids>

I<CompatMode> (Not used)

I<InactiveDestroy>

I<Kids>

I<PrintError>

I<RaiseError>

I<Warn>

    The following DBI attributes are handled by DBD::Sprite:

B<AutoCommit>

        Works

B<ChopBlanks>

        Should Work

B<NUM_OF_FIELDS>

        Valid after `$sth->execute'

B<NUM_OF_PARAMS>

        Valid after `$sth->prepare'

B<NAME>

        Valid after `$sth->execute'; undef for Non-Select statements.

B<NULLABLE>

        Not really working. Always returns an array ref of one's, as
        DBD::Sprite always allows NULL (handled as an empty string). 
        Valid after `$sth->execute'.
        
B<PRECISION>

   		Works
   		
B<SCALE>

		Works

B<LongReadLen>

    		Should work

B<LongTruncOk>

    		Works

These attributes and methods are not supported:

B<bind_param_inout>

B<CursorName>


    In addition to the DBI attributes, you can use the following dbh
    attributes.  These attributes are read-only after "connect".

I<sprite_dbdir>

    		Path to tables for database.
    		
I<sprite_dbext>

		File extension used on table files in the database.
		
I<sprite_dbuser>

		Current database user.
		
I<sprite_dbfdelim>

		Field delimiter string in use for the database.
		
I<sprite_dbrdelim>

		Record delimiter string in use for the database.

	The following are environment variables specifically recognized by Sprite.

I<SPRITE_HOME>
		Environment variable specifying a path to search for Sprite 
		databases (*.sdb) files.


	The following are Sprite-specific options which can be set when connecting.

I<sprite_CaseTableNames> => 0 | 1

		By default, table names are case-insensitive (as they are in Oracle), 
		to make table names case-sensitive (as in MySql), so that one could 
		have two separate tables such as "test" and "TEST", set this option 
		to 1.

I<sprite_CaseFieldNames> => 0 | 1

		By default, field names are case-insensitive (as they are in Oracle), 
		to make field names case-sensitive, so that one could 
		have two separate fields such as "test" and "TEST", set this option 
		to 1.  The default is 1 (case-sensitive) if XML.

I<sprite_StrictCharComp> => 0 | 1

		CHAR fields are always right-padded with spaces to fill out 
		the field.  Old (pre 5.17) Sprite behaviour was to require the 
		padding be included in literals used for testing equality in 
		"where" clauses. 	I discovered that Oracle and some other databases 
		do not require this when testing DBIx-Recordset, so Sprite will 
		automatically right-pad literals when testing for equality.  
		To disable this and force the old behavior, set this option to 1.
		
I<sprite_Crypt> => [encrypt=|decrypt=][Crypt]::CBC;][[IDEA[_PP]|DES[_PP]|BLOWFISH[_PP];]keystring
	
		Optional encryption and/or decryption of data stored in tables.  By 
		omitting "encrypt=" and "decrypt=", data will be decrypted when read 
		from the table and encrypted when written to the table using the 
		"keystring" as the key.
		
I<sprite_forcereplace> => 0 | 1
	
		This option forces the table file to first be deleted before being 
		overwritten.  Default is 0 (do not delete, just overwrite it).  This 
		was need by the author on certain network filesystems on one jobsite.
		
I<sprite_xsl> => xsl_stylesheet_url
	
		Optional xsl stylesheet url to be included in database tables in XML 
		format.  Otherwise, ignored.  Default none.

I<silent> => 0 | 1
	
		By default, on error, Sprite prints the legacy 
		"Oops! Sprite encountered the following error when processing your request..." 
		multiline error message carried over from the original Sprite by 
		Shishir Gurdavaram.  Set to 1 to silense this, if it annoys you, or if you 
		are using Sprite in a CGI script.

	The following attributes can be specified as a hash reference in "prepare" 
	statements:
	
I<sprite_reclimit> => #
	
		Limit processing the table to # records.  This is NOT the same as a 
		"LIMIT #" clause in selects.  This limits the query to the first # 
		records in the table UNSORTED - BEFORE any constraints or sorting are 
		applied.  This is useful for limiting queries to, say 1 record 
		simply to populate the column metadata.
		
I<sprite_actlimit> => #
	
		This is the same as adding a "LIMIT #" clause to a select statement 
		when preparing it, as it will limit a query to returning # records 
		AFTER applying any constraints and sorting.
	
=head1 DRIVER PRIVATE METHODS

B<DBI>->B<data_sources>()

        The `data_sources' method returns a list of "databases" (.sdb files) 
        found in the current directory and, if specified, the path in 
        the SPRITE_HOME environment variable.
        
$dbh->B<tables>()

        This method returns a list of table names specified in the current 
        database.
        Example:

            my($dbh) = DBI->connect("DBI:Sprite:mydatabase",'me','mypswd');
            my(@list) = $dbh->func('tables');

B<JSprite::fn_register>('myfn', __PACKAGE__);

		This method takes the name of a user-defined data-conversion function 
		for use in SQL commands.  Your function can optionally take arguments, 
		but should return a single number or string.  Unless your function 
		is defined in package "main", you must also specify the package name 
		or "__PACKAGE__" for the current package.  For an example, see the 
		section "INSERTING, FETCHING AND MODIFYING DATA" above or (JSprite(3)).
		
=head1 OTHER SUPPORTING UTILITIES

B<makesdb.pl>

		This utility lets you build new Sprite databases and later add 
		additional user-spaces to them.  Simply cd to the directory where 
		you wish to create / modify a database, and run.  It prompts as 
		follows:
		
		Database name: Enter a 1-word name for your database.
		Database user: Enter a 1-word user-name.
		User password: Enter a 1-word password for this user.
		Database path: Enter a path (no trailing backslash) to store tables.
		Table file extension (default .stb): 
		Record delimiter (default \n): 
		Field delimiter (default ::): 

		The last 6 prompts repeat until you do not enter another user-name 
		allowing you to set up multiple users in a single database.  Each 
		"user" can have it's own separate tables by specifying different 
		paths, file-extensions, password, and delimiters!  You can invoke 
		"makesdb.pl" on an existing database to add new users.  You can 
		edit it with vi to remove users, delete the 5 lines starting with 
		the path for that user.  The file is all text, except for the 
		password, which is encrypted for your protection!
		
=head1 RESTRICTIONS

	Although DBD::Sprite supports the following datatypes:
		NUMBER FLOAT DOUBLE INT INTEGER NUM CHAR VARCHAR VARCHAR2 
		DATE LONG BLOB and MEMO, there are really only 4 basic datatypes 
		(NUMBER, CHAR, VARCHAR, and BLOB).  This is because Perl treates 
		everything as simple strings.  The first 5 are all treated as "numbers" 
		by Perl for sorting purposes and the rest as strings.  This is seen 
		when sorting, ie NUMERIC types sort as 1,5,10,40,200, whereas 
		STRING types sort these as 1,10,200,40,5.  CHAR fields are right-
		padded with spaces when stored.  LONG-type fields are subject to 
		truncation by the "LongReadLen" attribute value.

	DBD::Sprite works with the tieDBI module, if "Sprite => 1" lines are added 
	to the "%CAN_BIND" and "%CAN_BINDSELECT" hashes.  This should not be 
	necessary, and I will investigate when I have time.
	
=head1 KNOWN BUGS

    *       The module is using flock() internally. However, this function is
            not available on platforms. Using flock() is disabled on MacOS
            and Windows 95: There's no locking at all (perhaps not so
            important on these operating systems, as they are for single
            users anyways).


=head1 SEE ALSO

B<DBI(3)>, B<perl(1)>

=cut

package DBD::Sprite;

#no warnings 'uninitialized';

use strict;
#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw($VERSION $err $errstr $state $sqlstate $drh $i $j $dbcnt);

#require Exporter;

#@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
#@EXPORT = qw(

#);
$VERSION = '6.11';

# Preloaded methods go here.

$err = 0;	# holds error code   for DBI::err
$errstr = '';	# holds error string for DBI::errstr
$sqlstate = '';
$drh = undef;	# holds driver handle once initialised

sub driver{
    return $drh if $drh;
    my($class, $attr) = @_;

    $class .= "::dr";

    # not a 'my' since we use it above to prevent multiple drivers
    $drh = DBI::_new_drh($class, { 'Name' => 'Sprite',
				   'Version' => $VERSION,
				   'Err'    => \$DBD::Sprite::err,
				   'Errstr' => \$DBD::Sprite::errstr,
				   'State' => \$DBD::Sprite::state,
				   'Attribution' => 'DBD::Sprite by Shishir Gurdavaram & Jim Turner',
				 });
    $drh;
}

sub DESTROY   #ADDED 20001108
{
}

#sub AUTOLOAD {
#	print "***** AUTOLOAD CALLED! *****\n";
#}

1;


package DBD::Sprite::dr; # ====== DRIVER ======
use strict;
use vars qw($imp_data_size);

$DBD::Sprite::dr::imp_data_size = 0;

sub connect {
    my($drh, $dbname, $dbuser, $dbpswd, $attr, $old_driver, $connect_meth) = @_;

#DON'T PASS ATTRIBUTES IN AS A STRING, MUST BE A HASH-REF!

    my($port);
    my($cWarn, $i, $j);

	$_ = '';    #ONLY WAY I KNOW HOW TO RETURN ERRORS FROM HERE ($DBI::err WON'T WORK!)

    # Avoid warnings for undefined values
    $dbuser ||= '';
    $dbpswd ||= '';

    # create a 'blank' dbh
    my($privateattr) = {
		'Name' => $dbname,
		'user' => $dbuser,
		'dbpswd' => $dbpswd
    };
    #if (!defined($this = DBI::_new_dbh($drh, {
    my $this = DBI::_new_dbh($drh, {
    		'Name' => $dbname,
    		'USER' => $dbuser,
    		'CURRENT_USER' => $dbuser,
    });
    
    # Call Sprite Connect function
    # and populate internal handle data.
	if ($this)   #ADDED 20010226 TO FIX BAD ERROR MESSAGE HANDLING IF INVALID UN/PW ENTERED.
	{
		my $dbfid = $dbname;
		$dbfid .= '.sdb'  unless ($dbfid =~ /\.\w+$/);
		$ENV{SPRITE_HOME} ||= '';
		if ($dbfid =~ m#^/#)
		{
			unless (open(DBFILE, "<$dbfid"))
			{
				#DBI::set_err($this, -1, "No such database ($dbname)!");  #REPLACED W/NEXT LINE 20021021!
				warn "No such database ($dbname)!"  if ($attr->{PrintError});
				$_ = "-1:No such database ($dbname)!";
				return undef;
			}
		}
		else
		{
			unless (open(DBFILE, "<$ENV{SPRITE_HOME}/$dbfid"))
			{
				unless (open(DBFILE, "<$dbfid"))
				{
					unless (open(DBFILE, "<$ENV{HOME}/$dbfid"))  #NEXT 4 ADDED 20040909
					{
						my $pgmhome = $0;
						$pgmhome =~ s#[^/\\]*$##;  #SET NAME TO SQL.PL FOR ORAPERL!
						$pgmhome ||= '.';
						$pgmhome .= '/'  unless ($pgmhome =~ m#\/$# || $dbfid =~ m#^\/#);
						unless (open(DBFILE, "<${pgmhome}$dbfid"))
						{
							$_ = "-1:No such database ($dbname) ($!)!";
							DBI::set_err($this, -1, $_);  #REPLACED W/NEXT LINE 20021021!
							warn $DBI::errstr  if ($attr->{PrintError});
							return undef;
						}
					}
				}
			}
		}
		my (@dbinputs) = <DBFILE>;
		foreach $i (0..$#dbinputs)
		{
			chomp ($dbinputs[$i]);
		}
		my ($inputcnt) = $#dbinputs;
		my ($dfltattrs, %dfltattr);
		for ($i=0;$i<=$inputcnt;$i+=5)  #SHIFT OFF LINES UNTIL RIGHT USER FOUND.
		{
			last  if ($dbinputs[1] eq $dbuser);
			if ($dbinputs[1] =~ s/^$dbuser\:(.*)/$dbuser/)
			{
				$dfltattrs = $1;
				eval "\%dfltattr = ($dfltattrs)";
				foreach my $j (keys %dfltattr)
				{
					#$attr->{$j} = $dfltattr{$j};  #CHGD. TO NEXT 20030207
					$attr->{$j} = $dfltattr{$j}  unless (defined $attr->{$j});
				}
				last;
			}
			for ($j=0;$j<=4;$j++)
			{
				shift (@dbinputs);
			}
		}
#foreach my $x (keys %{$attr}) { print STDERR "-attr($x)=$attr->{$x}=\n"; };
		if ($dbinputs[1] eq $dbuser)
		{
			#if ($dbinputs[2] eq crypt($dbpswd, substr($dbuser,0,2)))
			my ($crypted);
			eval { $crypted = crypt($dbpswd, substr($dbuser,0,2)); };
			if ($dbinputs[2] eq $crypted || $@ =~ /excessive paranoia/)
			{
				++$DBD::Sprite::dbcnt;
				$this->STORE('sprite_dbname',$dbname);
				$this->STORE('sprite_dbuser',$dbuser);
				$this->STORE('sprite_dbpswd',$dbpswd);
				close (DBFILE);
				#$this->STORE('sprite_autocommit',0);  #CHGD TO NEXT 20010912.
				$this->STORE('sprite_autocommit',($attr->{AutoCommit} || 0));
				$this->STORE('sprite_SpritesOpen',{});
				my ($t) = $dbinputs[0];
				$t =~ s#(.*)/.*#$1#;
				if ($dbinputs[0] =~ /(.*)(\..*)/)
				{
					$this->STORE('sprite_dbdir', $t);
					$this->STORE('sprite_dbext', $2);
				}
				else
				{
					$this->STORE('sprite_dbdir', $dbinputs[0]);
					$this->STORE('sprite_dbext', '.stb');
				}
				for (my $i=0;$i<=$#dbinputs;$i++)
				{
					$dbinputs[$i] =~ /^(.*)$/;
					$dbinputs[$i] = $1;
				}
				$this->STORE('sprite_dbfdelim', $attr->{sprite_read} || $attr->{sprite_field} || eval("return(\"$dbinputs[3]\");") || '::');
				$this->STORE('sprite_dbwdelim', $attr->{sprite_write} || $attr->{sprite_field} || eval("return(\"$dbinputs[3]\");") || '::');
				$this->STORE('sprite_dbrdelim', $attr->{sprite_record} || eval("return(\"$dbinputs[4]\");") || "\n");
				$this->STORE('sprite_attrhref', $attr);
				$this->STORE('AutoCommit', ($attr->{AutoCommit} || 0));

				$this->STORE('sprite_autocommit',($attr->{AutoCommit} || 0));

				#NOTE:  "PrintError" and "AutoCommit" are ON by DEFAULT!
				#I KNOW OF NO WAY TO DETECT WHETHER AUTOCOMMIT IS SET BY 
				#DEFAULT OR BY USER IN "AutoCommit => 1", THEREFORE I CAN'T 
				#FORCE THE DEFAULT TO ZERO.  JWT

				return $this;
			}
		}
	}
	close (DBFILE);
	#DBI::set_err($this, -1, "Invalid username/password!");  #REPLACED W/NEXT LINE 20021021!
	warn "Invalid username/password!"  if ($attr->{PrintError});
	$_ = "-1:Invalid username/password!";
	return undef;
}

sub data_sources
{
	my ($self) = shift;

	my (@dsources) = ();
	my $path;
	if (defined $ENV{SPRITE_HOME})
	{
		$path = "$ENV{SPRITE_HOME}/*.sdb";
		my $code = "while (my \$i = <$path>)\n";
		$code .= <<'END_CODE';
		{
			chomp ($i);
			push (@dsources,"DBI:Sprite:$1")  if ($i =~ m#([^\/\.]+)\.sdb$#);
		}
END_CODE
		eval $code;
		$code =~ s/\.sdb([\>\$])/\.SDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
		eval $code;
	}
	$path = '*.sdb';
	my $code = "while (my \$i = <$path>)\n";
	$code .= <<'END_CODE';
	{
		chomp ($i);
		push (@dsources,"DBI:Sprite:$1")  if ($i =~ m#([^\/\.]+)\.sdb$#);
	}
END_CODE
	eval $code;
	$code =~ s/\.sdb([\>\$])/\.SDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
	eval $code;
	unless (@dsources)
	{
		if (defined $ENV{HOME})
		{
			$path = "$ENV{HOME}/*.sdb";
			my $code = "while (my \$i = <$path>)\n";
			$code .= <<'END_CODE';
			{
				chomp ($i);
				push (@dsources,"DBI:Sprite:$1")  if ($i =~ m#([^\/\.]+)\.sdb$#);
			}
END_CODE
			eval $code;
			$code =~ s/\.sdb([\>\$])/\.SDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
			eval $code;
		}
	}
	return (@dsources);
}

sub DESTROY
{
    my($drh) = shift;
    
#	if ($drh->FETCH('AutoCommit') == 1)   #REMOVED 20020225 TO ELIMINATE -w WARNING.
#	{
#		$drh->STORE('AutoCommit',0);
#		$drh->rollback();                #COMMIT IT IF AUTOCOMMIT ON!
#		$drh->STORE('AutoCommit',1);
#	}
	$drh = undef;
}

sub disconnect_all
{
}

sub admin {                 #I HAVE NO IDEA WHAT THIS DOES!
    my($drh) = shift;
    my($command) = shift;

    my($dbname) = ($command eq 'createdb'  ||  $command eq 'dropdb') ?
			shift : '';
    my($host, $port) = DBD::Sprite->_OdbcParseHost(shift(@_) || '');
    my($user) = shift || '';
    my($password) = shift || '';

    $drh->func(undef, $command,
	       $dbname || '',
	       $host || '',
	       $port || '',
	       $user, $password, '_admin_internal');
}

1;


package DBD::Sprite::db; # ====== DATABASE ======
use strict;
use JSprite;

$DBD::Sprite::db::imp_data_size = 0;
use vars qw($imp_data_size);

sub last_insert_id     #MUST BE CALLED W/"$dbh->func"!   ADDED 20040407 TO SUPPORT NEW DBI FUNCTION.
{
	my ($resptr, $cat, $schema, $tablename, $seqfield) = @_;
	return $resptr->{sprite_insertid}  if (defined $resptr->{sprite_insertid} && $resptr->{sprite_insertid} =~ /\d$/);
	my $mycsr;
	if ($mycsr = $resptr->prepare("select ${seqfield}.CURRVAL from DUAL"))
	{
		my $myexe;
		if ($myexe = $mycsr->execute())
		{
			my ($lastseq) = $mycsr->fetchrow_array();
			$mycsr->finish();
			###return $lastseq  if ($lastseq =~ /\d$/);  #CHGD. TO NEXT 20061006 TO HANDLE ERRORS, IE. WHEN SEQ IS AN AUTONUMBER, NOT A SEQ!
			return $lastseq  if ($lastseq =~ /\d$/ && $lastseq > 0);
		}
	}
	if ($seqfield)    #IF ALL ELSE FAILS, FETCH A DESCENDING LIST OF VALUES FOR THE FIELD THE SEQUENCE WAS INSERTED INTO (USER MUST SPECIFY THE FIELD!)
	{
		my $sql = <<END_SQL;
			select $seqfield
			from $tablename
			order by $seqfield desc
END_SQL
		if ($mycsr = $resptr->prepare($sql))
		{
			my $myexe;
			if ($myexe = $mycsr->execute())
			{
				my ($lastseq) = $mycsr->fetchrow_array();
				$mycsr->finish();
				return $lastseq;
			}
			else
			{
				return undef;
			}
		}
		return undef;
	}
	return undef;
}

sub Statement     #MUST BE CALLED W/"dbh->func([undef, undef, 'tablename', 'seq/field name',] 'last_insert_id')"!   ADDED 20040407 TO SUPPORT NEW DBI FUNCTION.
{
	return undef  unless ($_[0]);
	return $_[0]->FETCH('sprite_last_prepare_sql');
}

sub prepare
{
	my ($resptr, $sqlstr, $attribs) = @_;
	my ($indx, @QS);
	local ($_);
	#$sqlstr =~ s/\n/ /g;  #REMOVED 20011107.
	
	#DBI::set_err($resptr, 0, '');   #CHGD. TO NEXT 20041104.
	DBI::set_err($resptr, undef);

	my $limit = ($sqlstr =~ s/^(.+)\s*limit\s+(\d+)\s*$/$1/i) ? $2 : 0;     #ADDED 20160111 TO SUPPORT "limit #" ON QUERIES.
 	$sqlstr =~ s/^\s*listfields\s+(\w+)/select * from $1 where 1 = 0/i;  #ADDED 20030901.
	my $csr = DBI::_new_sth($resptr, {
		'Statement' => $sqlstr,
	});

	my ($spritefid);
	$resptr->STORE('sprite_last_prepare_sql', $sqlstr);
	$csr->STORE('sprite_fetchcnt', 0);
	$csr->STORE('sprite_reslinev','');
	$sqlstr =~ s/\\\'|\'\'/\x02\^3jSpR1tE\x02/gso; #PROTECT "\'" IN QUOTES.
	$sqlstr =~ s/\\\"|\"\"/\x02\^4jSpR1tE\x02/gso; #PROTECT "\"" IN QUOTES.
	$indx = 0;
	$indx++  while ($sqlstr =~ s/([\'\"])([^\1]*?)\1/
				$QS[$indx] = "$1$2"; "\$QS\[$indx]"/e);
	#$sqlstr =~ /(into|from|update|table) \s*(\w+)/gi;  #CHANGED 20000831 TO NEXT LINE!
	#$sqlstr =~ /(into|from|update|table|sequence)\s+(\w+)/is;  #CHGD. 20040305 TO NEXT.
	$spritefid = $2  if ($sqlstr =~ /(into|from|update|table|sequence)\s+(\w+)/ios);
	$spritefid = $1  if ($sqlstr =~ /primary_key_info\s+(\w+)/ios);
	unless ($spritefid)   #ADDED 20061010 TO SUPPORT "select fn" (like MySQL, et al.)
	{
		$spritefid = 'DUAL'  if ($sqlstr =~ s/^(\s*select\s+\w+\s*)(\(.*\))?$/$1$2 from DUAL/is);
	}
	
	unless ($spritefid)   #NEXT 5 ADDED 20000831!
	{
		DBI::set_err($resptr, -1, "Prepare:(bad sql) Must specify a table name!");
		return undef;
	}
	$spritefid =~ tr/A-Z/a-z/  unless ($resptr->{sprite_attrhref}->{sprite_CaseTableNames});
	$csr->STORE('sprite_spritefid', $spritefid);

	my $join = 0;
	my $joininfo;
	#$joininfo = $1  if ($sqlstr =~ /from\s+([\w\.\, ]+)\s*(?:where|order\s+by)/is);
	#$joininfo = $1  if (!$joininfo && $sqlstr =~ /from\s+([\w\.\, ]+)/is);
	#LAST 2 CHGD. TO NEXT 2 20040914.
	$joininfo = $1  if ($sqlstr =~ /from\s+([\w\.\,\s]+)\s*(?:where|order\s+by)/iso);
	$joininfo = $1  if (!$joininfo && $sqlstr =~ /from\s+([\w\.\,\s]+)/iso);
	my @joinfids;
	@joinfids = split(/\,\s*/o, $joininfo)  if (defined $joininfo);
	my (@joinfid, @joinalias);
	if ($#joinfids >= 1)
	{
		unless ($#joinfids == 1)
		{
			DBI::set_err($resptr, -1, "Only 2-table joins currently supported!");
			return undef;
		}
		for (my $i=0;$i<=$#joinfids;$i++)
		{
			($joinfid[$i], $joinalias[$i]) = split(/\s+/o, $joinfids[$i]);
			$joinfid[$i] ||= $joinfids[$i];
			$joinfid[$i] =~ tr/A-Z/a-z/  unless ($resptr->{sprite_attrhref}->{sprite_CaseTableNames});
		}
		$csr->STORE('sprite_joinfid', \@joinfid);
		$csr->STORE('sprite_joinalias', \@joinalias);
		$join = 1;
	}
	#CHECK TO SEE IF A PREVIOUSLY-CLOSED SPRITE OBJECT EXISTS FOR THIS TABLE.
	#IF SET, THE "RECYCLE" OPTION TELLS SPRITE NOT TO RELOAD THE TABLE DATA.
	#THIS IS USEFUL TO SAVE TIME AND MEMORY FOR APPS DOING MULTIPLE 
	#TRANSACTIONS ON SEVERAL LARGE TABLES.
	#RELOADING IS NECESSARY, HOWEVER, IF ANOTHER USER CAN CHANGE THE 
	#DATA SINCE YOUR LAST COMMIT, SO RECYCLE IS OFF BY DEFAULT!
	#THE SPRITE HANDLE AND ALL IT'S BASIC CONFIGURATION IS RECYCLED REGARDLESS.
	my (@spritedbs) = (qw(sprite_spritedb sprite_joindb));
	my ($myspriteref);
	my $i = 0;
	$myspriteref = undef;
	foreach my $fid ($spritefid, $joinfid[1])
	{
		last  unless ($fid);
		if (ref($resptr->{'sprite_SpritesOpen'}) && ref($resptr->{'sprite_SpritesOpen'}->{$fid}))
		{
			$myspriteref = ${$resptr->{'sprite_SpritesOpen'}->{$fid}};
			$csr->STORE($spritedbs[$i], ${$resptr->{'sprite_SpritesOpen'}->{$fid}});
			$myspriteref->{TYPE} = undef;
			$myspriteref->{NAME} = undef;
			$myspriteref->{PRECISION} = undef;
			$myspriteref->{SCALE} = undef;
		}
		else   #CREATE A NEW SPRITE OBJECT.
		{
			$myspriteref = new JSprite(%{$resptr->{sprite_attrhref}});
			unless ($myspriteref)
			{
				DBI::set_err($resptr, -1, "Unable to create JSprite handle ($@)!");
				return undef;
			}
			$csr->STORE($spritedbs[$i], $myspriteref);
			my ($openhash) = $resptr->FETCH('sprite_SpritesOpen');
			$openhash->{$fid} = \$myspriteref;
			$myspriteref->set_delimiter("-read",($attribs->{sprite_read} || $attribs->{sprite_field} || $resptr->FETCH('sprite_dbfdelim')));
			$myspriteref->set_delimiter("-write",($attribs->{sprite_write} || $attribs->{sprite_field} || $resptr->FETCH('sprite_dbwdelim')));
			$myspriteref->set_delimiter("-record",($attribs->{sprite_record} || $attribs->{sprite_field} || $resptr->FETCH('sprite_dbrdelim')));
			$myspriteref->set_db_dir($resptr->FETCH('sprite_dbdir'));
			$myspriteref->set_db_ext($resptr->FETCH('sprite_dbext'));
			$myspriteref->{CaseTableNames} = $resptr->{sprite_attrhref}->{sprite_CaseTableNames};
			$myspriteref->{sprite_CaseFieldNames} = $resptr->{sprite_attrhref}->{sprite_CaseFieldNames};
			$myspriteref->{StrictCharComp} = $resptr->{sprite_attrhref}->{sprite_StrictCharComp};
			#DON'T NEED!#$myspriteref->{Crypt} = $resptr->{sprite_attrhref}->{sprite_Crypt};  #ADDED 20020109.
			$myspriteref->{sprite_forcereplace} = $resptr->{sprite_attrhref}->{sprite_forcereplace};  #ADDED 20010912.
			$myspriteref->{dbuser} = $resptr->FETCH('sprite_dbuser');  #ADDED 20011026.
			$myspriteref->{dbname} = $resptr->FETCH('sprite_dbname');  #ADDED 20011026.
			$myspriteref->{dbhandle} = $resptr;  #ADDED 20020516
		}
		$myspriteref->{LongTruncOk} = $resptr->FETCH('LongTruncOk');
		my ($silent) = $resptr->FETCH('PrintError');
		$myspriteref->{silent} = ($silent ? 0 : 1);   #ADDED 20000103 TO SUPPRESS "OOPS" MSG ON WEBSITES!
		$myspriteref->{sprite_reclimit} = (defined $attribs->{sprite_reclimit}) ? $attribs->{sprite_reclimit} : 0;  #ADDED 20020123.
		$myspriteref->{sprite_sizelimit} = (defined $attribs->{sprite_sizelimit}) ? $attribs->{sprite_sizelimit} : 0;  #ADDED 20020530.
		$myspriteref->{sprite_actlimit} = $limit;  #ADDED 20160111 TO SUPPORT "limit #" ON QUERIES.
		++$i;
	}

	#PARSE OUT SQL IF JOIN.

	my $num_of_params;
	my @bindindices;
	my @joinsql;
	if ($join)
	{
		my ($whereclause, $joinfid);
		my %addfields;  #FIELDS IN UNION CRITERIA THAT MUST BE ADDED TO FETCH.
		my @selectfields;  #FIELD NAMES OF FIELDS TO BE FETCHED.
		my $addthesefields; #COLLECT LIST OF FIELDS THAT ACTUALLY NEED ADDING.
		my @union;  #LIST OF FIELDS IN THE JOIN UNION(S).
		my $listprefix;

		for (my $jj=0;$jj<=1;$jj++)
		{
			$joinsql[$jj] = $sqlstr;
			$joinfid = $joinalias[$jj] ? $joinalias[$jj] : $joinfid[$jj];
			%addfields = ();

			$joinsql[$jj] =~ s/^\s+//gso;  #STRIP LEADING, TRAILING SPACES.
			$joinsql[$jj] =~ s/\s+$//gso;

			#CONVERT ALL "jointable.fieldname" to "fieldname" & REMOVE ALL "othertables.fieldname".

			$joinsql[$jj] =~ s!^\s*select(?:\s*distinct)?\s+(.+)\s+from\s+!
					my $one = $1;
					$one =~ s/$joinfid\.//g;
					$one =~ s/\w+\.\w+(?:\s*\,)?//go;
					$one =~ s/\,\s*$//o;
					"select $one from "
			!eis;

			$whereclause = $1  if ($joinsql[$jj] =~ s/\s+where\s+(.+)$/ /iso);
#			$csr->STORE("sprite_where0", $whereclause)  unless ($jj);	
			unless ($jj)
			{
				my $unprotectedWhere = $whereclause;
				if ($whereclause =~ /\S/o)
				{
					#RESTORE QUOTED STRINGS AND ESCAPED QUOTES WITHIN THEM.
					1 while ($unprotectedWhere =~ s/\$QS\[(\d+)\]/
							my $one = $1;
							my $quotechar = substr($QS[$one],0,1);
							($quotechar.substr($QS[$one],1).$quotechar)
					/es);
					$unprotectedWhere =~ s/\x02\^4jSpR1tE\x02/\"\"/gso;   #UNPROTECT QUOTES WITHIN QUOTES!
					$unprotectedWhere =~ s/\x02\^3jSpR1tE\x02/\'\'/gso;
				}
				$csr->STORE("sprite_where0", $unprotectedWhere);	
			}


#			$whereclause =~ s/([\'\"])([^\1]*?)\1//g;   #STRIP OUT QUOTED STRINGS TO PREVENT INTERFEARANCE W/OTHER REGICES.
			$_ = $1  if ($joinsql[$jj] =~ /select\s+(.+?)\s+from\s+/o);
			s/\s+//go;
			@selectfields = split(/\,/o, $_);

			#DEAL WITH THE ORDER-BY CLAUSE, IF ANY.

			if ($whereclause =~ s/\s+order\s+by\s*(.*)//iso || $joinsql[$jj] =~ s/\s+order\s+by\s*(.*)//iso)
			{
				my $ordbyclause = $1;
				if ($jj)
				{
					$ordbyclause =~ s/(?:$joinalias[0]|$joinfid[0])\.\w+(?:\s+desc)?//gis;
				}
				else
				{
					$csr->STORE('sprite_joinorder', (
							($ordbyclause =~ /^(?:$joinalias[1]|$joinfid[1])\./)
							? 1 : 0));
					$ordbyclause =~ s/(?:$joinalias[1]|$joinfid[1])\.\w+(?:\s+desc)?\s*\,?//gis;
				}
				$ordbyclause =~ s/\w+\.(\w+)/$1/gs;
				$ordbyclause =~ s/\,\s*$//so;
				$ordbyclause =~ s/^\s*\,//so;
				$joinsql[$jj] .= " order by $ordbyclause"  if ($ordbyclause =~ /\S/o);
			}
			
			#ADD ANY FIELDS IN WHERE-CLAUSE BUT NOT FETCHED (WE MUST FETCH THEM)!
			@union = ();
			while ($whereclause =~ s/$joinfid\.(\w+)//is)
			{
				$addfields{$1} = 1;
				push (@union, "$joinfid.$1");
			}
			$csr->STORE("sprite_union$jj", [@union]);
			$joinsql[$jj] =~ s/$joinfid\.(\w+)/$1/gs;
#			unless ($whereclause)
#			{
#				DBI::set_err($resptr, -1, 'Join queries require "where"-clause!');
#				return undef;
#			}

			#REMOVE THE OTHER TABLES FROM THE FROM CLAUSE.

			#$joinsql[$jj] =~ s!\s+from\s+(\w+.*?)(\s+where.*)?$!" from $joinfid[$jj] $2"!egs;
			$joinsql[$jj] =~ s!\s+from\s+(\w+.*?)(\s+(?:where|order\s+by).*)?$!" from $joinfid[$jj] $2"!egs;

			#APPEND UNION FIELDS FROM JOINTABLE NOT IN SELECT LIST TO SELECT LIST.

			$addthesefields = '';
			$listprefix = '';
			unless ($selectfields[0] eq '*')
			{
outer:				foreach my $j (keys %addfields)
				{
					for (my $k=0;$k<=$#selectfields;$k++)
					{
						next outer  if ($selectfields[$k] eq $j);
#						$listprefix = ',';   #REMOVED 20040913
					}
					#$addthesefields .= $listprefix . $j;  #CHGD. TO NEXT 20040913
					$addthesefields .= $listprefix . $j . ',';
				}
				$addthesefields =~ s/\,$//o;
				#$joinsql[$jj] =~ s/\s+from\s+/ $addthesefields from /;  #CHGD. TO NEXT IF-STMT. 20040929.
				if ($addthesefields)
				{
					($joinsql[$jj] =~ s/^\s*select\s+from\s+$joinfid[$jj]/select $addthesefields from	$joinfid[$jj]/is)
							or
						($joinsql[$jj] =~ s/\s+from\s+$joinfid[$jj]/,$addthesefields from $joinfid[$jj]/is);
				}
			}
			#$csr->STORE("sprite_bi$jj", $bindindices[$jj]);
			$csr->STORE("sprite_joinnops$jj", 0);

			#RESTORE QUOTED STRINGS AND ESCAPED QUOTES WITHIN THEM.
			1 while ($joinsql[$jj] =~ s/\$QS\[(\d+)\]/
					my $one = $1;
					my $quotechar = substr($QS[$one],0,1);
					($quotechar.substr($QS[$one],1).$quotechar)
			/es);
			$joinsql[$jj] =~ s/\x02\^4jSpR1tE\x02/\"\"/gso;   #UNPROTECT QUOTES WITHIN QUOTES!
			$joinsql[$jj] =~ s/\x02\^3jSpR1tE\x02/\'\'/gso;
			$csr->STORE("sprite_joinstmt$jj", $joinsql[$jj]);	
		}
		$csr->STORE('sprite_joinparams', []);
	}
	else
	{
		$sqlstr =~ s/select\s+(.*?)\s+from\s+(\w+)\s+(\w+)\s+(where\s+.+|order\s+.+)?$/
				my ($one, $two, $three, $four) = ($1, $2, $3, $4);
				$one =~ s|\b$three\.(\w)|$1|g;
				$four =~ s|\b$three\.(\w)|$1|g;
				"select $one from $two $four"
		/eis;
	}
	
	#SET UP STMT. PARAMETERS.
	
	$csr->STORE('sprite_params', []);
	$num_of_params = ($sqlstr =~ tr/\?//);
	$sqlstr =~ s/\x02\^2jSpR1tE\x02/\?/gso;
	$csr->STORE('NUM_OF_PARAMS', $num_of_params);	
	$sqlstr = $joinsql[0]  if ($joinsql[0]);

	#RESTORE QUOTED STRINGS.
	1 while ($sqlstr =~ s/\$QS\[(\d+)\]/
			my $one = $1;
			my $quotechar = substr($QS[$one],0,1);
			($quotechar.substr($QS[$one],1).$quotechar)
	/es);
	#$sqlstr =~ s/\x02\^3jSpR1tE\x02/\"\"/gs;   #BUGFIX: CHGD NEXT 2 TO FOLLOWING 2 20050429.
	#$sqlstr =~ s/\x02\^2jSpR1tE\x02/\'\'/gs;
	$sqlstr =~ s/\x02\^4jSpR1tE\x02/\"\"/gso;   #UNPROTECT QUOTES WITHIN QUOTES!
	$sqlstr =~ s/\x02\^3jSpR1tE\x02/\'\'/gso;
	$csr->STORE('sprite_statement', $sqlstr);
	return ($csr);
}

sub parseParins  #RECURSIVELY ASSIGN ALL PARENTHAASZED EXPRESSIONS TO AN ARRAY TO PROTECT FROM OTHER REGICES.
{
	my ($T, $tindx, $s) = @_;

	$tindx++ while ($s =~ s/\(([^\(\)]+)\)/
			$T->[$tindx] = &parseParins($T, $tindx, $1);
			"\$T\[$tindx]"
	/e);
	return $s;
}

sub commit
{
	my ($dB) = shift;

	if ($dB->FETCH('AutoCommit') && $dB->FETCH('Warn'))
	{
		warn ('Commit ineffective while AutoCommit is ON!');
		return 1;
	}
	my ($commitResult) = 1;  #ADDED 20000103

	foreach (keys %{$dB->{sprite_SpritesOpen}})
	{
		next  unless (defined($dB->{'sprite_SpritesOpen'}->{$_}));
		next  if (/^(USER|ALL)_TABLES$/i);
		next  unless (defined(${$dB->{'sprite_SpritesOpen'}->{$_}}));
		$commitResult = ${$dB->{'sprite_SpritesOpen'}->{$_}}->commit($_);
		return undef  if (!defined($commitResult) || $commitResult <= 0);
	}
	return 1;
}

sub rollback
{
	my ($dB) = shift;

	if (!shift && $dB->FETCH('AutoCommit') && $dB->FETCH('Warn'))
	{
		warn ('Rollback ineffective while AutoCommit is ON!');
		return 1;
	}
	
	foreach my $s (keys %{$dB->{sprite_SpritesOpen}})
	{
		next  unless (defined($dB->{'sprite_SpritesOpen'}->{$s}));
		next  if ($s =~ /^(USER|ALL)_TABLES$/i);
		next  unless (defined(${$dB->{'sprite_SpritesOpen'}->{$s}}));
		${$dB->{'sprite_SpritesOpen'}->{$s}}->rollback($s);
	}
	return 1;
}

sub STORE
{
	my($dbh, $attr, $val) = @_;
	if ($attr eq 'AutoCommit')
	{
		# AutoCommit is currently the only standard attribute we have
		# to consider.

		$dbh->commit()  if ($val == 1 && !$dbh->FETCH('AutoCommit'));
		$dbh->{AutoCommit} = $val;
		return 1;
	}
	if ($attr =~ /^sprite/o)
	{
		# Handle only our private attributes here
		# Note that we could trigger arbitrary actions.
		# Ideally we should catch unknown attributes.
		$dbh->{$attr} = $val; # Yes, we are allowed to do this,
		return 1;             # but only for our private attributes
	}
	# Else pass up to DBI to handle for us
	$dbh->SUPER::STORE($attr, $val);
}

sub FETCH
{
	my($dbh, $attr) = @_;
	if ($attr eq 'AutoCommit') { return $dbh->{AutoCommit}; }
	if ($attr =~ /^sprite_/o)
	{
		# Handle only our private attributes here
		# Note that we could trigger arbitrary actions.
		return $dbh->{$attr}; # Yes, we are allowed to do this,
			# but only for our private attributes
		return $dbh->{$attr};
	}
	# Else pass up to DBI to handle
	$dbh->SUPER::FETCH($attr);
}

sub disconnect
{
	my ($db) = shift;
	
	#DBI::set_err($db, 0, '');   #CHGD. TO NEXT 20041104.
	DBI::set_err($db, undef);
	return (1);   #20000114: MAKE WORK LIKE DBI!
}

sub do
{
	my ($dB, $sqlstr, $attr, @bind_values) = @_;
	my ($csr) = $dB->prepare($sqlstr, $attr) or return undef;

	#DBI::set_err($dB, 0, '');   #CHGD. TO NEXT 20041104.
	DBI::set_err($dB, undef);
	
	#my $retval = $csr->execute(@bind_values) || undef;
	return ($csr->execute(@bind_values) || undef);
}

sub table_info
{
	my($dbh) = @_;		# XXX add qualification
	my $sth = $dbh->prepare('select TABLE_NAME from USER_TABLES') 
			or return undef;
	$sth->execute or return undef;
	return $sth;
}

sub primary_key_info   #ADDED 20060613 TO SUPPORT DBI primary_key/primary_key_info FUNCTIONS!
{
	my ($dbh, $cat, $schema, $tablename) = @_;
	my $sth = $dbh->prepare("PRIMARY_KEY_INFO $tablename") 
			or return undef;
	$sth->execute() or return undef;
	return $sth;
}

sub type_info_all  #ADDED 20010312, BORROWED FROM "Oracle.pm".
{
	my ($dbh) = @_;
	my $names =
	{
			TYPE_NAME		=> 0,
			DATA_TYPE		=> 1,
			COLUMN_SIZE		=> 2,
			LITERAL_PREFIX	=> 3,
			LITERAL_SUFFIX	=> 4,
			CREATE_PARAMS		=> 5,
			NULLABLE		=> 6,
			CASE_SENSITIVE	=> 7,
			SEARCHABLE		=> 8,
			UNSIGNED_ATTRIBUTE	=> 9,
			FIXED_PREC_SCALE	=>10,
			AUTO_UNIQUE_VALUE	=>11,
			LOCAL_TYPE_NAME	=>12,
			MINIMUM_SCALE		=>13,
			MAXIMUM_SCALE		=>14,
	}
	;
	# Based on the values from Oracle 8.0.4 ODBC driver
	my $ti = [
	$names,
			[ 'LONG RAW', -4, '2147483647', '\'', '\'', undef, 1, '0', '0',
			undef, '0', undef, undef, undef, undef
			],
			[ 'RAW', -2, 255, '\'', '\'', 'max length', 1, '0', 3,
			undef, '0', undef, undef, undef, undef
			],
			[ 'LONG', -1, '2147483647', '\'', '\'', undef, 1, 1, '0',
			undef, '0', undef, undef, undef, undef
			],
			[ 'CHAR', 1, 255, '\'', '\'', 'max length', 1, 1, 3,
			undef, '0', '0', undef, undef, undef
			],
			[ 'NUMBER', 3, 38, undef, undef, 'precision,scale', 1, '0', 3,
			'0', '0', '0', undef, '0', 38
			],
			[ 'AUTONUMBER', 4, 38, undef, undef, 'precision,scale', 1, '0', 3,
			'0', '0', '0', undef, '0', 38
			],
			[ 'DOUBLE', 8, 15, undef, undef, undef, 1, '0', 3,
			'0', '0', '0', undef, undef, undef
			],
			[ 'DATE', 11, 19, '\'', '\'', undef, 1, '0', 3,
			undef, '0', '0', undef, '0', '0'
			],
			[ 'VARCHAR2', 12, 2000, '\'', '\'', 'max length', 1, 1, 3,
			undef, '0', '0', undef, undef, undef
			]
	];
	return $ti;
}
sub tables   #CONVENIENCE METHOD FOR FETCHING LIST OF TABLES IN THE DATABASE.
{
	my($dbh) = @_;		# XXX add qualification

	my $sth = $dbh->table_info();
	
	return undef  unless ($sth);
	
	my ($row, @tables);
	
	while ($row = $sth->fetchrow_arrayref())
	{
		push (@tables, $row->[0]);
	}
	$sth->finish();
	return undef  unless ($#tables >= 0);
	return (@tables);
}

sub rows
{
	return $DBI::rows;
}

sub DESTROY   #ADDED 20001108 
{
	my($drh) = shift;
    
	if ($drh->FETCH('AutoCommit') == 1)
	{
		$drh->STORE('AutoCommit',0);
		$drh->rollback();                #COMMIT IT IF AUTOCOMMIT ON!
		$drh->STORE('AutoCommit',1);
	}
	$drh = undef;
}

1;


package DBD::Sprite::st; # ====== STATEMENT ======
use strict;

my (%typehash) = (
	'LONG RAW' => -4,
	'RAW' => -3,
	'LONG' => -1, 
	'CHAR' => 1,
	'NUMBER' => 3,
	'AUTONUMBER' => 4,
	'DOUBLE' => 8,
	'DATE' => 11,
	'VARCHAR' => 12,
	'VARCHAR2' => 12,
	'BOOLEAN' => -7,    #ADDED 20000308!
	'BLOB'	=> 113,     #ADDED 20020110!
	'MEMO'	=> -1,      #ADDED 20020110!

	'DATE' => 9,
	'REAL' => 7,
	'TINYINT' => -6,
	'NCHAR' => -8,
	'NVARCHAR' => -9,
	'NTEXT' => -10,
	'SMALLDATETIME' => 93,
	'BIGINT' => -5,
	'DECIMAL' => 3,
	'INTEGER' => 4,
);

$DBD::Sprite::st::imp_data_size = 0;
use vars qw($imp_data_size *fetch);

sub bind_param
{
	my($sth, $pNum, $val, $attr) = @_;
	my $type = (ref $attr) ? $attr->{TYPE} : $attr;

	if ($type)
	{
		my $dbh = $sth->{Database};
		$val = $dbh->quote($val, $type);
		$val =~ s/^\'//o;
		$val =~ s/\'$//o;
	}
	my $params = $sth->FETCH('sprite_params');
	$params->[$pNum-1] = $val;

	#${$sth->{bindvars}}[($pNum-1)] = $val;   #FOR SPRITE. #REMOVED 20010312 (LVALUE NOT FOUND ANYWHERE ELSE).

	$sth->STORE('sprite_params', $params);
	return 1;
}

sub execute
{
	my ($sth, @bind_values) = @_;
	my $params = (@bind_values) ? \@bind_values : $sth->FETCH('sprite_params');
	my @ocolnames;
	for (my $i=0;$i<=$#{$params};$i++)  #ADDED 20000303  FIX QUOTE PROBLEM WITH BINDS.
	{
		$params->[$i] =~ s/\'/\'\'/go;
	}
	my $numParam = $sth->FETCH('NUM_OF_PARAMS');

	if ($params && scalar(@$params) != $numParam)  #CHECK FOR RIGHT # PARAMS.
	{
		DBI::set_err($sth, (scalar(@$params)-$numParam), 
				"..execute: Wrong number of bind variables (".(scalar(@$params)-$numParam)
				." too many!)");
		return undef;
	}
	#my $sqlstr = $sth->{'Statement'};   #CHGD. TO NEXT 20040205 TO PERMIT JOINS.
	my $sqlstr = $sth->FETCH('sprite_statement');
	#NEXT 8 LINES ADDED 20010911 TO FIX BUG WHEN QUOTED VALUES CONTAIN "?"s.
	$sqlstr =~ s/\\\'/\x02\^3jSpR1tE\x02/gso;      #PROTECT ESCAPED DOUBLE-QUOTES.
	$sqlstr =~ s/\'\'/\x02\^4jSpR1tE\x02/gso;      #PROTECT DOUBLED DOUBLE-QUOTES.
	$sqlstr =~ s/\'([^\']*?)\'/
			my ($str) = $1;
			$str =~ s|\?|\x02\^2jSpR1tE\x02|gs;    #PROTECT QUESTION-MARKS WITHIN QUOTES.
			"'$str'"/egs;
	$sqlstr =~ s/\x02\^4jSpR1tE\x02/\'\'/gso;      #UNPROTECT DOUBLED DOUBLE-QUOTES.
	$sqlstr =~ s/\x02\^3jSpR1tE\x02/\\\'/gso;      #UNPROTECT ESCAPED DOUBLE-QUOTES.

	#CONVERT REMAINING QUESTION-MARKS TO BOUND VALUES.

#	my $bindindices = $sth->FETCH('sprite_bi0') || [0..($numParam-1)];
#	foreach my $i (@$bindindices)
	for (my $i = 0;  $i < $numParam;  $i++)
	{
		$params->[$i] =~ s/\?/\x02\^2jSpR1tE\x02/gso;   #ADDED 20001023 TO FIX BUG WHEN PARAMETER OTHER THAN LAST CONTAINS A "?"!
		$sqlstr =~ s/\?/"'".$params->[$i]."'"/es;
	}
	$sqlstr =~ s/\x02\^2jSpR1tE\x02/\?/gso;     #ADDED 20001023! - UNPROTECT PROTECTED "?"s.
	my ($spriteref) = $sth->FETCH('sprite_spritedb');

	#CALL JSPRITE TO DO THE SQL!
	my (@resv) = $spriteref->sql($sqlstr);
	#!!! HANDLE SPRITE ERRORS HERE (SEE SPRITE.PM)!!!
	my ($retval) = undef;
	if ($#resv < 0)          #GENERAL ERROR!
	{
		DBI::set_err($sth, ($spriteref->{lasterror} || -601), 
				($spriteref->{lastmsg} || 'Unknown Error!'));
		return $retval;
	}
	elsif ($resv[0])         #NORMAL ACTION IF NON SELECT OR >0 ROWS SELECTED.
	{
		$retval = $resv[0];
		my $dB = $sth->{Database};
		#if ($dB->FETCH('AutoCommit') == 1 && $sth->FETCH('Statement') !~ /^\s*select/i)   #CHGD. TO NEXT 20040205 TO PERMIT JOINS.
		if ($sth->FETCH('sprite_statement') !~ /^\s*(?:select|primary_key_info)/io)
		{
			if ($dB->FETCH('AutoCommit') == 1)
			{
				$retval = undef  unless ($spriteref->commit());  #ADDED 20010911 TO MAKE AUTOCOMMIT WORK (OOPS :(  )
				#$dB->STORE('AutoCommit',1);  #COMMIT DONE HERE!
			}
		}
		else
		{
			#OCOL* = ORIGINAL SQL.
			#ICOL* = BASE SQL.
			#JCOL* = JOIN SQL.
			$sqlstr = $sth->FETCH('sprite_joinstmt1');
			if ($sqlstr)
			{
				$sqlstr =~ s/\\\'/\x02\^3jSpR1tE\x02/gso;      #PROTECT ESCAPED DOUBLE-QUOTES.
				$sqlstr =~ s/\'\'/\x02\^4jSpR1tE\x02/gso;      #PROTECT DOUBLED DOUBLE-QUOTES.
				$sqlstr =~ s/\'([^\']*?)\'/
						my ($str) = $1;
						$str =~ s|\?|\x02\^2jSpR1tE\x02|gso;    #PROTECT QUESTION-MARKS WITHIN QUOTES.
						"'$str'"/egs;
				$sqlstr =~ s/\x02\^4jSpR1tE\x02/\'\'/gso;      #UNPROTECT DOUBLED DOUBLE-QUOTES.
				$sqlstr =~ s/\x02\^3jSpR1tE\x02/\\\'/gso;      #UNPROTECT ESCAPED DOUBLE-QUOTES.

				#CONVERT REMAINING QUESTION-MARKS TO BOUND VALUES.

#!!!				my $bindindices = $sth->FETCH('sprite_bi1');
#				foreach my $i (@$bindindices)
#				{
#					$params->[$i] =~ s/\?/\x02\^2jSpR1tE\x02/gs;   #ADDED 20001023 TO FIX BUG WHEN PARAMETER OTHER THAN LAST CONTAINS A "?"!
#					$sqlstr =~ s/\?/"'".$params->[$i]."'"/es;
#				}
				$sqlstr =~ s/\x02\^2jSpR1tE\x02/\?/gso;     #ADDED 20001023! - UNPROTECT PROTECTED "?"s.
				my @icolnames = split(/\,/o, $spriteref->{use_fields});
				my %icolHash;
				for (my $i=0;$i<=$#icolnames;$i++)
				{
					$icolHash{$icolnames[$i]} = $i;
				}
				my $origsql = $sth->FETCH('Statement');
				$origsql =~ s/select\s+(.+)?\s+from\s+.+$/$1/is;
				$origsql =~ s/\s+//g;
				my $joinfids = $sth->FETCH('sprite_joinfid');
				my $joinalii = $sth->FETCH('sprite_joinalias');
#				unless ($spriteref->{sprite_CaseFieldNames})  #CHGD. TO NEXT 20040929.
				$origsql =~ tr/a-z/A-Z/  unless ($spriteref->{sprite_CaseFieldNames});
				unless ($spriteref->{sprite_CaseTableNames})
				{
					for (my $i=0;$i<=$#{$joinfids};$i++)
					{
						$joinfids->[$i] =~ tr/a-z/A-Z/;
						$joinalii->[$i] =~ tr/a-z/A-Z/;
					}
					
				}
				#CALL JSPRITE TO DO THE SQL!

				my $joinspriteref = $sth->FETCH('sprite_joindb');
				my (@joinresv) = $joinspriteref->sql($sqlstr);
				my $joinunion0 = $sth->FETCH('sprite_union0');

				#BUILD ARRAYS OF INDICES FOR UNION FIELDS TO BE COMPARED.
				my @icolindx;
				for (my $i=0;$i<=$#{$joinunion0};$i++)
				{
					$joinunion0->[$i] =~ s/[^\.]*\.(.*)/$1/;
					$joinunion0->[$i] =~ tr/a-z/A-Z/
							unless ($joinspriteref->{sprite_CaseFieldNames});
					for (my $j=0;$j<=$#icolnames;$j++)
					{
						if ($joinunion0->[$i] eq $icolnames[$j])
						{
							push (@icolindx, $j);
							last;
						}
					}
				}
				my $joinunion1 = $sth->FETCH('sprite_union1');
				my @jcolnames = split(/\,/o, $joinspriteref->{use_fields});
				my %jcolHash;
				for (my $i=0;$i<=$#jcolnames;$i++)
				{
					$jcolHash{$jcolnames[$i]} = $i;
				}
				my @jcolindx;
				for (my $i=0;$i<=$#{$joinunion1};$i++)
				{
					$joinunion1->[$i] =~ s/[^\.]*\.(.*)/$1/;
					$joinunion1->[$i] =~ tr/a-z/A-Z/
							unless ($joinspriteref->{sprite_CaseFieldNames});
					for (my $j=0;$j<=$#jcolnames;$j++)
					{
						if ($joinunion1->[$i] eq $jcolnames[$j])
						{
							push (@jcolindx, $j);
							last;
						}
					}
				}
				@ocolnames = split(/\,/o, $origsql);
				my ($tbl,$fld);
				my (@ocolwhich, %newtypes, %newlens, %newscales);

I1:				for (my $i=0;$i<=$#ocolnames;$i++)
				{
					($tbl,$fld) = split(/\./o, $ocolnames[$i]);
					$ocolnames[$i] = $fld;
					if ($tbl eq $joinfids->[1] || $tbl eq $joinalii->[1])
					{
						$ocolwhich[$i] = 1;
						for (my $j=0;$j<=$#jcolindx;$j++)
						{
							if ($fld eq $jcolnames[$j])
							{
								$newtypes{$fld} = ${$joinspriteref->{types}}{$fld};
								$newlens{$fld} = ${$joinspriteref->{lengths}}{$fld};
								$newscales{$fld} = ${$joinspriteref->{scales}}{$fld};
								next I1;
							}
						}
					}
					else
					{
						$ocolwhich[$i] = 0;
						for (my $j=0;$j<=$#icolindx;$j++)
						{
							if ($fld eq $icolnames[$j])
							{
								$newtypes{$fld} = ${$spriteref->{types}}{$fld};
								$newlens{$fld} = ${$spriteref->{lengths}}{$fld};
								$newscales{$fld} = ${$spriteref->{scales}}{$fld};
								next I1;
							}
						}
					}
				}
				%{$spriteref->{types}} = %newtypes;
				%{$spriteref->{lengths}} = %newlens;
				%{$spriteref->{scales}} = %newscales;
				$spriteref->{TYPE} = undef;
				my $jrow = shift(@joinresv);
				my $row = shift(@resv);
				my $orig_whereclause = $sth->FETCH('sprite_where0');
				$orig_whereclause =~ s/\s+order\s+by\s+[\w\,\.\s]+$//is;
				my @tblname = (($joinalii->[0] || $joinfids->[0]), 
						($joinalii->[1] || $joinfids->[1]));
				my $validColumnnames = "(?:$tblname[0].".$spriteref->{use_fields};
				$validColumnnames =~ s/\,/\|$tblname[0]\./g;
				$validColumnnames .= "|$tblname[1].".$joinspriteref->{use_fields}.')';
				$validColumnnames =~ s/\,/\|$tblname[1]\./g;
				#DE-ALIAS ALL TABLE-ALIASES IN THE WHERE-CLAUSE.
				if ($spriteref->{sprite_CaseTableNames})  #CONDITION ADDED 20040929.
				{
					for (my $i=0;$i<=1;$i++)
					{
						$orig_whereclause =~ s/ $joinalii->[$i]\./ $joinfids->[$i]\./gs;
					}
				}
				else
				{
					for (my $i=0;$i<=1;$i++)
					{
						$orig_whereclause =~ s/ $joinalii->[$i]\./ $joinfids->[$i]\./igs;
					}
				}

				#NOW, BIND ALL BIND VARIABLES HERE!
				$orig_whereclause =~ s/\\\'/\x02\^3jSpR1tE\x02/gso;      #PROTECT ESCAPED DOUBLE-QUOTES.
				$orig_whereclause =~ s/\'\'/\x02\^4jSpR1tE\x02/gso;      #PROTECT DOUBLED DOUBLE-QUOTES.
				$orig_whereclause =~ s/\'([^\']*?)\'/
						my ($str) = $1;
						$str =~ s|\?|\x02\^2jSpR1tE\x02|gso;    #PROTECT QUESTION-MARKS WITHIN QUOTES.
						"'$str'"/egs;
				$orig_whereclause =~ s/\x02\^4jSpR1tE\x02/\'\'/gso;      #UNPROTECT DOUBLED DOUBLE-QUOTES.
				$orig_whereclause =~ s/\x02\^3jSpR1tE\x02/\\\'/gso;      #UNPROTECT ESCAPED DOUBLE-QUOTES.

				#CONVERT REMAINING QUESTION-MARKS TO BOUND VALUES.

				for (my $i = 0;  $i < $numParam;  $i++)
				{
					$params->[$i] =~ s/\?/\x02\^2jSpR1tE\x02/gso;   #ADDED 20001023 TO FIX BUG WHEN PARAMETER OTHER THAN LAST CONTAINS A "?"!
					$orig_whereclause =~ s/\?/"'".$params->[$i]."'"/es;
				}
				$orig_whereclause =~ s/\x02\^2jSpR1tE\x02/\?/gso;     #ADDED 20001023! - UNPROTECT PROTECTED "?"s.
				my $cond = $spriteref->parse_expression($orig_whereclause, $validColumnnames);
				#$cond =~ s/\$\_\-\>\{\w+\.(\w+)\}/BASE($icolHash{$1})/g;
				#$cond =~ s/\$\_\-\>\{\w+\.(\w+)\}/\$baseresv\-\>\[\$icolHash\{$1\}\]/g;
				#$cond =~ s/\$\_\-\>\{\w+\.(\w+)\}/JOIN($jcolHash{$1})/g;
				$cond =~ s/\$\_\-\>\{$tblname[0]\.(\w+)\}/\$baserow\-\>\[\$icolHash\{$1\}\]/g;
				$cond =~ s/\$\_\-\>\{$tblname[1]\.(\w+)\}/\$joinrow\-\>\[\$jcolHash\{$1\}\]/g;
				#DONT NEED?$cond =~ s/[\r\n\t]/ /gs;

				#NOW EVAL THE *ORIGINAL* WHERE-CLAUSE CONDITION TO WEED OUT UNDESIRED RECORDS.

				my ($j, $k, $baserow, $joinrow, @newresv, @newrow);
				if ($sth->FETCH('sprite_joinorder'))
				{
					while (@joinresv)
					{
						$joinrow = shift(@joinresv);
J2A:						for ($j=0;$j<$row;$j++)
						{
							$baserow = $resv[$j];
							$@ = '';
							$_ = ($cond !~ /\S/o || eval $cond);
							next J2A  unless ($_);
							for ($k=0;$k<=$#ocolnames;$k++)
							{
								if ($ocolwhich[$k])
								{
									push (@newrow, $joinrow->[$jcolHash{$ocolnames[$k]}]);
								}
								else
								{
									push (@newrow, $baserow->[$icolHash{$ocolnames[$k]}]);
								}
							}
							push (@newresv, [@newrow]);
							@newrow = ();
						}
					}
				}
				else
				{
					while (@resv)
					{
						$baserow = shift(@resv);
J2B:						for ($j=0;$j<$jrow;$j++)
						{
							$joinrow = $joinresv[$j];
							$@ = '';
							$_ = ($cond !~ /\S/o || eval $cond);
							next J2B  unless ($_);
							for ($k=0;$k<=$#ocolnames;$k++)
							{
								if ($ocolwhich[$k])
								{
									push (@newrow, $joinrow->[$jcolHash{$ocolnames[$k]}]);
								}
								else
								{
									push (@newrow, $baserow->[$icolHash{$ocolnames[$k]}]);
								}
							}
							push (@newresv, [@newrow]);
							@newrow = ();
						}
					}
				}
				@resv = (scalar(@newresv), @newresv);
				$retval = $resv[0] || '0E0';
			}
		}
	}
	else                     #SELECT SELECTED ZERO RECORDS.
	{
		if ($spriteref->{lasterror})
		{
			DBI::set_err($sth, $spriteref->{lasterror}, $spriteref->{lastmsg});
			$retval = undef;
		}
		$retval = '0E0';
	}

	#EVERYTHING WORKED, SO SAVE SPRITE RESULT (# ROWS) AND FETCH FIELD INFO.

	#if ($retval)   #CHGD TO NEXT 20020606.
	if (defined($retval) && $retval)
	{
		$sth->{'driver_rows'} = $retval; # number of rows
		$sth->{'sprite_rows'} = $retval; # number of rows
		$sth->STORE('sprite_rows', $retval);
		$sth->STORE('driver_rows', $retval);
	}
	else
	{
		$sth->{'driver_rows'} = 0; # number of rows
		$sth->{'sprite_rows'} = 0; # number of rows
		$sth->STORE('sprite_rows', 0);
		$sth->STORE('driver_rows', 0);
	}

    #### NOTE #### IF THIS FAILS, IT PROBABLY NEEDS TO BE "sprite_rows"?

	shift @resv;   #REMOVE 1ST COLUMN FROM DATA RETURNED (THE SPRITE RESULT).
	my @l = ($#ocolnames >= 0) ? @ocolnames : split(/,/,$spriteref->{use_fields});
	$sth->STORE('NUM_OF_FIELDS',($#l+1));
	my (@keyfields) = split(',', $spriteref->{key_fields}); #ADDED 20030520 TO IMPROVE NULLABLE.

	unless ($spriteref->{TYPE})
	{
		@{$spriteref->{NAME}} = @l;
		for my $i (0..$#l)
		{
			if (defined ${$spriteref->{types}}{$l[$i]})
			{
				${$spriteref->{TYPE}}[$i] = $typehash{"\U${$spriteref->{types}}{$l[$i]}\E"};
				${$spriteref->{PRECISION}}[$i] = ${$spriteref->{lengths}}{$l[$i]};
				${$spriteref->{SCALE}}[$i] = ${$spriteref->{scales}}{$l[$i]};
			}
			else
			{
				${$spriteref->{TYPE}}[$i] = '';
				${$spriteref->{PRECISION}}[$i] = 0;
				${$spriteref->{SCALE}}[$i] = 0;
			}
			${$spriteref->{NULLABLE}}[$i] = 1;
			foreach my $j (@keyfields)   #ADDED 20030520 TO IMPROVE NULLABLE.
			{
				if (${$spriteref->{NAME}}[$i] eq $j)
				{
					${$spriteref->{NULLABLE}}[$i] = 0;
					last;
				}
			}
		}
	}

	#TRANSFER SPRITE'S FIELD DATA TO DBI.

	$sth->{'driver_data'} = \@resv;
	$sth->STORE('sprite_data', \@resv);
    #$sth->STORE('sprite_rows', ($#resv+1)); # number of rows
	$sth->{'TYPE'} = \@{$spriteref->{TYPE}};
	$sth->{'NAME'} = \@{$spriteref->{NAME}};
	for (my $i=0;$i<=$#{$sth->{'NAME'}};$i++)
	{
		$sth->{'NAME'}->[$i] = $spriteref->{ASNAMES}->{$sth->{'NAME'}->[$i]}
				if ($spriteref->{ASNAMES}->{$sth->{'NAME'}->[$i]});
	}
	$sth->{'PRECISION'} = \@{$spriteref->{PRECISION}};
	$sth->{'SCALE'} = \@{$spriteref->{SCALE}};
	$sth->{'NULLABLE'} = \@{$spriteref->{NULLABLE}};
	$sth->STORE('sprite_resv',\@resv);
    #ADDED NEXT LINE 20020905 TO SUPPORT DBIx::GeneratedKey!
	$sth->{Database}->STORE('sprite_insertid', $spriteref->{'sprite_lastsequence'});
	if (defined $retval)
	{
		return $retval ? $retval : '0E0';
	}
	return undef;
}

sub fetchrow_arrayref
{
	my($sth) = @_;
	my $data = $sth->FETCH('driver_data');
	my $row = shift @$data;
	#return undef  if (!$row || !scalar(@$row));   #CHGD. TO NEXT 20040913 TO AVOID _FBAV ERROR IF NO ROWS RETURNED!
	return undef  if (!$row || !scalar(@$row));
	#my ($longreadlen) = $sth->{Database}->FETCH('LongReadLen');  #CHGD. TO NEXT 20020606 AS WORKAROUND FOR DBI::PurePerl;
	my ($longreadlen) = $sth->{Database}->FETCH('LongReadLen') || 0;
	if ($longreadlen > 0)
	{
		if ($sth->FETCH('ChopBlanks'))
		{
			for (my $i=0;$i<=$#{$row};$i++)
			{
				if (${$sth->{TYPE}}[$i] < 0)  #LONG, LONG RAW, etc.
				{
					my ($t) = substr($row->[$i],0,$longreadlen);
					return undef  unless (($row->[$i] eq $t) || $sth->{Database}->FETCH('LongTruncOk'));
					$row->[$i] = $t;
				}
			}
			map { $_ =~ s/\s+$//; } @$row;
		}
	}
	else
	{
		if ($sth->FETCH('ChopBlanks'))
		{
			map { $_ =~ s/\s+$//; } @$row;
		}
	}
	my $myres;
	eval { $myres = $sth->_set_fbav($row); };
#	$myres = $sth->_set_fbav($row);
	return $myres;
}

*fetch = \&fetchrow_arrayref; # required alias for fetchrow_arrayref
sub rows
{
	my($sth) = @_;
	return $sth->FETCH('driver_rows') or $sth->FETCH('sprite_rows') or $sth->{drv_rows};
}
#### NOTE #### IF THIS FAILS, IT PROBABLY NEEDS TO BE "sprite_rows"?


sub STORE
{
	my($dbh, $attr, $val) = @_;
	if ($attr eq 'AutoCommit')
	{
		# AutoCommit is currently the only standard attribute we have
		# to consider.
		#if (!$val) { die "Can't disable AutoCommit"; }

		$dbh->{AutoCommit} = $val;
		return 1;
	}
	if ($attr =~ /^sprite/o)
	{
		# Handle only our private attributes here
		# Note that we could trigger arbitrary actions.
		# Ideally we should catch unknown attributes.
		$dbh->{$attr} = $val; # Yes, we are allowed to do this,
		return 1;             # but only for our private attributes
	}
	# Else pass up to DBI to handle for us
	eval {$dbh->SUPER::STORE($attr, $val);};
}

sub FETCH
{
	my($dbh, $attr) = @_;
	if ($attr eq 'AutoCommit') { return $dbh->{AutoCommit}; }
	if ($attr =~ /^sprite_/o)
	{
		# Handle only our private attributes here
		# Note that we could trigger arbitrary actions.
		return $dbh->{$attr}; # Yes, we are allowed to do this,
			# but only for our private attributes
		return $dbh->{$attr};
	}
	# Else pass up to DBI to handle
	$dbh->SUPER::FETCH($attr);
}

sub DESTROY   #ADDED 20010221
{
}

1;

package DBD::Sprite; # ====== HAD TO HAVE TO PREVENT MAKE ERROR! ======

1;

__END__
