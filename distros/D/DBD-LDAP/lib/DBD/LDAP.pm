=head1 NAME

DBD::LDAP - Provides an SQL/Perl DBI interface to LDAP

=head1 AUTHOR

This module is Copyright (C) 2000-2010 by

          Jim Turner

        Email:  turnerjw784 .att. yahoo.com

All rights reserved Without Prejudice.

You may distribute this module under the same terms as Perl itself.

=head1 PREREQUISITES

     Convert::ANS1   (required by Net::LDAP)
     Net::LDAP
     DBI
     - an LDAP database to connect to.

=head1 SYNOPSIS

     use DBI;
     $dbh = DBI->connect("DBI:LDAP:ldapdb",'user','password')  #USER LOGIN.
         or die "Cannot connect as user: " . $DBI::errstr;

     $dbh = DBI->connect("DBI:LDAP:ldapdb")  #ANONYMOUS LOGIN (Read-only).
         or die "Cannot connect as guest (readonly): " . $DBI::errstr;

     $sth = $dbh->prepare("select * from people where (cn like 'Smith%')")
         or die "Cannot prepare: " . $dbh->errstr();
     $sth->execute() or die "Cannot execute: " . $sth->errstr();
      while ((@results) = $sth->fetchrow_array)
      {
           print "--------------------------------------------------------\n";
           ++$cnt;
           while (@results)
           {
                print "------>".join('|',split(/\0/, shift(@results)))."\n";
           }
      }
     $sth->finish();
     $dbh->disconnect();

=head1 DESCRIPTION

LDAP stands for the "Lightweight Directory Access Protocol".  For more information, see:  http://www.ogre.com/ldap/docs.html

DBD::LDAP is a DBI extension module adding an SQL database interface to 
standard LDAP databases to Perl's database-independent database interface.  
You will need access to an existing LDAP database or set up your own using 
an LDAP server, ie. "OpenLDAP", see (http://www.openldap.org).  

The main advantage of DBD::LDAP is the ability to query LDAP databases via 
standard SQL queries in leu of cryptic LDAP "filters".  LDAP is optimized for 
quick lookup of existing data, but DBD::LDAP does support entry inserts, 
updates, and deletes with commit/rollback via the standard SQL commands!  

LDAP databases are "heirarchical" in structure, whereas other DBD-supported 
databases are "relational" and there is no LDAP-equivalent to SQL "tables", so   
DBD::LDAP maps a "table" interface over the LDAP "tree" via a configuration 
file you must set up.  Each "table" is mapped to a common "base DN".  For 
example, consider a typical LDAP database of employees within different 
departments within a company.  You might have a "company" names "Acme" and 
the root "dn" of "dc=Acme, dc=com" (Acme.com).  Below the company level, are 
divisions, ie. "Widgets", and "Blivets".  Each division would have an entry 
with a "dn" of "ou=Widgets, dc=Acme, dc=com".  Employees within each division 
could have a "dn" of "cn=John Doe, ou=Widgets, dc=Acme, dc=com".  
With DBD::LDAP, we could create tables to access these different levels, 
ie. "top", which would have a "DN" of "dc=Acme, dc=com", "WidgetDivision" for 
"dc=Acme, dc=com".  Tables can also be constained by additional 
attribute specifications (filters), ie constraining by "objectclass", ie. 
"(objectclass=person)".  Then, doing a "select * from WidgetDivision" would 
display all "person"s with a "dn" containing ""ou=Widgets, dc=Acme, dc=com".

=head1 INSTALLATION

Installing this module (and the prerequisites from above) is quite simple. You just fetch the archive, extract it with

        gzip -cd DBD-LDAP-####.tar.gz | tar xf -

          -or-

          tar -xzvf DBD-LDAP-####.tar.gz

(this is for Unix users, Windows users would prefer WinZip or something similar) and then enter the following:

        cd DBD-LDAP-#.###
        perl Makefile.PL
        make
        make test

If any tests fail, let me know. Otherwise go on with

        make install

Note that you almost definitely need root or administrator permissions.  If you don't have them, read the ExtUtils::MakeMaker man page for details on installing in your own directories. 

=head1 GETTING STARTED:

1) Create a "database", ie. "foo" by creating a text file "foo.ldb".  The general format of this file is:

  ----------------------------------------------------------
  hostname[;port][:[root-dn][:[loginrule]]]
  tablename1:[basedn]:[basefilter]:dnattrs:[visableattrs]:[insertattrs]:[ldap_options]
  tablename2:[basedn]:[basefilter]:dnattrs:[visableattrs]:[insertattrs]:[ldap_options]
  ...
  ----------------------------------------------------------

     <hostname>          represents the ldap server host name.
     <port>               represents the server's port, default is 389.
     <root-dn>               if specified, is appended to the end of each tablename's 
                    base-dn.
     <loginrule>     if specified, converts single word "usernames" to the 
                    appropriate DN, ie:

               "cn=*,<ROOT>" would convert user name "foo" to "cn=foo, " and 
               append the "<root-dn>" onto that.  The asterisk is converted to 
               the user-name specified in the "connect" method.  If not specified, 
               the username specified in the "connect" method must be a full DN.
               If the "<root-dn>" is not specified, then the "<loginrule>" would 
               need to be a full DN.

     tablename     -     represents the name to be used in SQL statements for a given 
               set of entries which make up a virtual "table".
     basedn - if specified, is appended to the "<root-dn>" to make up the 
               common base DN for all entries in this table.  If "<root-dn>" is 
               not specified, then a full DN must be specified; otherwise, the 
               default is the root-dn.
     basefilter     - if specified, specifies a filter to be used if no "where"-
               clause is specified in SQL queries.  If a "where"-clause is 
               specified, the resulting filter is "and"-ed with this one.  The 
               default is "(objectclass=*)".
     dnattrs - specifies which attributes that values for which are to be 
               appended to the left of the basedn to create DNs for new entries 
               being inserted into the table.
     visableattrs - if specified, one or more attributes separated by commas 
               which will be sought when the SQL statement does not specify 
               attributes, ie. "select * from tablename".  If not specified, the 
               attributes of the first matching entry are returned and used for 
               all entries matching a given query.
     insertattrs - if specified, one or more attribute/value combinations to be 
               added to any new entry inserted into the table, usually needed for 
               objectclass values.  The attributes and values usually correspond 
               to those specivied in the "<basefilter>".  The general format is: 
               attr1=value1[|value2...],attr2=value1...,...
               These attributes and values will be joined with any user-specified 
               values for these attributes.
     ldap_options - if specified, can be any one or more of the following:

          ldap_sizelimit - Limit the number of entries fetch by a query to this 
                    number (0 = no limit) - default:  0.
          ldap_timelimit - Limit the search to this number of seconds per query. 
                    (0 = no limit) - default:  0.
          ldap_scope - specify the "scope" of the search.  Values are:  "base", 
                    "one", and "sub", see Net::LDAP docs.  Default is "one", 
                    meaning the set of records one level below the basedn.  "base" 
                    means search only the basedn, and "sub" means the union 
                    of entries at the "base" level and "one" level below.
          ldap_inseparator - specify the separator character/string to be used 
                    in queries to separate multiple values being specified for 
                    a given attribute.  Default is "|".
          ldap_outseparator - specify the separator character/string to be used 
                    in queryies to separate multiple values displayed as a result 
                    of a query.  Default is "|".
          ldap_firstonly - only display the 1st value fetched for each attribute 
                    per entry.  This makes "ldap_outseparator" unnecessary.

2) write your script to use DBI, ie:

          #!/usr/bin/perl
          use DBI;
          $dbh = DBI->connect('DBD:LDAP:mydb','me','mypassword') || 
                    die "Could not connect (".$DBI->err.':'.$DBI->errstr.")!";
          ...
          #CREATE A TABLE, INSERT SOME RECORDS, HAVE SOME FUN!

3) get your application working.

=head1 INSERTING, FETCHING AND MODIFYING DATA

1st, we'll create a database called "ldapdb" with the tables previously mentioned in the example in the DESCRIPTION section:

  ----------------- file "ldapdb.ldb" ----------------
  ldapserver:dc=Acme, dc=com:cn=*,<ROOT>
  top:::dc
  WidgetDivision:ou=Widgets, :&(objectclass=top)(objectclass=person):cn:cn,sn,ou,title,telephonenumber,description,objectclass,dn:objectclass=top|person|organizationalPerson:ldap_outseparator => ":"
  ----------------------------------------------------

The following examples insert some data in a table and fetch it back: First all data in the string:

        $dbh->do(q{
          INSERT INTO top (ou, cn, objectclass)  
          VALUES ('Widgets', 'WidgetDivision', 'top|organizationalUnit')
        };

Next an example using parameters:

        $dbh->do("INSERT INTO WidgetDivision (cn,sn,title,telephonenumber) VALUES (?, ?, ?, ?)",
        'John Doe','DoeJ','Manager','123-1111');
        $dbh->commit;

NOTE:  Unlike most other DBD modules which support transactions, changes made do NOT show up until the "commit" function is called, unless "AutoCommit" is set.  This is due to the fact that fetches are done from the LDAP server and changes do not take effect there until the Net::LDAP "update" function is called, which is called by "commit".  

NOTE: The "dn" field is generated automatically from the base "dn" and the dn component fields specified by "dnattrs", If you try to insert a value directly into it, it will be ignored.  Also, if not specified, any attribute/value combinations specified in the "insertattrs" option will be added automatically.  

To retrieve data, you can use the following:

        my($query) = "SELECT * FROM WidgetDivision WHERE cn like 'John%' ORDER BY cn";
        my($sth) = $dbh->prepare($query);
        $sth->execute();
        while (my $entry = $sth->fetchrow_hashref) {
            print("Found result record: cn = ", $entry->{'cn'},
                  ", phone = ", $row->{'telephonenumber'});
        }
        $sth->finish();

The SQL "SELECT" statement above (combined with the table information in the "ldapdb.ldb" database file would generate and execute the following equivalent LDAP Search:

          base => 'ou=Widgets, dc=Acme, dc=com',
          filter => '(&(&(objectclass=top)(objectclass=person))(cn=John*))',
          scope => 'one',
          attrs => 'cn,sn,ou,title,telephonenumber,description,objectclass,dn'

See the L<DBI> manpage for details on these methods. See the Data rows are modified with the UPDATE statement:

        $dbh->do("UPDATE WidgetDivision SET description = 'Outstanding Employee' WHERE cn = 'John Doe'");

NOTE:  You can NOT change the "dn" field directly - direct changes will be ignored.  You change the "rdn" component of the "dn" field by changing the value of the other field(s) which are appended to the base "dn".  Also, if not specified, any attribute/value combinations specified in the "insertattrs" option will be added automatically.

Likewise you use the DELETE statement for removing entries:

        $dbh->do("DELETE FROM WidgetDivision WHERE description = 'Outstanding Employee'");

=head1 METADATA

The following attributes are handled by DBI itself and not by DBD::LDAP, thus they should all work as expected.

        PrintError
        RaiseError
        Warn

The following DBI attributes are handled by DBD::LDAP:

    AutoCommit
        Works

    NUM_OF_FIELDS
        Valid after '$sth->execute'

    NUM_OF_PARAMS
        Valid after '$sth->prepare'

    NAME
        Valid after '$sth->execute'; undef for Non-Select statements.

    NULLABLE
        Not really working. Always returns an array ref of one's, as
        DBD::LDAP always allows NULL (handled as an empty string). 
        Valid after `$sth->execute'.

    LongReadLen
              Should work

    LongTruncOk
              Should work

These attributes and methods are not supported:

        bind_param_inout
        CursorName

In addition to the DBI attributes, you can use the following dbh attributes.  These attributes are read-only after "connect".

     ldap_dbuser
          Current database user.

     ldap_HOME
          Environment variable specifying a path to search for LDAP 
          databases (*.ldb) files.


=head1 DRIVER PRIVATE METHODS

    DBI->data_sources()
        The `data_sources' method returns a list of "databases" (.ldb files) 
        found in the current directory and, if specified, the path in 
        the ldap_HOME environment variable.

    $dbh->tables()
        This method returns a list of table names specified in the current 
        database.
        Example:

            my($dbh) = DBI->connect("DBI:LDAP:mydatabase",'me','mypswd');
            my(@list) = $dbh->func('tables');

=head1 OTHER SUPPORTING UTILITIES

=head1 RESTRICTIONS

DBD::LDAP currently treats all data as strings and all fields as VARCHAR(255).

Currently, you must define tables manually in the "<database>.ldb" file using your favorite text editor.  I hope to add support for the SQL "Create Table", "Alter Table", and "Drop Table" functions to handle this eventually.  

=head1 TODO

"Create Table", "Alter Table", and "Drop Table" SQL functions for creating, altering, and deleting the tables defined in the "<database>.ldb" file.

Some kind of datatype support, ie. numeric (for sorting), CHAR for padding, Long/Blob - for >255 chars per field, etc.

=head1 KNOWN BUGS

none - (yet).

=head1 SEE ALSO

L<Net::LDAP>, L<DBI>

=cut

require DBI;

package DBD::LDAP;

use strict;
#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw($VERSION $err $errstr $state $sqlstate $drh $i $j $dbcnt);
no warnings qw (uninitialized);

#require Exporter;

#@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
#@EXPORT = qw(
	
#);
$VERSION = '0.22';

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
    $drh = DBI::_new_drh($class, { 'Name' => 'LDAP',
				   'Version' => $VERSION,
				   'Err'    => \$DBD::LDAP::err,
				   'Errstr' => \$DBD::LDAP::errstr,
				   'State' => \$DBD::LDAP::state,
				   'Attribution' => 'DBD::LDAP by Shishir Gurdavaram & Jim Turner',
				 });
    $drh;
}

#sub AUTOLOAD {
#	print "***** AUTOLOAD CALLED! *****\n";
#}

1;


package DBD::LDAP::dr; # ====== DRIVER ======
use strict;
use vars qw($imp_data_size);

$DBD::LDAP::dr::imp_data_size = 0;

sub connect
{
	my($drh, $dbname, $dbuser, $dbpswd, $attr, $old_driver, $connect_meth) = @_;
	my($i, $j);

	# Avoid warnings for undefined values

	$dbuser ||= '';
	$dbpswd ||= '';

	$ENV{LDAP_HOME} ||= '';
	unless (open(DBFILE, "<$ENV{LDAP_HOME}/${dbname}.ldb"))
	{
		unless (open(DBFILE, "<${dbname}.ldb"))
		{
			unless (open(DBFILE, "<$ENV{HOME}/${dbname}.ldb"))
			{
				$_ = "No such database ($dbname)!";
				DBI::set_err($drh, -1, $_);
				warn $_  if ($attr->{PrintError});
				$_ = '-1:'.$_;
				return undef;
			}
		}
	}
	do
	{
		$_ = <DBFILE>;
		chomp;
	}
	while (/^\#/o);

	s#^(\w+)\:\/\/#$1\x02\/\/#o;  #PROTECT COLON IN PROTOCOLS (ADDED ON)
	s#\:(\d+)#\x02$1#go;         #PROTECT COLON BEFORE PORT#S (ADDED ON)
	my ($ldap_hostname, $ldap_root, $ldap_loginrule) = split(/\:/o);
	$ldap_hostname =~ s/\x02/\:/go;

	my %ldap_tables;
	my %ldap_ops;
	my ($tablename,$basedn,$dnattbs,$inseparator,$outseparator);

	while (<DBFILE>)
	{
		chomp;
		next  if (/^\#/o);
		my ($tablename,$basedn,$objclass,$dnattbs,$allattbs,$alwaysinsert,$dbdattbs) = split(/\:/o, $_,7);
		if ($ldap_root && $basedn !~ /\<ROOT\>i/o)
		{
			$basedn .= ','  unless ($basedn !~ /\S/o || $basedn =~ /\,\s*$/o);
			$basedn .= $ldap_root;
		}
		$ldap_tables{$tablename} = "$basedn:$objclass:$dnattbs:$allattbs:$alwaysinsert"  if ($tablename);
		$ldap_tables{$tablename} =~ s/\<root\>/$ldap_root/i;
		eval "\$ldap_ops{$tablename} = \{$dbdattbs\};";
	}

	#CREATE A 'BLANK' DBH

	if ($dbuser && $ldap_loginrule =~ /\*/o)
	{
		$ldap_loginrule =~ s/\<root\>/$ldap_root/gi;
		$_ = $dbuser;
		$dbuser = $ldap_loginrule;
		$dbuser =~ s/\*/$_/g;
	}
	my ($privateattr) = 
	{
		'Name' => $ldap_hostname,
				'user' => $dbuser,
				'dbpswd' => $dbpswd
	};

	my $this = DBI::_new_dbh($drh, 
	{
		'Name' => $ldap_hostname,              #LDAP URL!
				'USER' => $dbuser,              #OPTIONAL, '' = ANONYMOUS!	
		'CURRENT_USER' => $dbuser,
	}
	);
	unless ($this)
	{
		$_ = "Could not get new dbh handle on \"$ldap_hostname\" (".$@.")!";
		DBI::set_err($drh, -1, $_);
		warn $_  if ($attr->{PrintError});
		$_ = '-1:'.$_;
		return undef;
	}


	my $ldap_hostport = 389;
	$ldap_hostport = $1  if ($ldap_hostname =~ s/\;(.*)$//o);
	my $ldap;
	my @connectArgs = ($ldap_hostname);
	push (@connectArgs, 'port', $ldap_hostport)  unless ($ldap_hostname =~ /\:\d+$/o);
	if ($ldap_hostname =~ /^ldaps/o)
	{
		unless (defined($attr->{ldaps_capath}) && -d $attr->{ldaps_capath})
		{
			$_ = "Must specify valid path for \"ldaps_capath\" attribute when using ldaps!";
			DBI::set_err($drh, -1, $_);
			warn $_  if ($attr->{PrintError});
			$_ = '-1:'.$_;
			return undef;
		}
		push (@connectArgs, 'verify', 'require', 'capath', $attr->{ldaps_capath});
	}
	$ldap = Net::LDAP->new(@connectArgs);
	unless ($ldap)
	{
		$_ = "Could not connect to \"$ldap_hostname\" (".$@.")!";
		DBI::set_err($drh, -1, $_);
		warn $_  if ($attr->{PrintError});
		$_ = '-1:'.$_;
		return undef;
	}

	my $mesg;
	if ($dbpswd)
	{
		$mesg = $ldap->bind($dbuser, password => $dbpswd);
	}
	elsif ($dbuser)
	{
		$mesg = $ldap->bind($dbuser);
	}
	else
	{
		$mesg = $ldap->bind();
	}
	unless ($mesg)
	{
		$_ = "Could not bind - \"$ldap_hostname\" (".$mesg->code().':'.$mesg->error().")!";
		DBI::set_err($drh, ($mesg->code()||-1), $_);
		warn $_  if ($attr->{PrintError});
		$_ = $mesg->code().':'.$_;
		return undef;
	}
	if ($mesg->code())
	{
		$_ = "Could not bind to \"$ldap_hostname\" (".$mesg->code().':'.$mesg->error().")!";
		DBI::set_err($drh, ($mesg->code()||-1), $_);
		warn $_  if ($attr->{PrintError});
		$_ = $mesg->code().':'.$_;
		return undef;
	}

	#POPULATE INTERNAL HANDLE DATA.

	++$DBD::LDAP::dbcnt;
	my (@commitqueue) = ();
	$this->STORE('ldap_commitqueue', \@commitqueue);
	$this->STORE('ldap_ldap', $ldap);
	$this->STORE('ldap_mesg', $mesg);
	$this->STORE('ldap_dbname',$dbname);
	$this->STORE('ldap_dbuser',$dbuser);
	$this->STORE('ldap_dbpswd',$dbpswd);
	$this->STORE('ldap_autocommit', 0);
	$this->STORE('ldap_attrhref', $attr);
	$this->STORE('ldap_hostname', $ldap_hostname);
	$this->STORE('ldap_tables', \%ldap_tables);
	$this->STORE('ldap_tablenames', [keys(%ldap_tables)]);
	$this->STORE('ldap_ops', \%ldap_ops);
	$this->STORE('AutoCommit', ($attr->{AutoCommit} || 0));
	return $this;
}

sub data_sources
{
	my ($self) = shift;

	my (@dsources) = ();

	my $path;
	if (defined $ENV{LDAP_HOME})
	{
		$path = "$ENV{LDAP_HOME}/*.ldb";
		my $code = "while (my \$i = <$path>)\n";
		$code .= <<'END_CODE';
		{
			chomp ($i);
			push (@dsources,"DBI:LDAP:$1")  if ($i =~ m#([^\/\.]+)\.ldb$#);
		}
END_CODE
		eval $code;
		$code =~ s/\.ldb([\>\$])/\.LDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
		eval $code;
	}
	$path = '*.ldb';
	my $code = "while (my \$i = <$path>)\n";
	$code .= <<'END_CODE';
	{
		chomp ($i);
		push (@dsources,"DBI:LDAP:$1")  if ($i =~ m#([^\/\.]+)\.ldb$#);
	}
END_CODE
	eval $code;
	$code =~ s/\.ldb([\>\$])/\.LDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
	eval $code;
	unless (@dsources)
	{
		if (defined $ENV{HOME})
		{
			$path = "$ENV{HOME}/*.ldb";
			my $code = "while (my \$i = <$path>)\n";
			$code .= <<'END_CODE';
			{
				chomp ($i);
				push (@dsources,"DBI:LDAP:$1")  if ($i =~ m#([^\/\.]+)\.ldb$#);
			}
END_CODE
			eval $code;
			$code =~ s/\.ldb([\>\$])/\.LDB$1/g;   #HANDLE WINDOWSEY FILENAMES :(
			eval $code;
		}
	}
	return (@dsources);
}

sub DESTROY
{
    my($drh) = shift;
	$drh = undef;
	return undef;
}

sub disconnect_all
{
}

sub admin {                 #I HAVE NO IDEA WHAT THIS DOES!
    my($drh) = shift;
    my($command) = shift;

    my($dbname) = ($command eq 'createdb'  ||  $command eq 'dropdb') ?
			shift : '';
    my($host, $port) = DBD::LDAP->_OdbcParseHost(shift(@_) || '');
    my($user) = shift || '';
    my($password) = shift || '';

    $drh->func(undef, $command,
	       $dbname || '',
	       $host || '',
	       $port || '',
	       $user, $password, '_admin_internal');
}

1;


package DBD::LDAP::db; # ====== DATABASE ======
use strict;
use Net::LDAP;
use JLdap;

$DBD::LDAP::db::imp_data_size = 0;
use vars qw($imp_data_size);

sub prepare
{
	my ($resptr, $sqlstr, $attribs) = @_;

	local ($_);

	$sqlstr =~ s/\n/ /go;
	
	DBI::set_err($resptr, undef);
	my $csr = DBI::_new_sth($resptr, {
		'Statement' => $sqlstr,
	});

	my $myldapref = new JLdap;
	$csr->STORE('ldap_ldapdb', $myldapref);
	$csr->STORE('ldap_fetchcnt', 0);
	$csr->STORE('ldap_reslinev','');

	#NEXT 4 LINES ADDED 20010829!

	$myldapref->{CaseTableNames} = $resptr->{ldap_attrhref}->{ldap_CaseTableNames};
	$myldapref->{ldap_firstonly} = $resptr->{ldap_attrhref}->{ldap_firstonly};
	$myldapref->{ldap_inseparator} = $resptr->{ldap_attrhref}->{ldap_inseparator} 
			if ($resptr->{ldap_attrhref}->{ldap_inseparator});
	$myldapref->{ldap_outseparator} = $resptr->{ldap_attrhref}->{ldap_outseparator} 
			if ($resptr->{ldap_attrhref}->{ldap_outseparator});
	$myldapref->{ldap_appendbase2ins} = $resptr->{ldap_attrhref}->{ldap_appendbase2ins}
			? $resptr->{ldap_attrhref}->{ldap_appendbase2ins} : 0;

	$sqlstr =~ /(into|from|update|table|primary_key_info)\s+(\w+)/gio;
	my ($tablename) = $2;
	$csr->STORE('ldap_base', $tablename);

	#NEXT 5 LINES ADDED 20091105 TO MAKE primary_key_info()	FUNCTION WORK:
	my $tablehash = $resptr->FETCH('ldap_tables');
	my $keyfields;
	(undef, undef, $keyfields) = split(/\:/o, $tablehash->{$tablename});
	$myldapref->{'table'} = $tablename;
	$myldapref->{'key_fields'} = $keyfields;

	$myldapref->{ldap_dbh} = $resptr;
	my ($ldap_ops) = $resptr->FETCH('ldap_ops');
	foreach my $i (keys %{$ldap_ops->{$tablename}})
	{
		$myldapref->{$i} = $ldap_ops->{$tablename}->{$i}  if ($i =~ /^ldap_/o);
	}
	foreach my $i (qw(ldap_sizelimit ldap_timelimit ldap_scope deref typesonly 
				callback))
	{
		$myldapref->{$i} = $attribs->{$i}  if (defined $attribs->{$i});
	}

	#SET UP STMT. PARAMETERS.

	unless (defined $tablehash->{$tablename})
	{
		DBI::set_err($resptr, -1, 
				"..Could not prepare query - no such table ($tablename)!");
		return undef;
	}
	my ($ldap) = $resptr->FETCH('ldap_ldap');
	$csr->STORE('ldap_ldap', $ldap);
	$csr->STORE('ldap_params', []);
	$sqlstr =~ s/([\'\"])([^$1]*?)\?([^$1]*?$1)/$1$2\x02$3/g;  #PROTECT ? IN QUOTES (DATA)!

	my $num_of_params = ($sqlstr =~ tr/?//);
	$sqlstr =~ s/\x02/\?/go;
	$csr->STORE('NUM_OF_PARAMS', $num_of_params);	
	$csr->STORE('ldap_dbh', $resptr);
	return ($csr);
}

sub commit
{
	my ($dB) = shift;

	my ($status, $res);
	if ($dB->FETCH('AutoCommit'))
	{
		if ($dB->FETCH('Warn'))
		{
			warn ('Commit ineffective while AutoCommit is ON!');
			return 0;
		}
	}
	else
	{
		my ($commitqueue) = $dB->FETCH('ldap_commitqueue');
		my ($entry, $ldap);
		while (@{$commitqueue})
		{
			$entry = shift(@{$commitqueue});
			$ldap = shift(@{$commitqueue});
			$res = ${$entry}->update($$ldap);
			if ($res->is_error)
			{
				DBI::set_err($dB, ($res->code||-1), 
						("Could not commit - " . $res->code . ': ' 
						. $res->error . '!'));
				return (undef);
			}
			if ($commitqueue->[0] =~ /^dn\=(.+)/o)
			{
				my $newdn = $1;
				shift(@{$commitqueue});
				$res = ${$ldap}->moddn($$entry, newrdn => $newdn);
				if ($res->is_error)
				{
					DBI::set_err($dB, ($res->code||-1), 
							("Could not commit new dn - " . $res->code . ': ' 
							. $res->error . '!'));
					return (undef);
				}
			}
		}
	}
	return 1;
}

sub rollback
{
	my ($dB) = shift;

	if ($dB->FETCH('AutoCommit'))
	{
		if ($dB->FETCH('AutoCommit') && $dB->FETCH('Warn'))
		{
			warn ('Rollback ineffective while AutoCommit is ON!');
			return 0;
		}
	}
	else
	{
		my ($commitqueue) = $dB->FETCH('ldap_commitqueue');
		@{$commitqueue} = ();
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
	if ($attr =~ /^ldap/o)
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
	if ($attr =~ /^ldap_/o)
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
	my ($ldap) = $db->FETCH('ldap_ldap');

	$ldap->unbind()  if ($ldap);
	DBI::set_err($db, undef);
	return (1);   #20000114: MAKE WORK LIKE DBI!
}

sub do
{
	my ($dB, $sqlstr, $attr, @bind_values) = @_;
	my ($csr) = $dB->prepare($sqlstr, $attr) or return undef;

	DBI::set_err($dB, undef);
	
	return ($csr->execute(@bind_values) or undef);
}

sub table_info
{
	my($dbh) = @_;		# XXX add qualification
	my $sth = $dbh->prepare('select tables') 
			or return undef;
	$sth->execute or return undef;
	$sth;
}

sub primary_key_info   #ADDED 20091105 TO SUPPORT DBI primary_key/primary_key_info FUNCTIONS!
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
			[ 'VARCHAR', 12, 255, '\'', '\'', 'max length', 1, '0', 3,
			undef, '0', '0', undef, undef, undef
			]
	];
	return $ti;
}
sub tables   #CONVENIENCE METHOD FOR FETCHING LIST OF TABLES IN THE DATABASE.
{
	my($dbh) = @_;		# XXX add qualification

	my ($tables) = $dbh->FETCH('ldap_tablenames');
	my (@tables) = @{$tables};
	return undef  unless ($#tables >= 0);
	return (@tables);
}

sub rows
{
	return $DBI::rows;
}

sub DESTROY
{
    my($drh) = shift;
	my ($ldap) = $drh->FETCH('ldap_ldap');
	if ($drh->FETCH('AutoCommit') != 1)
	{
		$drh->rollback();                #ROLL BACK ANYTHING UNCOMMITTED IF AUTOCOMMIT OFF!
	}

	$drh->disconnect();
	$drh = undef;
	return undef;
}

1;


package DBD::LDAP::st; # ====== STATEMENT ======
use strict;

my (%typehash) = (
	'LONG RAW' => -4,
	'RAW' => -3,
	'LONG' => -1, 
	'CHAR' => 1,
	'NUMBER' => 3,
	'DOUBLE' => 8,
	'DATE' => 11,
	'VARCHAR' => 12,
	'BOOLEAN' => -7,    #ADDED 20000308!
);

$DBD::LDAP::st::imp_data_size = 0;
use vars qw($imp_data_size *fetch);

sub bind_param
{
	my($sth, $pNum, $val, $attr) = @_;
	my $type = (ref $attr) ? $attr->{TYPE} : $attr;

	if ($type)
	{
		my $dbh = $sth->{Database};
		$val = $dbh->quote($sth, $type);
	}
	my $params = $sth->FETCH('ldap_params');
	$params->[$pNum-1] = $val;

	${$sth->{bindvars}}[($pNum-1)] = $val;   #FOR LDAP.

	$sth->STORE('ldap_params', $params);
	return 1;
}

sub execute
{
    my ($sth, @bind_values) = @_;
#print STDERR "-execute1($sth,".join(',',@bind_values).")\n";
    my $params = (@bind_values) ?
        \@bind_values : $sth->FETCH('ldap_params');

	for (my $i=0;$i<=$#{$params};$i++)  #ADDED 20000303  FIX QUOTE PROBLEM WITH BINDS.
	{
		$params->[$i] =~ s/\'/\'\'/go;
	}

    my $numParam = $sth->FETCH('NUM_OF_PARAMS');

    if ($params && scalar(@$params) != $numParam)  #CHECK FOR RIGHT # PARAMS.
    {
		DBI::set_err($sth, (scalar(@$params)-$numParam), 
				"..execute: Wrong number of bind variables (".(scalar(@$params)-$numParam)." too many!)");
		return undef;
    }
    my $sqlstr = $sth->{'Statement'};

	#NEXT 8 LINES ADDED 20010911 TO FIX BUG WHEN QUOTED VALUES CONTAIN "?"s.
    $sqlstr =~ s/\\\'/\x03/go;      #PROTECT ESCAPED DOUBLE-QUOTES.
    $sqlstr =~ s/\'\'/\x04/go;      #PROTECT DOUBLED DOUBLE-QUOTES.
	$sqlstr =~ s/\'([^\']*?)\'/
			my ($str) = $1;
			$str =~ s|\?|\x02|go;   #PROTECT QUESTION-MARKS WITHIN QUOTES.
			"'$str'"/eg;
	$sqlstr =~ s/\x04/\'\'/go;      #UNPROTECT DOUBLED DOUBLE-QUOTES.
	$sqlstr =~ s/\x03/\\\'/go;      #UNPROTECT ESCAPED DOUBLE-QUOTES.

	#CONVERT REMAINING QUESTION-MARKS TO BOUND VALUES.

    for (my $i = 0;  $i < $numParam;  $i++)
    {
        $params->[$i] =~ s/\?/\x02\^2jSpR1tE\x02/gs;   #ADDED 20091030 TO FIX BUG WHEN PARAMETER OTHER THAN LAST CONTAINS A "?"!
        $sqlstr =~ s/\?/"'".$params->[$i]."'"/e;
    }
	$sqlstr =~ s/\x02\^2jSpR1tE\x02/\?/gs;     #ADDED 20091030! - UNPROTECT PROTECTED "?"s.
	my ($ldapref) = $sth->FETCH('ldap_ldapdb');

	#CALL JLDAP TO DO THE SQL!

	my (@resv) = $ldapref->sql($sth, $sqlstr);
	my $saveAT = $@;
#print STDERR "-execute4 at=$@\n";

	#!!! HANDLE LDAP ERRORS HERE (SEE LDAP.PM)!!!
	
	my ($retval) = undef;
	if ($#resv < 0)          #GENERAL ERROR!
	{
		DBI::set_err($sth, ($ldapref->{lasterror} || -601), 
				($ldapref->{lastmsg} || 'Unknown Error!'));
		$@ ||= $saveAT;
		return $retval;
	}
	elsif ($resv[0])         #NORMAL ACTION IF NON SELECT OR >0 ROWS SELECTED.
	{
		$retval = $resv[0];
		my $dB = $sth->{Database};

#		if ($dB->FETCH('AutoCommit') == 1 && $sth->FETCH('Statement') !~ /^\s*select/i)   #CHGD. TO NEXT 20091105:
		if ($dB->FETCH('AutoCommit') == 1 && $sth->FETCH('Statement') !~ /^\s*(?:select|primary_key_info)/io)
		{
#print STDERR "!!!!!!!!!!!! clearing Autocommit drh=$dB= !!!!!!!!!!!!!\n";
			$dB->STORE('AutoCommit',0);  #ADDED 20010911 AS PER SPRITE TO MAKE AUTOCOMMIT WORK.
			$dB->commit();               #ADDED 20010911 AS PER SPRITE TO MAKE AUTOCOMMIT WORK.
			$dB->STORE('AutoCommit',1);  #COMMIT DONE HERE!
		}
		
	}
	else                     #SELECT SELECTED ZERO RECORDS.
	{
		if ($ldapref->{lasterror})
		{
			DBI::set_err($sth, $ldapref->{lasterror}, $ldapref->{lastmsg});
			$@ ||= $saveAT;
			$retval = undef;
		}
		$retval = '0E0';
#		$resv[0] = $ldapref->{lastmsg};
#		DBI::set_err($sth, ($ldapref->{lasterror} || -402), 
#				($ldapref->{lastmsg} || 'No matching records found/modified!'));
#		$retval = '0E0';
	}
	
	#EVERYTHING WORKED, SO SAVE LDAP RESULT (# ROWS) AND FETCH FIELD INFO.
	
    $sth->{'driver_rows'} = $resv[0]; # number of rows
    $sth->{'ldap_rows'} = $resv[0]; # number of rows    #ADDED 20050416 PER PACH BY jmorano

    #### NOTE #### IF THIS FAILS, IT PROBABLY NEEDS TO BE "ldap_rows"?
    
	shift @resv;   #REMOVE 1ST COLUMN FROM DATA RETURNED (THE LDAP RESULT).

	my @l = split(/,/o, $ldapref->{use_fields});
    $sth->STORE('NUM_OF_FIELDS',($#l+1));
	unless ($ldapref->{TYPE})
	{
		@{$ldapref->{NAME}} = @l;
		for my $i (0..$#l)
		{
			${$ldapref->{TYPE}}[$i] = $typehash{${$ldapref->{types}}{$l[$i]}}
					|| $typehash{'VARCHAR'};
			${$ldapref->{PRECISION}}[$i] = ${$ldapref->{lengths}}{$l[$i]}
					|| 255;
			${$ldapref->{SCALE}}[$i] = ${$ldapref->{scales}}{$l[$i]} || 0;
			${$ldapref->{NULLABLE}}[$i] = 1;
			#${$ldapref->{TYPE}}[$i] = 12;   #VARCHAR
			##${$ldapref->{TYPE}}[$i] = -1;   #VARCHAR   #NEXT 4 REPLACED BY 1ST 4 PER REQUEST BY jmorano.
			##${$ldapref->{PRECISION}}[$i] = 255;
			##${$ldapref->{SCALE}}[$i] = 0;
			##${$ldapref->{NULLABLE}}[$i] = 1;
		}
	}

	#TRANSFER LDAP'S FIELD DATA TO DBI.

    $sth->{'driver_data'} = \@resv;
    $sth->STORE('ldap_data', \@resv);
    $sth->STORE('ldap_rows', ($#resv+1)); # number of rows
	$sth->{'TYPE'} = \@{$ldapref->{TYPE}};
	$sth->{'NAME'} = \@{$ldapref->{NAME}};
	$sth->{'PRECISION'} = \@{$ldapref->{PRECISION}};
	$sth->{'SCALE'} = \@{$ldapref->{SCALE}};
	$sth->{'NULLABLE'} = \@{$ldapref->{NULLABLE}};
    $sth->STORE('ldap_resv',\@resv);
    $@ ||= $saveAT;
    return $retval  if ($retval);
    return '0E0'  if (defined $retval);
    return undef;
}

sub fetchrow_arrayref
{
	my($sth) = @_;
	my $data = $sth->FETCH('driver_data');
	my $row = shift @$data;

	return undef  if (!$row);
	my ($longreadlen) = $sth->{Database}->FETCH('LongReadLen');
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
			map { $_ =~ s/\s+$//o; } @$row;
		}
	}
	else
	{
		if ($sth->FETCH('ChopBlanks'))
		{
			map { $_ =~ s/\s+$//o; } @$row;
		}
	}

	return $sth->_set_fbav($row);
}

*fetch = \&fetchrow_arrayref; # required alias for fetchrow_arrayref
sub rows
{
	my($sth) = @_;
	$sth->FETCH('driver_rows');
}

#### NOTE #### IF THIS FAILS, IT PROBABLY NEEDS TO BE "ldap_rows"?


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
	if ($attr =~ /^ldap/o)
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
	if ($attr =~ /^ldap_/o)
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


1;

package DBD::LDAP; # ====== HAD TO HAVE TO PREVENT MAKE ERROR! ======

1;

__END__
