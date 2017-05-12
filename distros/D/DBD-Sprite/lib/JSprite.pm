##++
##    JSprite
##    Sprite v.3.2
##    Last modified: August 22, 1998
##
##    Copyright (c) 1998, Jim Turner, from
##    Sprite.pm (c) 1995-1998, Shishir Gundavaram
##    All Rights Reserved
##
##    E-Mail: shishir@ora.com
##    E-Mail: jim.turner@lmco.com
##
##    Permission  to  use,  copy, and distribute is hereby granted,
##    providing that the above copyright notice and this permission
##    appear in all copies and in supporting documentation.
##
##    If you use Sprite for any cool (Web) applications, I would be 
##    interested in hearing about them. So, drop me a line. Thanks!
##--

#############################################################################

=head1 NAME

JSprite - Modified version of Sprite to manipulate text delimited flat-files 
as databases using SQL emulating Oracle.  The remaining documentation
is based on Sprite.

=head1 SYNOPSIS

  use JSprite;

  $rdb = new JSprite;

  $rdb->set_delimiter (-read  => '::')  ## OR: ('read',  '::');
  $rdb->set_delimiter (-write => '::')  ## OR: ('write', '::');
  $rdb->set_delimiter (-record => '\n')  ## OR: ('record', '::');

  $rdb->set_os ('Win95');

    ## Valid arguments (case insensitive) include:
    ##
    ## Unix, Win95, Windows95, MSDOS, NT, WinNT, OS2, VMS, 
    ## MacOS or Macintosh. Default determined by $^O.

  #$rdb->set_lock_file ('c:\win95\tmp\Sprite.lck', 10);
	$rdb->set_lock_file ('Sprite.lck', 10);

  $rdb->set_db_dir ('Mac OS:Perl 5:Data') || die "Can't access dir!\n";

  $data = $rdb->sql (<<Query);   ## OR: @data = $rdb->sql (<<Query);
      .
      . (SQL)
      .
  Query

  foreach $row (@$data) {        ## OR: foreach $row (@data) {
      @columns = @$row;          ## NO null delimited string -- v3.2
  }                              

  $rdb->xclose;
  $rdb->close ($database);       ## To save updated database

=head1 DESCRIPTION

Here is a simple database where the fields are delimited by double-colons:

  PLAYER=VARCHAR2(16)::YEARS=NUMBER::POINTS=NUMBER::REBOUNDS=NUMBER::ASSISTS=NUMBER::Championships=NUMBER
  ...
  Larry Bird::13::25::11::7::3
  Michael Jordan::14::29::6::5::5
  Magic Johnson::13::22::7::11::5
  ...

I<Note:> The first line must contain the field names (case insensitive),
and the Oracle datatype and length.  Currently, the only meaningful
datatypes are NUMBER and VARCHAR.  All other types are treated
the same as VARCHAR (Perl Strings, for comparisens).

=head1 Supported SQL Commands

Here are a list of the SQL commands that are supported by JSprite:

=over 5

=item I<select> - retrieves records that match specified criteria:

  select col1 [,col2] from table_name
         where (cond1 OPERATOR value1) 
         [and|or (cond2 OPERATOR value2) ...] 
         order by col1 [,col2] 

The '*' operator can be used to select all columns.

The I<database> is simply the file that contains the data. If the file 
is not in the current directory, the path must be specified.  By
default, the actual file-name will end with the extension ".sdb".

Valid column names can be used where [cond1..n] and [value1..n] are expected, 
such as: 

I<Example 1>:

  select Player, Points from my_db
         where (Rebounds > Assists) 

I<Note:> Column names must not be Perl string or boolean operators, ie. (lt, 
	gt, eq, and, or, etc. and are case-insensitive.
	
The following SQL operators can be used: =, <, >, <=, >=, <>, 
is,  as well as Perl's special operators: =~ and !~.  
The =~ and !~ operators are used to 
specify regular expressions, such as: 

I<Example 2>:

  select * from my_db
         where (Name =~ /Bird$/i) 

Selects records where the Name column ends with "Bird" (case insensitive). 
For more information, look at a manual on regexps.

I<Note:> A path to a database can contain only the following characters:

  \w, \x80-\xFF, -, /, \, ., :

If you have directories with spaces or other 'invalid' characters, you 
need to use the I<set_db_dir> method.

=item I<update> - updates records that match specified criteria. 

  update table_name
    set cond1 = (value1)[,cond2 = (value2) ...]
        where (cond1 OPERATOR value1)
        [and|or (cond2 OPERATOR value2) ...] 

I<Example>:

  update my_db 
	 set Championships = (Championships + 1) 
         where (Player = 'Larry Bird') 

  update my_db
         set Championships = (Championships + 1),
	     Years = (12)
         where (Player = 'Larry Bird')

=item I<delete> - removes records that match specified criteria:

  delete from table_name
         where (cond1 OPERATOR value1) 
         [and|or (cond2 OPERATOR value2) ...] 

I<Example>:

  delete from my_db
         where (Player =~ /Johnson$/i) or
               (Years > 12) 

=item I<create> - simplified version of SQL-92 counterpart

Creates a new table or sequence.

  create table table_name (
         column-name datatype [, column-name2 datatype...]
         [, primary key (column-name [, column-name..])

  create sequence sequence_name [increment by #] start with #

A sequence is an Oracle-ish way of doing autonumbering.  The sequence is stored 
in a tiny ascii file (sequence-name.seq).  You can also do autonumbering the 
MySQL way with a field using the "AUTONUMBER" datatype and giving it a default 
value of the starting sequence number.

=item I<alter> - simplified version of SQL-92 counterpart

Removes the specified column from the database. The other standard SQL 
functions for alter table are also supported:

  alter table table_name drop (column-name [, column-name2...])

  alter table table_name add ([position] column-name datatype
  		[, [position2] column-name2 datatype2...] 
  		[primary key (column-name [, column-name2...]) ])

I<Examples>:

  alter table my_db drop (Years)

  alter table my_db add (Legend VARCHAR(40) default "value", Mapname CHAR(5))

  alter table my_db add (1 Maptype VARCHAR(40))

This example adds a new column as the 2nd column (0 for 1st column) of the 
table.  By default, new fields are added as the right-most (last) column of 
the table.  This is a JSprite Extension and is not supported by standard SQL.

  alter table my_db modify (Legend VARCHAR(40))

  alter table my_db modify (0 Legend default 1)

The last example moves the "Legend" column to the 1st column in the table and 
shifts the others over, and causes all subsequent records added to use a 
default value of "1" for the "Legend" field, if no value is inserted for it.
This "Position" field (zero in the example) is a JSprite extension and is not 
part of standard SQL.  

=item I<insert> - inserts a record into the database:

  insert into table_name 
         [(col1, col2, ... coln) ]
  values 
         (val1, val2, ... valn) 

I<Example>:

  insert into my_db 
         (Player, Years, Points, Championships) 
  values 
         ('Kareem Abdul-Jabbar', 21, 26, 6) 

You don't have to specify all of the fields in the database! Sprite also 
does not require you to specify the fields in the same order as that of 
the database. 

I<Note:> You should make it a habit to quote strings. 

=back

=head1 METHODS

Here are the available methods:

=over 5

=item I<set_delimiter>

The set_delimiter function sets the read and write delimiter for the
database. The delimiter is not limited to one character; you can have 
a string, and even a regexp (for reading only).  In JSprite,
you can also set the record seperator (default is newline).

I<Return Value>

None

=item I<set_os>

The set_os function can be used to notify Sprite as to the operating 
system that you're using. Default is determined by $^O.

I<Note:> If you're using Sprite on Windows 95/NT or on OS2, make sure
to use backslashes -- and NOT forward slashes -- when specifying a path 
for a database or to the I<set_db_dir> or I<set_lock_file> methods!

I<Return Value>

None

=item I<set_lock_file>

For any O/S that doesn't support flock (i.e Mac, Windows 95 and VMS), this
method allows you to set a lock file to use and the number of tries that
Sprite should try to obtain a 'fake' lock. However, this method is NOT 
fully reliable, but is better than no lock at all.

'Sprite.lck' (either in the directory specified by I<set_db_dir> or in 
the current directory) is used as the default lock file if one 
is not specified.

I<Return Value>

None

=item I<set_db_dir>

A path to a database can contain only the following characters: 

  \w, \x80-\xFF, -, /, \, ., :  

If your path contains other characters besides the ones listed above,
you can use this method to set a default directory. Here's an example:

  $rdb->set_db_dir ("Mac OS:Perl 5:Data");

  $data = $rdb->sql ("select * from phone.db");

Sprite will look for the file "Mac OS:Perl 5:Data:phone.db". Just to
note, the database filename cannot have any characters besides the one 
listed above!

I<Return Value>

  0 - Failure
  1 - Success

=item I<set_db_ext>

JSprite permits the user to specify an extension that is part
of the actual file name, but not part of the corresponding
table name.  The default is '.sdb'.

  $rdb->set_db_ext ('.sdb');


I<Return Value>

None

=item I<sql>

The sql function is used to pass a SQL command to this module. All of the 
SQL commands described above are supported. The I<select> SQL command 
returns an array containing the data, where the first element is the status. 
All of the other other SQL commands simply return a status.

I<Return Value>
  1 - Success
  0 - Error

=item I<commit>

The sql function is used to commit changes to the database.
Arguments:  file-name (usually the table-name) - the file
name to write the table to.  NOTE:  The path and file 
extension will be appended to it, ie:

  &rdb->commit('filename');

I<Return Value>
  1 - Success
  0 - Error

=item I<close>

The close function closes the file, and destroys the database object. You 
can pass a filename to the function, in which case Sprite will save the 
database to that file; the directory set by I<set_db_dir> is used as
the default.

I<Return Value>

None

=back

=head1 NOTES

Sprite is not the solution to all your data manipulation needs. It's fine 
for small databases (less than 1000 records), but anything over that, and 
you'll have to sit there and twiddle your fingers while Sprite goes 
chugging away ... and returns a few *seconds* or so later.

The main advantage of Sprite is the ability to develop and test 
prototype applications on personal machines (or other machines which do not 
have an Oracle licence or some other "mainstream" database) before releasing 
them on "production" machines which do have a "real" database.  This can all 
be done with minimal or no changes to your Perl code.

Another advantage of Sprite is that you can use Perl's regular expressions 
to search through your data. Yippee!

JSprite provides the ability to emulate basic database tables
and SQL calls via flat-files.  The primary use envisioned
for this is to permit website developers who can not afford
to purchase an Oracle licence to prototype and develop Perl 
applications on their own equipment for later hosting at 
larger customer sites where Oracle is used.  :-)

JSprite attempts to do things in as database-independent manner as possible, 
but where differences occurr, JSprite most closely emmulates Oracle, for 
example "sequences/autonumbering".  JSprite uses tiny one-line text files 
called "sequence files" (.seq).  and Oracle's "seq_file_name.NEXTVAL" 
function to insert into autonumbered fields.

=head1 ADDITIONAL JSPRITE-SPECIFIC FEATURES

JSprite supports Oracle sequences and functions.  The
currently-supported Oracle functions are "SYSTIME", NEXTVAL, and "NULL".  
Users can also "register" their own functions via the 
"fn_register" method.

=item I<fn_register>

Method takes 2 arguments:  Function name and optionally, a
package name (default is "main").

  $rdb->fn_register ('myfn','mypackage');
  
-or-

  JSprite::fn_register ('myfn',__PACKAGE__);

Then, you could say:

	insert into mytable values (myfn(?))
	
and bind some value to "?", which is passed to "myfn", and the return-value 
is inserted into the database.  You could also say (without binding):

	insert into mytable values (myfn('mystring'))
	
-or (if the function takes a number)-

	select field1, field2 from mytable where field3 = myfn(123) 
	
I<Return Value>

None

JSprite has added the SQL "create" function to 
create new tables and sequences.  

I<Examples:>

	create table table1 (
		field1 number, 
		field2 varchar(20), 
		field3 number(5,3)  default 3.143)

	create sequence sequence-name [increment by 1] start with 0

=head1 SEE ALSO

DBD::Sprite, Sprite, Text::CSV, RDB

=head1 ACKNOWLEDGEMENTS

I would like to thank the following, especially Rod Whitby and Jim Esten, 
for finding bugs and offering suggestions:

  Shishir Gundavaram  (shishir@ora.com)     (Original Sprite Author)
  Rod Whitby      (rwhitby@geocities.com)
  Jim Esten       (jesten@wdynamic.com)
  Dave Moore      (dmoore@videoactv.com)
  Shane Hutchins  (hutchins@ctron.com)
  Josh Hochman    (josh@bcdinc.com)
  Barry Harrison  (barryh@topnet.net)
  Lisa Farley     (lfarley@segue.com)
  Loyd Gore       (lgore@ascd.org)
  Tanju Cataltepe (tanju@netlabs.net)
  Haakon Norheim  (hanorhei@online.no)

=head1 COPYRIGHT INFORMATION
	
			JSprite Copyright (c) 1998-2001, Jim Turner
          Sprite Copyright (c) 1995-1998, Shishir Gundavaram
                      All Rights Reserved

  Permission  to  use,  copy, and distribute is hereby granted,
  providing that the above copyright notice and this permission
  appear in all copies and in supporting documentation.

=cut

###############################################################################

package JSprite;

no warnings 'uninitialized';

require 5.002;

use vars qw($VERSION);

use Cwd;
use Fcntl; 
use File::DosGlob 'glob';
our ($XMLavailable, $results);
eval 'use XML::Simple; $XMLavailable = 1; 1';
eval {require 'OraSpriteFns.pl';};

##++
##  Global Variables. Declare lock constants manually, instead of 
##  importing them from Fcntl.
##
use vars qw ($VERSION $LOCK_SH $LOCK_EX);
##--

$JSprite::VERSION = '6.11';
$JSprite::LOCK_SH = 1;
$JSprite::LOCK_EX = 2;

my $NUMERICTYPES = '^(NUMBER|FLOAT|DOUBLE|INT|INTEGER|NUM|AUTONUMBER|AUTO|AUTO_INCREMENT|DECIMAL|TINYINT|BIGINT|DOUBLE)$';       #20000224
my $STRINGTYPES = '^(VARCHAR2|CHAR|VARCHAR|DATE|LONG|BLOB|MEMO|RAW|TEXT)$';
#my $BLOBTYPES = '^(LONG|BLOB|MEMO)$';
my $BLOBTYPES = '^(LONG.*|.*?LOB|MEMO|.FILE)$';
my $REFTYPES = '^(LONG.*|.FILE)$';   #SUPPORT FILE-REFERENCING FOR THESE BLOB-TYPES.  (OTHERS ARE STORED INLINE).   20010125
my @perlconds = ();
my @perlmatches = ();
my $sprite_user = '';   #ADDED 20011026.
our ($errdetails);

##++
##  Public Methods and Constructor
##--

sub new
{
    my $class = shift;
    my $self;

    $self = {
                commands     => 'select|update|delete|alter|insert|create|drop|truncate|primary_key_info',
#                column       => '[A-Za-z0-9\~\x80-\xFF][\w\x80-\xFF]+',  #CHGD. TO NEXT 20020214 TO ALLOW 1-LETTER FIELD NAMES!!!! (HOW DID THIS GO ON FOR SO LONG?)
                column       => '[A-Za-z0-9][\w\x80-\xFF]*',
		_select      => '[\w\x80-\xFF\*,\s\~]+',
		path         => '[\w\x80-\xFF\-\/\.\:\~\\\\]+',
		table        => '',
		file         => '',
		table        => '',      #JWT: ADDED 20020515
		ext          => '',      #JWT:ADD FILE EXTENSIONS.
		directory    => '',
		timestamp    => 0,
		_read        => ',',
		_write       => ',',
		_record      => "\n",    #JWT:SUPPORT ANY RECORD-SEPARATOR!
		fields       => {},
		fieldregex   => '',      #ADDED 20001218
		use_fields   => '',
		key_fields   => '',
		order        => [],
		types        => {},
		lengths      => {},
		scales       => {},
		defaults     => {},
		records      => [],
		platform     => 'Unix',
		fake_lock    => 0,
		default_lock => 'Sprite.lck',
		sprite_lock_file => '',
		lock_handle  => '',
		default_try  => 10,
		sprite_lock_try     => '',
                lock_sleep   => 1,
		errors       => {},
		lasterror    => 0,     #JWT:  ADDED FOR ERROR-CONTROL
		lastmsg      => '',
		CaseTableNames  => 0,    #JWT:  19990991 TABLE-NAME CASE-SENSITIVITY?
		LongTruncOk  => 0,     #JWT: 19991104: ERROR OR NOT IF TRUNCATION.
		LongReadLen  => 0,     #JWT: 19991104: ERROR OR NOT IF TRUNCATION.
		RaiseError   => 0,     #JWT: 20000114: ADDED DBI RAISEERROR HANDLING.
		silent       => 0,
		dirty			 => 0,     #JWT: 20000229: PREVENT NEEDLESS RECOMMITS.
		StrictCharComp => 0,    #JWT: 20010313: FORCES USER TO PAD STRING LITERALS W/SPACES IF COMPARING WITH "CHAR" TYPES.
		sprite_forcereplace => 0,  #JWT: 20010912: FORCE DELETE/REPLACE OF DATAFILE (FOR INTERNAL WEBFARM USE)!
		sprite_Crypt => 0,  #JWT: 20020109:  Encrypt Sprite table files! FORMAT:  [[encrypt=|decrypt=][Crypt]::CBC;][[IDEA[_PP]|DES]_PP];]keystr
		sprite_reclimit => 0, #JWT: 20010123: PERMIT LIMITING # OF RECORDS FETCHED.
		sprite_sizelimit => 0, #JWT: 20010123: SAME AS RECLIMIT, NEEDED BOR BACKWARD COMPAT.
		sprite_actlimit => 0, #JWT: 20010123: SAME AS RECLIMIT, NEEDED BOR BACKWARD COMPAT.
		dbuser			=> '',      #JWT: 20011026: SAVE USER'S NAME.
		dbname			=> '',      #JWT: 20020515: SAVE DATABASE NAME.
		CBC			=> 0,       #JWT: 20020529: SAVE Crypt::CBC object, if encrypting!
		sprite_xsl	=> '',      #JWT: 20020611: OPTIONAL XSL TEMPLATE FILE.
		sprite_CaseFieldNames => 0,  #JWT: 20020618: FIELD-NAME CASE-SENSITIVITY?
		sprite_lastsequence => '',   #JWT: ADDED 20020905 TO SUPPORT DBIx::GeneratedKey!
		sprite_nocase => 0,    #JWT: ADDED 20040323 TO SUPPORT CASE-INSENSITIVE WHERE-CLAUSES LIKE LDAP.
		                       #NOTE - ONLY CURRENTLY FOR "LIKE/NOT LIKE" (VALUE=1|'L)!
		                       #MAY ADD OTHER VALUES LATER!
		ASNAMES => {},         #ADDED 20040913 TO SUPPORT "AS" IN SELECTS.
	    };

    $self->{separator} = { Unix  => '/',    Mac => ':',   #JWT: BUGFIX.
		   PC    => '\\\\', VMS => '/' };
	$self->{maxsizes} = {
		'LONG RAW' => 2147483647,
		'RAW' => 255,
		'LONG' => 2147483647, 
		'CHAR' => 255,
		'NUMBER' => 38,
		'AUTONUMBER' => 38,
		'DOUBLE' => 15,
		'DATE' => 19,
		'VARCHAR' => 2000,
		'VARCHAR2' => 2000,
		'BOOLEAN' => 1,
		'BLOB'	=> 2147483647,
		'MEMO'	=> 2147483647, 
	};

    bless $self, $class;

	 for (my $i=0;$i<scalar(@_);$i+=2)   #ADDED: 20020109 TO ALLOW SETTING ATTRIBUTES IN INITIALIZATION!
	 {
	 	$self->{$_[$i]} = $_[$i+1];
	 }

    $self->initialize;
    return $self;
}

sub initialize
{
    my $self = shift;

    $sprite_user = $self->{'dbuser'};   #ADDED 20011026.
    $self->define_errors;
    $self->set_os ($^O) if (defined $^O);
	if ($self->{sprite_Crypt})  #ADDED: 20020109
	{
		my (@cryptinfo) = split(/\;/, $self->{sprite_Crypt});
		unshift (@cryptinfo, 'IDEA')  if ($#cryptinfo < 1);
		unshift (@cryptinfo, 'Crypt::CBC')  if ($#cryptinfo < 2);
		$self->{sprite_Crypt} = 1;
		$self->{sprite_Crypt} = 2  if ($cryptinfo[0] =~ s/^encrypt\=//i);
		$self->{sprite_Crypt} = 3  if ($cryptinfo[0] =~ s/^decrypt\=//i);
		$cryptinfo[0] = 'Crypt::' . $cryptinfo[0]  
				unless ($cryptinfo[0] =~ /\:\:/);
		eval "require $cryptinfo[0]";
	    if ($@)
	    {
			$errdetails = $@;
			$self->display_error (-526);
		}
		else
		{
		    eval {$self->{CBC} = Crypt::CBC->new($cryptinfo[2], $cryptinfo[1]); };
		    if ($@)
		    {
				$errdetails = "Can't find/use module \"$cryptinfo[1].pm\"? ($@)!";
				$self->display_error (-526);
			}
		}
	}
	return $self;
}

sub set_delimiter
{
    my ($self, $type, $delimiter) = @_;
    $type      ||= 'other';
    $delimiter ||= $self->{_read} || $self->{_write};

    $type =~ s/^-//;
    $type =~ tr/A-Z/a-z/;

    if ($type eq 'read') {
	$self->{_read} = $delimiter;
    } elsif ($type eq 'write') {
	$self->{_write} = $delimiter;
    } elsif ($type eq 'record') {    #JWT:SUPPORT ANY RECORD-SEPARATOR!
	###$delimiter =~ s/^\r//  if ($self->{platform} eq 'PC');  #20000403 (BINMODE HANDLES THIS!!!)
	$self->{_record} = $delimiter;
    } else {
	$self->{_read} = $self->{_write} = $delimiter;
    }

    return (1);
}

sub set_os
{
    my ($self, $platform) = @_;
    #$platform = 'Unix', return unless ($platform);  #20000403.
    return $self->{platform}  unless ($platform);    #20000403

    $platform =~ s/\s//g;

#    if ($platform =~ /^(?:OS2|(?:Win)?NT|Win(?:dows)?95|(?:MS)?DOS)$/i) {
#	$self->{platform} = '';      #20000403

	if ($platform =~ /(?:darwin|bsdos)/i)  #20020218:  ADDED FOR NEW MAC OS "OS X" WHICH USES "/"
	{
		$self->{platform} = 'Unix';
	}
    elsif ($platform =~ /(OS2|Win|DOS)/i)
    {  #20000403
		$self->{platform} = 'PC';
    }
    elsif ($platform =~ /^Mac(?:OS|intosh)?$/i)
    {
		$self->{platform} = 'Mac';
    }
    elsif ($platform =~ /^VMS$/i)
    {
		$self->{platform} = 'VMS';
    }
    else
    {
		$self->{platform} = 'Unix';
    }
    return (1);
}

sub set_db_dir
{
    my ($self, $directory) = @_;
    return (0) unless ($directory);

    stat ($directory);

    #if ( (-d _) && (-e _) && (-r _) && (-w _) ) {  #20000103: REMD WRITABLE REQUIREMENT!
    if ( (-d _) && (-e _) && (-r _) ) {
	$self->{directory} = $directory;
	return (1);
    } else {
	return (0);
    }
}

sub set_db_ext      #JWT:ADD FILE EXTENSIONS.
{
    my ($self, $ext) = @_;

    return (0) unless ($ext);

    stat ($ext);

	$self->{ext} = $ext;
	return (1);
}

sub get_path_info
{
    my ($self, $file) = @_;
    my ($separator, $path, $name, $full);
    $separator = $self->{separator}->{ $self->{platform} };

    ($path, $name) = $file =~ m|(.*?)([^$separator]+)$|o;

	$name =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
    if ($path) {
	$full  = $file;
    } else {
	#$path  = $self->{directory} || fastcwd;
	$path  = $self->{directory};
	$path .= $separator;
	$full  = $path . $name;
    }
    return wantarray ? ($path, $name) : $full;
}

sub set_lock_file
{
    my ($self, $file, $lock_try) = @_;

    if (!$file || !$lock_try) {
	return (0);
    } else {
	$self->{sprite_lock_file} = $file;
	$self->{sprite_lock_try}  = $lock_try;
    
	return (1);
    }
}

sub lock
{
    my $self = shift;
    my $count;

    $self->{sprite_lock_file} ||= $self->{default_lock}; 
    $self->{sprite_lock_file}   = $self->get_path_info ($self->{sprite_lock_file});
    $self->{sprite_lock_try}  ||= $self->{default_try};

    local *FILE;

    $count = 0;

    while (++$count <= $self->{sprite_lock_try}) {	
	if (sysopen (FILE, $self->{sprite_lock_file}, 
		           O_WRONLY|O_EXCL|O_CREAT, 0644)) {

	    $self->{fake_lock}   = 1;
	    $self->{lock_handle} = *FILE;

	    last;
	} else {
	    select (undef, undef, undef, $self->{lock_sleep});
	}
    }

    return $self->{fake_lock};
}

sub unlock
{
    my $self = shift;

    if ($self->{fake_lock}) {

	close ($self->{lock_handle}) || return (0);
	unlink ($self->{sprite_lock_file})  || return (0);
	
	$self->{fake_lock}   = 0;
	$self->{lock_handle} = '';

    }

    return (1);
}

sub sql
{
    my ($self, $query) = @_;
    my ($command, $status);

    return wantarray ? () : -514  unless ($query);

	$sprite_user = $self->{'dbuser'};   #ADDED 20011026.
	$self->{lasterror} = 0;
	$self->{lastmsg} = '';
    #$query   =~ s/\n/ /gs;   #REMOVED 20011107
    $query   =~ s/^\s*(.*?)\s*$/$1/s;
    $command = '';

	if ($query =~ /^($self->{commands})/io)
	{
		$command = $1;
		$command =~ tr/A-Z/a-z/;    #ADDED 19991202!
		$status  = $self->$command ($query);
		if (ref ($status) eq 'ARRAY')
		{     #SELECT RETURNED OK (LIST OF RECORDS).
			#unshift (@$status, 1);

			return wantarray ? @$status : $status;
		}
		else
		{
			if ($status < 0)
			{             #SQL RETURNED AN ERROR!
				$self->display_error ($status);
				#return ($status);
				return wantarray ? () : $status;
			}
			else
			{                        #SQL RETURNED OK.
				return wantarray ? ($status) : $status;
			}
		}
	}
	else
	{
		return wantarray ? () : -514;
	}
}

sub display_error
{	
    my ($self, $error) = @_;

    my $other = $@ || $! || 'None';

    print STDERR <<Error_Message  unless ($self->{silent});

Oops! Sprite encountered the following error when processing your request:

    ($error) $self->{errors}->{$error} ($errdetails)

Here's some more information to help you:

	file:  $self->{file}
    $other

Error_Message

#JWT:  ADDED FOR ERROR-CONTROL.

	$self->{lasterror} = $error;
	$self->{lastmsg} = "$error:" . $self->{errors}->{$error};
	$self->{lastmsg} .= '('.$errdetails.')'  if ($errdetails);  #20000114

	$errdetails = '';   #20000114
	die $self->{lastmsg}  if ($self->{RaiseError});  #20000114.

    return (1);
}

sub commit
{
    my ($self, $file) = @_;
    my ($status, $full_path);

    $status = 1;
    return $status  unless ($self->{dirty});

	if ($file)
	{
		$full_path = $self->get_path_info ($file);
		$full_path .= $self->{ext}  if ($self->{ext});  #JWT:ADD FILE EXTENSIONS.
	}
	else   #ADDED 20010911 TO ASSIST IN HANDLING AUTOCOMMIT!
	{
		$full_path = $self->{file};
	}
	$status = $self->write_file ($full_path);
	$self->display_error ($status) if ($status <= 0);

	return undef  if ($status <= 0);   #ADDED 20000103

	my $blobglob = $full_path;
	$blobglob =~ s/$self->{ext}$/\_\*\_$$\.tmp/;
	my @tempblobs;
	eval qq|\@tempblobs = <$blobglob>|;
	my ($blobfile, $tempfile);
	my $bloberror = 0;
	while (@tempblobs)
	{
		$tempfile = shift(@tempblobs);
		$blobfile = $tempfile;
		$blobfile =~ s/\_$$\.tmp/\.ldt/;
		unlink $blobfile  if ($self->{sprite_forcereplace} && -w $blobfile && -e $tempfile);
		$bloberror = $?.':'.$@  if ($?);
		rename ($tempfile, $blobfile) or ($bloberror = "Could not rename $tempfile to $blobfile (".$!.')');
		last  if ($bloberror);
	}
	if ($bloberror)
	{
		$errdetails = $bloberror;
		$self->display_error (-528);
		return undef;
	}
	else
	{
		$blobglob = $self->{directory}.$self->{separator}->{ $self->{platform} }
				.$self->{table}."_*_$$.del";
		@tempblobs = ();
		eval qq|\@tempblobs = <$blobglob>|;
		while (@tempblobs)
		{
			$tempfile = shift(@tempblobs);
			unlink $tempfile;
		}
		$self->{dirty} = 0;
	}
    return $status;
}

sub xclose
{
    my ($self, $file) = @_;
	
	my $status = $self->commit($file);
    undef $self;

    return $status;
}

##++
##  Private Methods
##--

sub define_errors
{
    my $self = shift;
    my $errors;

    $errors = {};

    $errors->{'-501'} = 'Could not open specified database.';
    $errors->{'-502'} = 'Specified column(s) not found.';
    $errors->{'-503'} = 'Incorrect format in [select] statement.';
    $errors->{'-504'} = 'Incorrect format in [update] statement.';
    $errors->{'-505'} = 'Incorrect format in [delete] statement.';
    $errors->{'-506'} = 'Incorrect format in [add/drop column] statement.';
    $errors->{'-507'} = 'Incorrect format in [alter table] statement.';
    $errors->{'-508'} = 'Incorrect format in [insert] command.';
    $errors->{'-509'} = 'The no. of columns does not match no. of values.';
    $errors->{'-510'} = 'A severe error! Check your query carefully.';
    $errors->{'-511'} = 'Cannot write the database to output file.';
    $errors->{'-512'} = 'Unmatched quote in expression.';
    $errors->{'-513'} = 'Need to open the database first!';
    $errors->{'-514'} = 'Please specify a valid query.';
    $errors->{'-515'} = 'Cannot get lock on database file.';
    $errors->{'-516'} = 'Cannot delete temp. lock file.';
    $errors->{'-517'} = "Built-in function failed ($@).";
    $errors->{'-518'} = "Unique Key Constraint violated.";  #JWT.
    $errors->{'-519'} = "Field would have to be truncated.";  #JWT.
    $errors->{'-520'} = "Can not create existing table (drop first!).";  #20000225 JWT.
    $errors->{'-521'} = "Can not change datatype on non-empty table.";  #20000323 JWT.
    $errors->{'-522'} = "Can not decrease field-size on non-empty table.";  #20000323 JWT.
    $errors->{'-523'} = "Special table \"DUAL\" is READONLY!";  #20000323 JWT.
	$errors->{'-524'} = "Can't store non-NULL value into AUTOSEQUENCE!"; #20011029 JWT.
	$errors->{'-525'} = "Can't update AUTOSEQUENCE field!"; #20011029 JWT.
	$errors->{'-526'} = "Can't find encryption modules"; #20011029 JWT.
	$errors->{'-527'} = "Database illedgable - wrong encryption key/method?"; #20011029 JWT.
	$errors->{'-528'} = "Could not read/write BLOB file!"; #20011029 JWT.
	$errors->{'-529'} = "Conversion between BLOB and nonBLOB types not (yet) supported!"; #20011029 JWT.
    $errors->{'-530'} = 'Incorrect format in [create] command.'; #ADDED 20020222
    $errors->{'-531'} = 'Encryption of XML databases not supported.'; #ADDED 20020516.
    $errors->{'-532'} = 'XML requested, but XML::Simple module not available!'; #ADDED 20020516.
    $errors->{'-533'} = 'Incorrect format in [truncate] statement.';
    $self->{errors} = $errors;

    return (1);
}

sub parse_expression
{
    my ($self, $query, $colmlist) = @_;
    return unless ($query);
    my ($column, @strings, %numopmap, %stropmap, $numops, $strops, $special);
	$colmlist ||= join('|',@{$self->{order}});
	my ($psuedocols) = "CURRVAL|NEXTVAL";

	unless ($colmlist =~ /\S/o)
	{
		$self->{file} =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
		#$thefid = $self->{file};
		$colmlist = &load_columninfo($self, '|');
		return $colmlist  if ($colmlist =~ /^\-?\d+$/o);
	}
    $column    = $self->{column};
    @strings   = ();

    %numopmap  = ( '=' => 'eq', '==' => 'eq', '>=' => 'ge', '<=' => 'le',
                   '>' => 'gt', '<'  => 'lt', '!=' => 'ne', '<>' => 'ne');
    %stropmap  = ( 'eq' => '==', 'ge' => '>=', 'le' => '<=', 'gt' => '>',
	           'lt' => '<',  'ne' => '!=' , '=' => '==');

    $numops    = join '|', keys %numopmap;
    $strops    = join '|', keys %stropmap;

    $special   = "$strops|and|or";
	#NOTE!:  NEVER USE ANY VALUE OF $special AS A COLUMN NAME IN YOUR TABLES!!

    ##++
    ##  The expression: "([^"\\]*(\\.[^"\\]*)*)" was provided by
    ##  Jeffrey Friedl. Thanks Jeffrey!
    ##--

$query =~ s/\\\\/\x02\^2jSpR1tE\x02/gso;    #PROTECT "\\"   #XCHGD. TO 2 LINES DOWN 20020111
#$query =~ s/\\\'|\'\'/\x02\^3jSpR1tE\x02/gs;   #CHGD. TO NEXT 20040305 2 FIX PERL BUG? UNPROTECT WON'T WORK IF STR="m'str\x02..\x02more'"?!?!?!
$query =~ s/\\\'|\'\'/\^3jSpR1tE/gso;   #20000201  #PROTECT "", \", '', AND \'.

my ($i, $j, $j2, $k);
my $caseopt = ($self->{sprite_nocase} ? 'i' : '');  #ADDED 20040325.

while (1)
{
	$i = 0;
	$i = ($query =~ s|\b($colmlist)\s+not\s+like\s+|$1 !^ |is);
	$i = ($query =~ s|\b($colmlist)\s+like\s+|$1 =^ |is)  unless ($i);
	if ($i)
	{
		#if ($query =~ /([\=\!]\^\s*)(["'])(.*?)\2/s)  #CHGD. TO NEXT 20040325.
		if ($query =~ s/([\=\!]\^\s*)(["'])(.*?)\2/$1$2$3$2$caseopt/s)  #20001010
		{
			$j = "$1$2";   #EVERYTHING BEFORE THE QUOTE (DELIMITER), INCLUSIVE
			$i = $3;       #THE STUFF BETWEEN THE QUOTES.
			my $iquoted = $i;    #ADDED 20000816 TO FIX "LIKE 'X.%'" (X\.%)!
			$iquoted =~ s/([\\\|\(\)\[\{\^\$\*\+\?\.])/\\$1/gs;
			my ($k) = "\^$iquoted\$";
			$k =~ s/^\^%//so;
			$k =~ s/%\$$//s;
			$j2 = $j;
			#$j2 =~ s/^\^/~/;   #CHANGE SPECIAL OPERATORS (=^ AND !^) BACK TO (=~ AND !~).
			$j2 =~ s/^(.)\^/$1~/s;   #20001010 CHANGE SPECIAL OPERATORS (=^ AND !^) BACK TO (=~ AND !~).
			$k =~ s/_/./gso;
			$query =~ s/\Q$j$i\E/$j2$k/s;
		}
	}
	else
	{
		last;
	}
}
	
    #$query =~ s/([!=][~\^])\s*(m)?([^\w;\s])([^\3\\]*(?:\\.[^\3\\]*)*)\3(i)?/
	#THIS REGEX LOOKS FOR USER-DEFINED FUNCTIONS FOLLOWING "=~ OR !~ (LIKE), 
	#FINDS THE MATCHING CLOSE PARIN(IF ANY), AND SURROUNDS THE FUNCTION AND 
	#IT'S ARGS WITH AN "&", A DELIMITER LATER USED TO EVAL IT.
	
	1 while ($query =~ s|([!=][~\^])\s*([a-zA-Z_]+)(.*)$|
			my ($one, $two, $three) = ($1, $2, $3);
			my ($parincnt) = 0;
			my (@lx) = split('', $three);
			my ($i);
			
			for ($i=0;$i<=length($three);$i++)
			{
				++$parincnt  if ($lx[$i] eq '(');
				last  unless ($parincnt);
				--$parincnt  if ($lx[$i] eq ')');
			}
			"$one ".'&'."$two".substr($three,0,$i).'&'.
					substr($three,$i);
	|es);

	#THIS REGEX HANDLES ALL OTHER LIKE AND PERL "=~" AND "!~" OPERATORS.

	@perlconds = ();
    $query =~ s%\b($colmlist)\s*([!=][~\^])\s*(m)?(.)([^\4]*?)\4(i)?%  #20011017: CHGD TO NEXT.
	           my ($m, $i, $delim, $four, $one, $fldname) = ($3, $6, $4, $5, $2, $1);
	           my ($catchmatch) = 0;
                   $m ||= ''; $i ||= '';
					$m = 'm'  unless ($delim eq '/');
					my ($three) = $delim;
					$four =~ s/\\\(/\x02\^5jSpR1tE\x02/gso;
					$four =~ s/\\\)/\x02\^6jSpR1tE\x02/gso;
					if ($four =~ /\(.*\)/)
					{
						#$four =~ s/\(//g;
						#$four =~ s/\)//g;
						$catchmatch = 1;
					}
					$four =~ s/\x02\^5jSpR1tE\x02/\(/gso;
					$four =~ s/\x02\^6jSpR1tE\x02/\)/gso;
                    push (@strings, "$m$delim$four$three$i");
					push (@perlconds, "\$_->{$fldname} $one *$#strings; push (\@perlmatches, \$1)  if (defined \$1); push (\@perlmatches, \$2)  if (defined \$2);")  if ($catchmatch);
                   "$fldname $one *$#strings";
               %geis;
    #$query =~ s|(['"])([^\1\\]*(?:\\.[^\1\\]*)*)\1|
    $query =~ s|(["'])(.*?)\1|
                   push (@strings, "$1$2$1"); "*$#strings";
 	       |ges;

	$query =~ s/\x02\^3jSpR1tE\x02/\'/gso;   #RESTORE PROTECTED SINGLE QUOTES HERE.
	$query =~ s/\^3jSpR1tE/\'/gso;       #ADDED 20040913 RESTORE PROTECTED SINGLE QUOTES HERE.
	#$query =~ s/\x02\^2jSpR1tE\x02/\\/gs;   #RESTORE PROTECTED SLATS HERE.  #CHGD. TO NEXT 20020111
	$query =~ s/\x02\^2jSpR1tE\x02/\\\\/gso;   #RESTORE PROTECTED SLATS HERE.
	for $i (0..$#strings)
	{
		#$strings[$i] =~ s/\x02\^3jSpR1tE\x02/\\\'/gs; #CHGD. TO NEXT IF-STMT. 20040503.
		#### NOTE:  STRING MUST *NOT* CONTAIN BOTH SINGLE-QUOTES AND GRAVS AND "^"S!!!!!
		 if ($strings[$i] =~ /^m\'/o)  #TEST MODIFIED 20050429 TO FIX BUG - IF STRING IS LIKE, THEN CHANGE m'str' to m`str` and restore ' UNESCAPED!
		 {                             #ALSO HAD 2 REMOVE "\X02" BRACKETS ON RESERVED STR. (PERL BUG?)
			 $strings[$i] =~ s/\^3jSpR1tE/\'/gso; #RESTORE PROTECTED SINGLE QUOTES HERE.
			 if ($string !~ /\`/o)  #NO GRAVS IN STRING, SAVE TO BRACKET W/GRAVS.
			 {
				 $strings[$i] =~ s/^m\'/m\`/o;
				 $strings[$i] =~ s/\'${caseopt}$/\`$caseopt/;   #JWT:MODIFIED 20150123 TO INCLUDE $caseopt TO FIX BUG W/sprite_nocase
			 }
			 else   #GRAVS TAKEN TOO, TRY "^" FOR BRACKET CHAR. IF BOTH GRAVS & "^" TAKEN, THEN PUNT!
			 {
				 $strings[$i] =~ s/^m\'/m\^/o;
				 $strings[$i] =~ s/\'${caseopt}$/\^$caseopt/;   #JWT:MODIFIED 20150123 TO INCLUDE $caseopt TO FIX BUG W/sprite_nocase
			 }
		 }
		 else
		 {
			 $strings[$i] =~ s/\^3jSpR1tE/\\\'/gso; #RESTORE PROTECTED SINGLE QUOTES HERE.
		 }
		$strings[$i] =~ s/\x02\^2jSpR1tE\x02/\\\\/gso;   #RESTORE PROTECTED SLATS HERE.
	}

	if ($query =~ /^($column)$/)
	{
		$i = $1;
		#$query = '&' . $i  unless ($i =~ $colmlist);  #CHGD. TO NEXT (20011019)
		$query = '&' . $i  unless ($i =~ m/($colmlist)/i);
	}

    $query =~ s#\b($colmlist)\s*($numops)\s*\*#$1 $numopmap{$2} \*#gis;
    $query =~ s#\b($colmlist)\s*($numops)\s*\'#$1 $numopmap{$2} \'\'#gis;
    $query =~ s#\b($colmlist)\s*($numops)\s*($colmlist)#$1 $numopmap{$2} $3#gis;
    #$query =~ s#\b($colmlist)\s*($numops)\s*($column(?:\(.*?\))?)#$1 $numopmap{$2} $3#gi;
    $query =~ s%\b($column\s*(?:\(.*?\))?)\s+is\s+null%$1 eq ''%igs;
    $query =~ s%\b($column\s*(?:\(.*?\))?)\s+is\s+not\s+null%$1 ne ''%igs;
    #$query =~ s%\b($colmlist)\s*(?:\(.*?\))?)\s*($numops)\s*CURRVAL%$1 $2 &pscolfn($self,$3)%gi;
    $query =~ s%($column)\s*($numops)\s*($column\.(?:$psuedocols))%"$1 $2 ".&pscolfn($self,$3)%egs;
    #$query =~ s%\b($column\s*(?:\(.*?\))?)\s*($numops)\s*($column\s*(?:\(.*?\))?)%   #CHGD. TO NEXT 20020108 TO FIX BUG WHEN WHERE-CLAUSE TESTED EQUALITY WITH NEGATIVE CONSTANTS.
    $query =~ s%\b($column\s*(?:\(.*?\))?)\s*($numops)\s*((?:[\+\-]?[0..9+-\.Ee]+|$column)\s*(?:\(.*?\))?)%
		my ($one,$two,$three) = ($1,$2,$3);
		$one =~ s/\s+$//;
		my $ONE = $one;
		$ONE =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
		if ($one =~ /NUM\s*\(/ || ${$self->{types}}{$ONE} =~ /$NUMERICTYPES/io)
		{
			$two =~ s/^($strops)$/$stropmap{$two}/s;
			"$one $two $three";
		}
		else
		{
			"$one $numopmap{$two} $three";
		}
	 %egs;

# (JWT 8/8/1998) $query =~ s|\b($colmlist)\s+($strops)\s+(\d+)|$1 $stropmap{$2} $3|gi;
	$query =~ s|\b($colmlist)\s*($strops)\s*(\d+)|$1 $stropmap{$2} $3|gis;

	my $ineqop = '!=';
	$query =~ s!\b($colmlist)\s*($strops)\s*(\*\d+)!
		my ($one,$two,$three) = ($1,$2,$3);
		$one =~ s/\s+$//;
		my $ONE = $one;
		$ONE =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
		my $res;
		if ($one =~ /NUM\s*\(/ || ${$self->{types}}{$ONE} =~ /$NUMERICTYPES/ios)
		{
			my ($opno) = undef;    #NEXT 18 LINES ADDED 20010313 TO CAUSE STRING COMPARISENS W/NUMERIC FIELDS TO RETURN ZERO, SINCE PERL NON-NUMERIC STRINGS RETURN ZERO.
			if ($three =~ /^\*\d+/s)
			{
				$opno = substr($three,1);
				$opno = $strings[$opno];
				$opno =~ s/^\'//s;
				$opno =~ s/\'$//s;
			}
			else
			{
				$opno = $three;
			}
			unless ($opno =~ /^[\+\-\d\.][\d\.Ex\+\-\_]*$/s)  #ARGUMENT IS A VALID NUMBER.
			{
			#	$res = '0';
			#	$res = '1'  if ($two eq $ineqop);
				$res = "$one $two '0'";
			}
			else
			{
				$two =~ s/^($strops)$/$stropmap{$two}/s  unless ($opno eq "0");
				$res = "$one $two $three";
			}
		}
		elsif ($self->{StrictCharComp} == 0 && ${$self->{types}}{$ONE} eq 'CHAR')
		{
			my ($opno) = undef;    #NEXT 18 LINES ADDED 20010313 TO CAUSE STRING COMPARISENS W/NUMERIC FIELDS TO RETURN ZERO, SINCE PERL NON-NUMERIC STRINGS RETURN ZERO.
			if ($three =~ /^\*\d+/)
			{
				$opno = substr($three,1);
				my $opstr = $strings[$opno];
				$opstr =~ s/^\'//s;
				$opstr =~ s/\'$//s;
				$strings[$opno] = "'" . sprintf(
							'%-'.${$self->{lengths}}{$ONE}.'s',
							$opstr) . "'";
			}
			$res = "$one $two $three";
		}
		else
		{
			$res = "$one $two $three";
		}
		$res;
		!egis;

	#NOTE!:  NEVER USE ANY VALUE OF $special AS A COLUMN NAME IN YOUR TABLES!!
	#20000224 ADDED "\b" AFTER "$special)" 5 LINES BELOW!
	$query =~ s!\b(($colmlist))\b!
                   my $match = $1;
						$match =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
                   ($match =~ /\b(?:$special)\b/ios) ? "\L$match\E"    : 
                                                    "\$_->{$match}"
               !geis;
	$query =~ s/ (and|or|not) / \L$1\E /igs;   #ADDED 20001011 TO FIX BUG THAT DIDN'T ALLOW UPPER-CASE BOOLOPS! 20001215: SPACES ADDED TO PREVENT "$_->{MandY}" MANGLE!
    $query =~ s|[;`]||gso;
    $query =~ s#\|\|#or#gso;
    $query =~ s#&&#and#gso;

	$query =~ s|(\d+)\s*($strops)\s*(\d+)|$1 $stropmap{$2} $3|gios;   #ADDED 20010313 TO MAKE "1=0" CONDITION EVAL WO/ERROR.
    $query =~ s|\*(\d+)|$strings[$1]|gs;
	 for (my $i=0;$i<=$#perlconds;$i++)
	 {
	 	$perlconds[$i] =~ s|\*(\d+)|$strings[$1]|gs;
	 }

	#THIS REGEX EVALS USER-FUNCTION CALLS FOLLOWING "=~" OR "!~".
	$query =~ s@([!=][~\^])\s*m\&([a-zA-Z_]+[^&]*)\&@
			my ($one, $two) = ($1, $2);
			
			#$one =~ s/\^/\~/s;   #MOVED INSIDE "UNLESS" BELOW 20040323.
			my ($res) = eval($two);
			$res =~ s/^\%//so;
			$res =~ s/\%$//so;
			my ($rtn, $isalike);
			foreach my $i ('/',"'",'"','|')
			{
				unless ($res =~ m%$i%)
				{
					$isalike = 1  if ($one =~ s/\^/\~/so);
					$rtn = "$one m".$i.$res.$i;
					$rtn .= 'i'  if ($self->{sprite_nocase} && $isalike);
					last;
				}
			}
			$rtn;
	@egs;
    return $query;
}

sub check_columns
{
    my ($self, $column_string) = @_;
    my ($status, @columns, $column);

    $status  = 1;
	unless ($self->{sprite_CaseFieldNames})
	{
		$column =~ tr/a-z/A-Z/  if (defined $column);   #JWT
		$column_string =~ tr/a-z/A-Z/;   #JWT
	}
	$self->{use_fields} = $column_string;    #JWT
    @columns = split (/\,/o, $column_string);

    foreach $column (@columns) {
	#$status = 0 unless ($self->{fields}->{$column});  #20000114
		unless ($self->{fields}->{$column})
		{
			$errdetails = $column;
			$status = 0;
		}
	}

    return $status;
}

sub parse_columns
{
	my ($self, $command, $column_string, $condition, $values, 
			$ordercols, $descorder, $fields, $distinct) = @_;
	my ($i, $j, $k, $rowcnt, $status, @columns, $single, $loop, $code, $column);
	my (%colorder, $rawvalue);
	my (@result_index);   #ADDED 20020709 TO SUPPORT SORTING ON COLUMNS NOT IN RESULT-SET.

	my ($psuedocols) = "CURRVAL|NEXTVAL";   #ADDED 20011019.
	local $results = undef;
	my (@keyfields) = split(',', $self->{key_fields});  #JWT: PREVENT DUP. KEYS.
	my (%valuenames);  #ADDED 20001218 TO ALLOW FIELD-NAMES AS RIGHT-VALUES.
	foreach $i (keys %$values)
	{
#		$valuenames{$i} = $values->{$i};   #MOVED TO BOTTOM OF LOOP 20020522 TO FIX SINGLE-QUOTE-IN-VALUE (-517) BUG!
		$values->{$i} =~ s/^\'(.*)\'$/my ($stuff) = $1; 
		$stuff =~ s|\'|\\\'|gso;
		$stuff =~ s|\\\'\\\'|\\\'|gso;
		"'" . $stuff . "'"/es;
		$values->{$i} =~ s/^\'$//so;      #HANDLE NULL VALUES.
		#$values->{$i} =~ s/\n//gs;       #REMOVE LFS ADDED BY NETSCAPE TEXTAREAS! #REMOVED 20011107 - ALLOW \n IN DATA!
		#$values->{$i} =~ s/\r /\r/gs;    #20000108: FIX LFS PREV. CONVERTED TO SPACES! #REMOVED 20011107 (SHOULDN'T NEED ANYMORE).
		$values->{$i} = "''"  unless ($values->{$i} =~ /\S/o);
		$valuenames{$i} = $values->{$i};
	}
	local $SIG{'__WARN__'} = sub { $status = -510; $errdetails = "$_[0] at ".__LINE__ };
	local $^W = 0;
	local ($_);
	$status  = 1;
	$results = [];
	@columns = split (/,/o, $column_string);

	if ($command eq 'update')  #ADDED NEXT 11 LINES 20011029 TO PROTECT AUTOSEQUENCE FIELDS FROM UPDATES.
	{
		foreach my $i (@columns)
		{
			if (${$self->{types}}{$i} =~ /AUTO/o)
			{
				$errdetails = $i;
				return (-525);
			}
		}
	}
	#$single  = ($#columns) ? $columns[$[] : $column_string;
	$single  = ($#columns) ? $columns[$#columns] : $column_string;
	$rowcnt = 0;

	my (@these_results);
	my ($skipreformat) = 0;
	my ($colskipreformat) = 0;
	my (@types);
	my (@coltypes);
	@coltypes = ();
	for (my $i=0;$i<=$#columns;$i++)
	{
		push (@coltypes, (${$self->{types}}{$columns[$i]} =~ /$REFTYPES/o));
	}
	if ($fields)
	{
		@types = ();
		for (my $i=0;$i<=$#{$fields};$i++)
		{
			#$_ = (${$self->{types}}{$columns[$i]} =~ /$REFTYPES/o);
			push (@types, ((${$self->{types}}{$columns[$i]} =~ /$REFTYPES/o)||0));
		}
	}
	else
	{
		push (@$results, [ @$_{@columns} ]);
		for (my $i=0;$i<=@{$_{@columns}};$i++)
		{
			#$_ = (${$self->{types}}{$i} =~ /$REFTYPES/o);
			push (@types, ((${$self->{types}}{$i} =~ /$REFTYPES/o)||0));
		}
	}
	my $blobfid;
	my $jj;
	$self->{sprite_reclimit} ||= $self->{sprite_sizelimit};  #ADDED 20020530 FOR SQL-PERL PLUS!
	for ($loop=0; $loop < scalar @{ $self->{records} }; $loop++)
	{
		next unless (defined $self->{records}->[$loop]);    #JWT: DON'T RETURN BLANK DELETED RECORDS.
		$_ = $self->{records}->[$loop];
		$@ = '';
#####print "<<<<<<< JSPRITE EVAL CONDITION=$condition=\n";
		if ( !$condition || (eval $condition) )
		{
			if ($command eq 'select')
			{
				last  if ($self->{sprite_reclimit} && $loop >= $self->{sprite_reclimit});  #ADDED 20020123 TO SPEED UP INFO-ONLY. FETCHES.
				if ($fields)
				{
					@these_results = ();
					for (my $i=0;$i<=$#{$fields};$i++)
					{
						$fields->[$i] =~ s/($self->{column}\.(?:$psuedocols))\b/&pscolfn($self,$1)/eg;  #ADDED 20011019
						$rawvalue = eval $fields->[$i];
						if ($types[$i] && $rawvalue =~ /^\d+$/o)    #A LONG (REFERENCED) TYPE
						{
							$blobfid = $self->{directory}
									.$self->{separator}->{ $self->{platform} }
									.$self->{table}."_${rawvalue}_$$.tmp";
							if (open(FILE, "<$blobfid"))
							{
								binmode FILE;
								$rawvalue = '';
								my $rawline;
								while ($rawline = <FILE>)
								{
									$rawvalue .= $rawline;
								}
								close FILE;
							}
							else
							{
								$blobfid = $self->{directory}
									.$self->{separator}->{ $self->{platform} }
									.$self->{table}."_${rawvalue}.ldt";
								if (open(FILE, "<$blobfid"))
								{
									binmode FILE;
									$rawvalue = '';
									my $rawline;
									while ($rawline = <FILE>)
									{
										$rawvalue .= $rawline;
									}
									close FILE;
								}
								else
								{
									$errdetails = "$blobfid ($?)";
									return (-528);
								}
							}
						}
						push (@these_results, $rawvalue);
					}
					push (@$results, [ @these_results ]);
					push (@result_index, $loop);   #ADDED 20020709 TO SUPPORT SORTING ON COLUMNS NOT IN RESULT-SET.
				}
				else   #I THINK THIS IS DEAD CODE!!!
				{
#print "<BR>-pc: SHOULD BE DEAD-CODE, PLEASE EMAIL JIM TURNER THE QUERY WHICH GOT HERE!<BR>\n";
#foreach my $i (@columns) {print "<BR>     $i:  =$_{$i}=\n";};
					push (@$results, [ @$_{@columns} ]);
				}
			}
			elsif ($command eq 'update')
			{
				@perlmatches = ();
				for (my $i=0;$i<=$#perlconds;$i++)
				{
					eval $perlconds[$i];
				}
				$code = '';
				my ($matchcnt) = 0;
				my (@valuelist) = keys(%$values);
				#my ($dontchkcols) = '('.join('|',@valuelist).')';
				my ($dontchkcols) = '('.join('|',@valuelist);
				for (my $i=0;$i<=$#columns;$i++)
				{
					$dontchkcols .= '|'.$columns[$i] 	if ($coltypes[$i]);
				}
				$dontchkcols .= ')';
				foreach $i (@valuelist)
				{
					for ($j=0;$j<=$#keyfields;$j++)
					{
						if ($i eq $keyfields[$j])
						{
K:							for ($k=0;$k < scalar @{ $self->{records} }; $k++)
							{
								$rawvalue = $values->{$i};
								$rawvalue =~ s/^\'(.*)\'\s*$/$1/s;
								if ($self->{records}->[$k]->{$i} eq $rawvalue)
								{
									foreach $jj (@keyfields)
									{
										unless ($jj =~ /$dontchkcols/)
										{
											next K  
											unless ($self->{records}->[$k]->{$jj} 
											eq $_->{$jj});
										}
									}
									goto MATCHED1;
								}
							}
							goto NOMATCHED1;
MATCHED1:							++$matchcnt;
						}
					}
				}
				return (-518)  if ($matchcnt && $matchcnt > $#valuelist);   #ALL KEY FIELDS WERE DUPLICATES!
				NOMATCHED1:
				$self->{dirty} = 1;
				foreach $jj (@columns)  #JWT 19991104: FORCE TRUNCATION TO FIT!
				{
					$colskipreformat = $skipreformat;
					#$rawvalue = $values->{$jj};  #CHGD TO NEXT 20011018.
					$rawvalue = $valuenames{$jj};
					#NEXT LINE ADDED 20011018 TO HANDLE PERL REGEX SUBSTITUTIONS.
					$colskipreformat = 0  if ($rawvalue =~ s/\$(\d)/$perlmatches[$1-1]/g);
					if ($valuenames{$jj} =~ /^[_a-zA-Z]/o)  #NEXT 5 LINES ADDED 20000516 SO FUNCTIONS WILL WORK IN UPDATES!
					{
						if ($self->{sprite_CaseFieldNames})
						{
							unless ($self->{fields}->{"$valuenames{$jj}"})  #ADDED TEST 20001218 TO ALLOW FIELD-NAMES AS RIGHT-VALUES.
							{
								#$rawvalue = &chkcolumnparms($self, $valuenames{$jj}); #CHGD. TO NEXT 20011018.
								$rawvalue = &chkcolumnparms($self, $rawvalue);
								$rawvalue = eval $rawvalue;   #FUNCTION EVAL 3
								return (-517)  if ($@);
							}
							else
							{
							$rawvalue = $_->{$valuenames{$jj}};
							}
						}
						else
						{
							unless ($self->{fields}->{"\U$valuenames{$jj}\E"})  #ADDED TEST 20001218 TO ALLOW FIELD-NAMES AS RIGHT-VALUES.
							{
								#$rawvalue = &chkcolumnparms($self, $valuenames{$jj}); #CHGD. TO NEXT 20011018.
								$rawvalue = &chkcolumnparms($self, $rawvalue);
								$rawvalue = eval $rawvalue;   #FUNCTION EVAL 3
								return (-517)  if ($@);
							}
							else
							{
								$rawvalue = $_->{$valuenames{$jj}};
							}
						}
						$colskipreformat = 0;
					}
					else
					{
						$rawvalue =~ s/^\'(.*)\'\s*$/$1/s  if ($valuenames{$jj} =~ /^\'/o);
					}
					#if (${$self->{types}}{$jj} =~ /$NUMERICTYPES/)  #CHGD TO NEXT LINE 20010313.

					unless ($colskipreformat)   #ADDED 20011018 TO OPTIMIZE.
					{
						if (length($rawvalue) > 0 && ${$self->{types}}{$jj} =~ /$NUMERICTYPES/)
						{
							$k = sprintf(('%.'.${$self->{scales}}{$jj}.'f'), 
							$rawvalue);
						}
						else
						{
							$k = $rawvalue;
						}
						#$rawvalue = substr($k,0,${$self->{lengths}}{$jj});
						$rawvalue = (${$self->{types}}{$jj} =~ /$BLOBTYPES/) ? $k : substr($k,0,${$self->{lengths}}{$jj});
						unless ($self->{LongTruncOk} || $rawvalue eq $k || 
								(${$self->{types}}{$jj} eq 'FLOAT'))
						{
							$errdetails = "$jj to ${$self->{lengths}}{$jj} chars";
							return (-519);   #20000921: ADDED (MANY PLACES) LENGTH TO ERRDETAILS "(fieldname to ## chars)"
						}
						if ((${$self->{types}}{$jj} eq 'FLOAT') 
								&& (int($rawvalue) != int($k)))
						{
							$errdetails = "$jj to ${$self->{lengths}}{$jj} chars";
							return (-519);
						}
						#if (${$self->{types}}{$jj} eq 'CHAR')  #CHGD. TO NEXT 20030812.
						if (${$self->{types}}{$jj} eq 'CHAR' && length($rawvalue) > 0)
						{
							$values->{$jj} = "'" . sprintf(
									'%-'.${$self->{lengths}}{$jj}.'s',
									$rawvalue) . "'";
						}
						#elsif (${$self->{types}}{$jj} !~ /$NUMERICTYPES/)  #CHGD. TO NEXT 20010313.
#CHGD. TO NEXT 20160111:						elsif (!length($rawvalue) || ${$self->{types}}{$jj} !~ /$NUMERICTYPES/)
#REASON: STOP TRAILING ZEROES IN DECIMALS FROM BEING TRUNCATED (WE ALREADY FORMATTED AT LINE 1541 ABOVE!)
						else
						{
							$values->{$jj} = "'" . $rawvalue . "'";
						}
#xNEXT 4 REMOVED 20160111:							else
#x						{
#x							$values->{$jj} = $rawvalue;
#x						}
					}
				}
#map { $code .= qq|\$_->{'$_'} = $values->{$_};| } @columns;  #NEXT 2 CHGD TO NEXT 34 20020125 TO SUPPORT BLOB REFERENCING.
#eval $code;
				for (my $i=0;$i<=$#columns;$i++)
				{
					if ($coltypes[$i])   #BLOB REF.
					{
						$code = qq|\$rawvalue = $values->{$columns[$i]};|;
						eval $code;
						$blobfid = $self->{directory}.$self->{separator}->{ $self->{platform} }
						.$self->{table}.'_'.$_->{$columns[$i]}."_$$.tmp";
						if (open(FILE, ">$blobfid"))
						{
							binmode FILE;
							if ($self->{CBC} && $self->{sprite_Crypt} <= 2)  #ADDED: 20020109
							{
								print FILE $self->{CBC}->encrypt($rawvalue);
							}
							else
							{
								print FILE $rawvalue;
							}
							close FILE;
						}
						else
						{
							$errdetails = "$blobfid: ($?)";
							return (-528);
						}
					}
					else
					{
						$code = qq|\$_->{'$columns[$i]'} = $values->{$columns[$i]};|;
						eval $code;
					}
				}

				return (-517)  if ($@);
			}
			elsif ($command eq 'add')
			{
				$_->{$single} = '';   #ORACLE DOES NOT SET EXISTING RECORDS TO DEFAULT VALUE!
			}
			elsif ($command eq 'drop')
			{
				delete $_->{$single};
			}
			++$rowcnt;
			$skipreformat = 1;
		}
		elsif ($@)   #ADDED 20010313 TO CATCH SYNTAX ERRORS.
		{
			$errdetails = "Condition failed ($@) in condition=$condition!";
			return -503  if ($command eq 'select');
			return -505  if ($command eq 'delete');
			return -504;
		}
	}
	if ($status <= 0)
	{
		return $status;
	}
	elsif ( $command ne 'select' )
	{
		return $rowcnt;
	}
	else
	{
		my $theresanull = 0;    #ADDED 20030930 TO HANDLE SINGLE NULL ELEMENT TO FIX _set_fbav ERROR!
		my $rowcntdigits = length(scalar(@$results));  #ADDED 20050514 TO ENSURE SORTING WORKS CORRECTLY.
		my ($ii, $t);
		if ($distinct)   #THIS IF ADDED 20010521 TO MAKE "DISTINCT" WORK.
		{
			my (%disthash);
			for (my $i=0;$i<=$#$results;$i++)
			{
				++$disthash{join("\x02\^2jSpR1tE\x02",@{$results->[$i]})};
			}
			@$results = ();
			#foreach my $i (sort keys(%disthash))  #CHGD. TO NEXT 20050514 - UNNECESSARY TO SORT.
			foreach my $i (keys(%disthash))
			{
				if ($i eq '')   #(20030930) SINGLE NULL ELEMENT MUST GO ON *END* OF ARRAY!
				{
					$theresanull = 1;
					next;
				}
#				push (@$results, [split(/\x02\^2jSpR1tE\x02/, $i)]);   #CHGD. TO NEXT 20031001 TO FIX _set_fbav ERROR!
				push (@$results, [split(/\x02\^2jSpR1tE\x02/o, $i, -1)]);
			}
		}
		if (@$ordercols)   #COMPLETELY OVERHAULED 20020708 TO SUPPORT MULTIPLE ASCENDING/DESCENDING DECISIONS & SORTING ON COLUMNS NOT IN RESULT-SET!
		{
			@$ordercols = reverse(@$ordercols);
			@$descorder = reverse(@$descorder);
			$rowcnt = 0;
			#my ($mysep) = "\x02\^2jSpR1tE\x02";
			#$mysep = "\xFF"  if ($descorder);
#my @mysep = ("^", "V");
			my @mysep = ("\x00", "\xff");
			my @SA = ();
			my @SSA = ();
			my @SI = ();
			my @l;
			for (0..$#columns)
			{
				$colorder{$columns[$_]} = $_;
			}
			for (my $i=0;$i<=$#$results;$i++)
			{
				$t = sprintf('%'.$rowcntdigits.'.'.$rowcntdigits.'d', $i); #ADDED 20050514 TO ENSURE SORTING WORKS CORRECTLY.
				push (@SI, $t);
				push (@SSA, $t);
			}
			my $jcnt = 0;
			my $do = ($descorder->[0] =~ /de/io) ? 1 : 0;
			my $fieldval;
			foreach my $j (@$ordercols)
			{
				$j =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
				#$k = $colorder{$j} || -1;   #CHGD. TO NEXT 20050514 TO FIX BUG THAT PREVENTED SORTING FROM WORKING W/SELECT DISTINCT.
				$k = defined($colorder{$j}) ? $colorder{$j} : -1;
				for (my $i=0;$i<=$#$results;$i++)
				{
					$fieldval = ($k >= 0) ?
					${$results}[$SI[$i]]->[$k] 
					: $self->{records}->[$result_index[$SI[$i]]]->{$j};
					if (${$self->{types}}{$j} eq 'FLOAT' || ${$self->{types}}{$j} eq 'DOUBLE')
					{
						push (@SA, (sprintf('%'.${$self->{lengths}}{$j}.${$self->{scales}}{$j}.'e',$fieldval) . $mysep[$do] . $SSA[$i]));
					}
					elsif (length ($fieldval) > 0 && ${$self->{types}}{$j} =~ /$NUMERICTYPES/)
					{
						push (@SA, (sprintf('%'.${$self->{lengths}}{$j}.${$self->{scales}}{$j}.'f',$fieldval) . $mysep[$do] . $SSA[$i]));
					}
					else
					{
						push (@SA, ($fieldval . $mysep[$do] . $SSA[$i]));
					}
				}
				@SI = ();
				@SSA = ();
				@SI = sort {$a cmp $b} @SA;
				@SI = reverse(@SI)  if ($do);
				@SA = ();
				my $ii = $#SI;
				$l = length($ii);
				if ($jcnt < $#$ordercols)
				{
					$do = ($descorder->[++$jcnt] =~ /de/io) ? 1 : 0;
					for (my $i=0;$i<=$#SI;$i++)
					{
						$SI[$i] = $1  if ($SI[$i] =~ /(\d+)$/o);
						#push (@SSA, sprintf("%${l}d",$ii--) . $mysep[$do] . $SI[$i]);   #CHGD. TO NEXT 20050514 TO ENSURE SORTING WORKS CORRECTLY.
						push (@SSA, sprintf("%${l}d",($do ? $ii-- : $i)) . $mysep[$do] . sprintf('%'.$rowcntdigits.'.'.$rowcntdigits.'d',$SI[$i]));
					}
				}
			}
			@SA = @$results;
			@$results = ();
			for (my $i=0;$i<=$#SI;$i++)
			{
				$SI[$i] = $1  if ($SI[$i] =~ /(\d+)$/o);
				push (@$results, $SA[$SI[$i]]);
			}
		}
		if ($theresanull)    #ADDED 20030930 TO HANDLE SINGLE NULL ELEMENT TO FIX _set_fbav ERROR!
		{
			unshift (@$results, ['']);
		}
#$rowcnt = $#$results + 1;
		#NEXT 2 ADDED 20160111 TO SUPPORT "limit #" ON QUERIES:
		$#{$results} = $self->{sprite_actlimit} - 1
				if ($self->{sprite_actlimit} > 0 && $#{$results} >= $self->{sprite_actlimit});
		$rowcnt = scalar(@{$results});
	}
	unshift (@$results, $rowcnt);
	return $results;
}

sub check_for_reload
{
	my ($self, $file) = @_;
	my ($table, $path, $status);

	return unless ($file);

	if ($file =~ /^DUAL$/io)  #ADDED 20000306 TO HANDLE ORACLE'S "DUAL" TABLE!
	{
		undef %{ $self->{types} };
		undef %{ $self->{lengths} };
		$self->{use_fields} = 'DUMMY';
		$self->{key_fields} = 'DUMMY';   #20000223 - FIX LOSS OF KEY ASTERISK ON ROLLBACK!
		${$self->{types}}{DUMMY} = 'VARCHAR2';
		${$self->{lengths}}{DUMMY} = 1;
		${$self->{scales}}{DUMMY} = 1;
		$self->{order} = [ 'DUMMY' ];
		$self->{fields}->{DUMMY} = 1;
		undef @{ $self->{records} };
		$self->{records}->[0] = {'DUMMY' => 'X'};
		$self->{table} = 'DUAL';
		return (1);
	}

	($path, $table) = $self->get_path_info ($file);
	$file   = $path . $table;  #  if ($table eq $file);
	$file .= $self->{ext}  if ($self->{ext});  #JWT:ADD FILE EXTENSIONS.
	$self->{table} = $table;
	$status = 1;

	my (@stats) = stat ($file);
	if ( ($self->{table} ne $table) || ($self->{file} ne $file
			|| $self->{timestamp} != $stats[9]) )
	{
		if ( (-e _) && (-s _) && (-r _) )
		{

			$self->{table} = $table;
			$self->{file}  = $file;
			$status        = $self->load_database ($file);
			$self->{timestamp} = $stats[9];
		}
		else
		{
			$errdetails = $file;   #20000114
			$status = 0;
		}
	}

	$errdetails = $file  if ($status == 0);   #20000114
	return $status;
}

sub rollback
{
    my ($self) = @_;
    my ($table, $path, $status);

	my (@stats) = stat ($self->{file});
	
	if ( (-e _) && (-T _) && (-s _) && (-r _) )
	{
	    $status = $self->load_database ($self->{file});
		$self->{timestamp} = $stats[9];
	}
	else 
	{
	    $status = 0;
	}
	my $blobglob = $self->{file};
	$blobglob =~ s/$self->{ext}$/\_\*\_$$\.tmp/;
	my $bloberror = 0;
	unlink $blobglob;
	$bloberror = $?.':'.$@  if ($?);
	#if ($bloberror)   #CHGD. TO NEXT 20020222 TO PREVENT EXTRA FALSE ERROR MSG.
	if ($blobglob && $bloberror)
	{
		$errdetails = $bloberror;
		$self->display_error (-528);
		return undef;
	}
	else
	{
		$blobglob = $self->{directory}.$self->{separator}->{ $self->{platform} }
				.$self->{table}."_*_$$.del";
		my @tempblobs = ();
		eval qq|\@tempblobs = <$blobglob>|;
		my ($blobfile, $tempfile);
		while (@tempblobs)
		{
			$tempfile = shift(@tempblobs);
			$blobfile = $tempfile;
			$blobfile =~ s/\_$$\.del/\.ldt/;
			rename ($tempfile, $blobfile);
		}
		$self->{dirty} = 0;
	}
	return $status;
}

sub select
{
    my ($self, $query) = @_;
    my ($i, @l, $regex, $path, $columns, $table, $extra, $condition, 
			$values_or_error, $descorder, @descorder);
	my (@ordercols) = ();
    $regex = $self->{_select};
    $path  = $self->{path};
#$fieldregex = $self->{fieldregex};
	my ($psuedocols) = "CURRVAL|NEXTVAL";

	my $distinct;   #NEXT 2 ADDED 20010521 TO ADD "DISTINCT" CAPABILITY!
	$distinct = 1  if ($query =~ /^select\s+distinct/o);
	$query =~ s/^select\s+distinct(\s+\w|\s*\(|\s+\*)/select $1/is;


    if  ($query =~ /^select\s+
			(.+)\s+
			from\s+
			(\w+)(.*)$/ioxs)
    {
		my ($column_stuff, $table, $extra) = ($1, $2, $3);
    		my (@fields) = ();
    		my ($fnname, $found_parin, $parincnt, $t);
		my @column_stuff;

		#ORACLE COMPATABILITY!

		if ($column_stuff =~ /^table_name\s*$/io && $table =~ /^(user|all)_tables$/io)  #JWT: FETCH TABLE NAMES!
		{
			my $full_path = $self->{directory};
			$full_path .= $self->{separator}->{ $self->{platform} }  
					unless ($full_path !~ /\S/o 
					|| $full_path =~ m#$self->{separator}->{ $self->{platform} }$#);
			my ($cmd);
			$cmd = $full_path . '*' . $self->{ext};
			my ($code);
			if ($^O =~ /Win/i)  #NEEDED TO MAKE PERL2EXE'S "-GUI" VERSION WORK!
			{
				@l = glob $cmd;
			}
			else
			{
				@l = ();
				$code = "while (my \$i = <$cmd>)\n";
				$code .= <<'END_CODE';
				{
					chomp ($i);
					push (@l, $i);
				}
END_CODE
				eval $code;
			}
			$self->{use_fields} = 'TABLE_NAME';  #ADDED 20000224 FOR DBI!
			$values_or_error = [];
			for ($i=0;$i<=$#l;$i++)	{
				#chomp($l[$i]);   #NO LONGER NEEDED 20000228
				if ($^O =~ /Win/i)   #COND. ADDED 20010321 TO HANDLE WINDOZE FILENAMES (CAN BE UPPER & OR LOWER)!
				{
					$l[$i] =~ s/${full_path}(.*?)$self->{ext}/$1/i;
					$l[$i] =~ s/$self->{ext}$//i;  #ADDED 20000418 - FORCE THIS!
				}
				else
				{
					$l[$i] =~ s/${full_path}(.*?)$self->{ext}/$1/;
					$l[$i] =~ s/$self->{ext}$//;  #ADDED 20000418 - FORCE THIS!
				}
				push (@$values_or_error,[$l[$i]]);
			}
			unshift (@$values_or_error, ($#l+1));
			return $values_or_error;
		}

		#SPLIT UP THE FIELDS BEING REQUESTED.

		$self->{ASNAMES} = {};  #ADDED NEXT 4 LINES 20040913 TO SUPPORT "AS".
		while ($column_stuff =~ s/($self->{column})\s+(?:AS|as)\s+($self->{column})/$1/)
		{
			$self->{ASNAMES}->{$1} = $2;
		};
		$column_stuff =~ s/\s+$//o;
		while (1)
		{
			$found_parin = 0;
			$column_stuff =~ s/^\s+//o;
			$fnname = '';
#			$fnname = $1  if ($column_stuff =~ s/^(\w+)//);  #CHGD TO NEXT 20020211!
			$fnname = $1  if ($column_stuff =~ s/^($self->{column}(?:\.(?:$psuedocols))?)//);
			$column_stuff =~ s/^ +//o;
			last  unless ($fnname);
			@column_stuff = split(//o,$column_stuff);
			if ($#column_stuff <= 0 ||  $column_stuff[0] eq ',')
			{
				push (@fields, $fnname);
				$column_stuff =~ s/^\,//o;
				next;
			}

			#FOR FUNCTIONS W/ARGS, WE MUST FIND THE CLOSING ")"!

			for ($i=0;$i<=length($column_stuff);$i++)
			{
				if ($column_stuff[$i] eq '(')
				{
					++$parincnt;
					$found_parin = 1;
				}
				last  if (!$parincnt && $found_parin);
				--$parincnt  if ($column_stuff[$i] eq ')');
			}
			push (@fields, ($fnname . substr($column_stuff,0,$i)));
			$t = substr($column_stuff,$i);
			$t =~ s/^\s*\,//o;
			last unless ($t);
			$column_stuff = $t;
		}

		#$thefid = $table;
		#$self->check_for_reload ($table) || return (-501);  #CHGD. TO NEXT 20020110 TO BETTER CATCH ERRORS.
		my $cfr = $self->check_for_reload($table) || -501;
		return $cfr  if ($cfr < 0);
		$columns = '';
		my (@strings);
		my ($column_list) = '('.join ('|', @{ $self->{order} }).')';

		#DETERMINE WHICH WORDS ARE VALID COLUMN NAMES AND CONVERT THEM INTO 
		#THE VARIABLE FOR LATER EVAL IN PARSE_EXPRESSION!  OTHER WORDS ARE 
		#TREATED AS FUNCTION NAMES AND ARE EVALLED AS THEY ARE.

		for (my $i=0;$i<=$#fields;$i++)
		{
			@strings = ();

			#FIRST, WE MUST PROTECT COLUMN NAMES APPEARING IN LITERAL STRINGS!

			$fields[$i] =~ s|(\'[^\']+\')|
					push (@strings, $1);
					"\x02\^2jSpR1tE\x02$#strings\x02\^2jSpR1tE\x02"
			|eg;

			#NOW CONVERT THE REMAINING COLUMN NAMES TO "$$_{COLUMN_NAME}"!

			#$fields[$i] =~ s/($column_list)/  #ADDED WORD-BOUNDARIES 20011129 TO FIX BUG WHERE ONE COLUMN NAME CONTAINED ANOTHER ONE, IE. "EMPL" AND "EMPLID".
			if ($self->{sprite_CaseFieldNames})
			{
				$fields[$i] =~ s/\b($column_list)\b/
						my ($column_name) = $1;
						$columns .= $column_name . ',';
						"\$\$\_\{$column_name\}"/ieg;
			}
			else
			{
				$fields[$i] =~ s/\b($column_list)\b/
						my ($column_name) = $1;
						$columns .= $column_name . ',';
						"\$\$\_\{\U$column_name\E\}"/ieg;
			}
			$fields[$i] =~ s/\x02\^2jSpR1tE\x02(\d+)\x02\^2jSpR1tE\x02/$strings[$1]/g; #UNPROTECT LITERALS!
		}
		chop ($columns);

		#PROCESS ANY WHERE AND ORDER-BY CLAUSES.

		#if ($extra =~ s/([\s|\)]+)order\s+by\s*(.*)/$1/i)  #20011129
		if ($extra =~ s/([\s|\)]+)order\s+by\s*(.*)/$1/is)
		{
			my $orderclause = $2;
			@ordercols = split(/,/o, $orderclause);
			#$descorder = ($ordercols[$#ordercols] =~ s/(\w+\W+)desc$/$1/i);
			#$descorder = ($ordercols[$#ordercols] =~ s/(\w+\W+)desc$/$1/is); #20011129
			for (my $i=0;$i<=$#ordercols;$i++)
			{
				$descorder = 'asc';
				$descorder = $2  if ($ordercols[$i] =~ s/(\w+)\W+(asc|desc|ascending|descending)$/$1/is); #20020708
				push (@descorder, $descorder);  #20020708
			}
			#$orderclause =~ s/,\s+/,/g;
			for $i (0..$#ordercols)
			{
				$ordercols[$i] =~ s/\s//go;
				$ordercols[$i] =~ s/[\(\)]+//go;
			}
		}
		#if ($extra =~ /^\s+where\s*(.+)$/i)  #20011129
		if ($extra =~ /^\s+where\s*(.+)$/iso)
		{
		    $condition = $self->parse_expression ($1);
		}
		if ($column_stuff =~ /\*/o)
		{
			@fields = @{ $self->{order} };
			$columns = join (',', @fields);
			if ($self->{sprite_CaseFieldNames})
			{
				for (my $i=0;$i<=$#fields;$i++)
				{
					$fields[$i] =~ s/([^\,]+)/\$\$\_\{$1\}/g;
				}
			}
			else
			{
				for (my $i=0;$i<=$#fields;$i++)
				{
					#$fields[$i] =~ s/([^\,]+)/\$\$\_\{\U$1\E\}/g;  #CHGD. TO NEXT 20030208 TO FIX WIERD BUG THAT $#?%ED UP NAMES SOMETIMES!
					$fields[$i] =~ s/([^\,]+)/\$\$\_\{$1\}/g;
					$fields[$i] =~ tr/a-z/A-Z/;
				}
			}
		}
		$columns =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
		$self->check_columns ($columns) || return (-502);
		#$self->{use_fields} = join (',', @{ $self->{order} }[0..$#fields] ) 
		if ($#fields >= 0)
		{
			my (@fieldnames) = @fields;
			for (my $i=0;$i<=$#fields;$i++)
			{
				$fieldnames[$i] =~ s/\(.*$//o;
				$fieldnames[$i] =~ s/\$\_//o;
				$fieldnames[$i] =~ s/[^\w\,]//go;
			}
			$self->{use_fields} = join(',', @fieldnames);
		}
		$values_or_error = $self->parse_columns ('select', $columns, 
				$condition, '', \@ordercols, \@descorder, \@fields, $distinct);    #JWT
		return $values_or_error;
    } 
    else     #INVALID SELECT STATEMENT!
    {
		$errdetails = $query;
		return (-503);
    }
}

sub update
{
    my ($self, $query) = @_;
    my ($i, $path, $regex, $table, $extra, $condition, $all_columns, 
	$columns, $status);
	my ($psuedocols) = "CURRVAL|NEXTVAL";

    ##++
    ##  Hack to allow parenthesis to be escaped!
    ##--

    $query =~ s/\\([()])/sprintf ("%%\0%d: ", ord ($1))/ges;
    $path  =  $self->{path};
    $regex =  $self->{column};

    if ($query =~ /^update\s+($path)\s+set\s+(.+)$/ios) {
	($table, $extra) = ($1, $2);
	return (-523)  if ($table =~ /^DUAL$/io);

	#ADDED IF-STMT 20010418 TO CATCH 
			#PARENTHESIZED SET-CLAUSES (ILLEGAL IN ORACLE & CAUSE WIERD PARSING ERRORS!)
	if ($extra =~ /^\(.+\)\s*where/so)
	{
		$errdetails = 'parenthesis around SET clause?';
		return (-504);
	}
	#$thefid = $table;
	#$self->check_for_reload ($table) || return (-501);  #CHGD. TO NEXT 20020110 TO BETTER CATCH ERRORS.
	my $cfr = $self->check_for_reload($table) || -501;
	return $cfr  if ($cfr < 0);

	return (-511)  unless (-w $self->{file});   #ADDED 19991207!

	$all_columns = {};
	$columns     = '';

	$extra =~ s/\\\\/\x02\^2jSpR1tE\x02/gso;         #PROTECT "\\"
	#$extra =~ s/\\\'|\'\'/\x02\^3jSpR1tE\x02/gs;    #PROTECT '', AND \'. #CHANGED 20000303 TO NEXT 2.
	#$extra =~ s/\'\'/\x02\^3jSpR1tE\x02\x02\^3jSpR1tE\x02/gs;    #CHGD. TO NEXT 20040121
	#$extra =~ s/\'\'/\x02\^3jSpR1tE\x02\x02\^8jSpR1tE\x02/gs;    #PROTECT '', AND \'.
	$extra =~ s/\'\'/\x02\^8jSpR1tE\x02/gso;    #PROTECT ''.
	$extra =~ s/\\\'/\x02\^3jSpR1tE\x02/gso;    #PROTECT \'.
	#$extra =~ s/\\\"|\"\"/\x02\^4jSpR1tE\x02/gs;   #REMOVED 20000303.

	#$extra =~ s/^[\s\(]+(.*)$/$1/;  #STRIP OFF SURROUNDING SPACES AND PARINS.
	#$extra =~ s/[\s\)]+$/$1/;
	#$extra =~ s/^[\s\(]+//;  #STRIP OFF SURROUNDING SPACES AND PARINS.
	#$extra =~ s/[\s\)]+$//;
	$extra =~ s/^\s+//so;  #STRIP OFF SURROUNDING SPACES.
	$extra =~ s/\s+$//so;
	#NOW TEMPORARILY PROTECT COMMAS WITHIN (), IE. FN(ARG1,ARG2).
	my $column = $self->{column};
	$extra =~ s/($column\s*\=\s*)\'(.*?)\'(,|$)/
		my ($one,$two,$three) = ($1,$2,$3);
		$two =~ s|\,|\x02\^5jSpR1tE\x02|go;
		$two =~ s|\(|\x02\^6jSpR1tE\x02|go;
		$two =~ s|\)|\x02\^7jSpR1tE\x02|go;
		$one."'".$two."'".$three;
	/egs;

	1 while ($extra =~ s/\(([^\(\)]*)\)/
			my ($args) = $1;
			$args =~ s|\,|\x02\^5jSpR1tE\x02|go;
			"\x02\^6jSpR1tE\x02$args\x02\^7jSpR1tE\x02";
			/egs);
	###$extra =~ s/\'(.*?)\'/my ($j)=$1;  #PROTECT COMMAS IN QUOTES.
	###		$j=~s|,|\x02\^5jSpR1tE\x02|g; 
	###	"'$j'"/eg;
	my @expns = split(',',$extra);
	for ($i=0;$i<=$#expns;$i++)  #PROTECT "WHERE" IN QUOTED VALUES.
	{
		$expns[$i] =~ s/\x02\^5jSpR1tE\x02/,/gso;
		$expns[$i] =~ s/\x02\^6jSpR1tE\x02/\(/gso;
		$expns[$i] =~ s/\x02\^7jSpR1tE\x02/\)/gso;
		$expns[$i] =~ s/\=\s*'([^']*?)where([^']*?)'/\='$1\x02\^5jSpR1tE\x02$2'/gis;
		$expns[$i] =~ s/\'(.*?)\'/my ($j)=$1; 
			$j=~s|where|\x02\^5jSpR1tE\x02|go; 
		"'$j'"/egs;
	}
	$extra = $expns[$#expns];    #EXTRACT WHERE-CLAUSE, IF ANY.
	$extra =~ s/\x02\^8jSpR1tE\x02/\'\'/gso; #ADDED 20040121.
	$condition = ($extra =~ s/(.*)where(.+)$/where$1/is) ? $2 : '';
	$condition =~ s/\s+//so;
	####$condition =~ s/^\((.*)\)$/$1/g;  #REMOVED 20010313 SO "WHERE ((COND) OP (COND) OP (COND)) WOULD WORK FOR DBIX-RECORDSET. (SELECT APPEARS TO WORK WITHOUT THIS).
	#$expns[$#expns] =~ s/where(.+)$//i;
	$expns[$#expns] =~ s/\s*where(.+)$//iso;   #20000108 REP. PREV. LINE 2FIX BUG IF LAST COLUMN CONTAINS SINGLE QUOTES.
	##########$expns[$#expns] =~ s/\s*\)\s*$//i;   #20010416: ADDED TO FIX BUG WHERE LAST ")" BEFORE "WHERE" NOT STRIPPED!
	##########ABOVE NOT A BUG -- MUST NOT USE PARINS AROUND UPDATE CLAUSE, IE. 
	##########"update table set (a = b, c = d) where e = f" is INVALID (IN ORACLE ALSO!!!!!!!!
	$column = $self->{column};
	$condition = $self->parse_expression ($condition);
	$columns = '';   #ADDED 20010228. (THESE CHGS FIXED INCORRECT ORDER BUG FOR "TYPE", "NAME", ETC. LISTS IN UPDATES).
	for ($i=0;$i<=$#expns;$i++)  #EXTRACT FIELD NAMES AND 
	                             #VALUES FROM EACH EXPRESSION.
	{
		$expns[$i] =~ s!\s*($column)\s*=\s*(.+)$!
			my ($var) = $1;
			my ($val) = $2;

			$var =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
			$columns .= $var . ',';   #ADDED 20010228.
			$val =~ s|%\0(\d+): |pack("C",$1)|ge;
			$all_columns->{$var} = $val;
			$all_columns->{$var} =~ s/\x02\^2jSpR1tE\x02/\\\\/g;
			$all_columns->{$var} =~ s/\x02\^8jSpR1tE\x02/\'\'/g; #ADDED 20040121.
			$all_columns->{$var} =~ s/\x02\^3jSpR1tE\x02/\'/g;   #20000108 REPL. PREV. LINE - NO NEED TO DOUBLE QUOTES (WE ESCAPE THEM) - THIS AIN'T ORACLE.
			#$all_columns->{$var} =~ s/\x02\^4jSpR1tE\x02/\"\"/g;   #REMOVED 20000303.
		!es;
	}
	#$columns   = join (',', keys %$all_columns);  #NEXT 2 CHGD TO 3RD LINE 20010228.
	#$columns =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});   #JWT
	chop($columns);   #ADDED 20010228.
	#$condition = ($extra =~ /^\s*where\s+(.+)$/is) ? $1 : '';

	#$self->check_for_reload ($table) || return (-501);
	$self->check_columns ($columns)  || return (-502);
	#### MOVED UP ABOVE FOR-LOOP SO "NEXTVAL" GETS EVALUATED IN RIGHT ORDER!
	####$condition = $self->parse_expression ($condition);
	$status    = $self->parse_columns ('update', $columns, 
 			    		             $condition, 
					             $all_columns);
	return ($status);
    } else {
		$errdetails = $query;
		return (-504);
    }
}

sub delete 
{
    my ($self, $query) = @_;
    my ($path, $table, $condition, $status, $wherepart);

    $path = $self->{path};

    if ($query =~ /^delete\s+from\s+($path)(?:\s+where\s+(.+))?$/ios) {
	$table     = $1;
	$wherepart = $2;
	#$thefid = $table;
	#$self->check_for_reload ($table) || return (-501);  #CHGD. TO NEXT 20020110 TO BETTER CATCH ERRORS.
	my $cfr = $self->check_for_reload($table) || -501;
	return $cfr  if ($cfr < 0);

	return (-511)  unless (-w $self->{file});   #ADDED 19991207!
	if ($wherepart =~ /\S/o)
	{
		$condition = $self->parse_expression ($wherepart);
	}
	else
	{
		$condition = 1;
	}
	#$self->check_for_reload ($table) || return (-501);

	$status = $self->delete_rows ($condition);

	return $status;
    } else {
		$errdetails = $query;
		return (-505);
    }
}

sub drop
{
    my ($self, $query) = @_;
    my ($path, $table, $condition, $status, $wherepart);

    $path = $self->{path};

	$_ = undef;
    if ($query =~ /^drop\s+table\s+($path)\s*$/ios)
    {
		$table     = $1;
		#$self->check_for_reload ($table) || return (-501);  #CHGD. TO NEXT 20020110 TO BETTER CATCH ERRORS.
		my $cfr = $self->check_for_reload($table) || -501;
		return $cfr  if ($cfr < 0);

		@{$self->{records}} = ();    #ADDED 20021025 TO REMOVE DANGLING DATA (CAUSED TESTS TO FAIL AT 9)!
		@{$self->{order}} = ();
		%{$self->{types}} = ();
		%{$self->{lengths}} = ();
		%{$self->{scales}} = ();
		%{$self->{defaults}} = ();
		$self->{key_fields} = '';

		#SOME DAY, I SHOULD ADD CODE TO DELETE DANGLING BLOB FILES!!!!!!!

#		return (unlink $self->{file} || -501);  #NEXT 2 CHGD. TO FOLLOWING 20020606.
#		return 
		return (unlink $self->{file}) ? '0E0' : -501;
	}
	$errdetails = $query;
	return (-501);
}

sub truncate
{
    my ($self, $query) = @_;
	return $self->delete($query)
			if ($query =~ s/^\s*truncate\s+table\s+/delete from /ios);
	$errdetails = $query;
	return (-533);	
}

sub primary_key_info
{
	my ($self, $query) = @_;
	my $table = $query;
	$table =~ s/^.*\s+(\w+)$/$1/;
	my $cfr = $self->check_for_reload($table) || -501;
	return $cfr  if ($cfr < 0);
		undef %{ $self->{types} };
		undef %{ $self->{lengths} };
		$self->{use_fields} = 'CAT,SCHEMA,TABLE_NAME,PRIMARY_KEY';
		$self->{order} = [ 'CAT', 'SCHEMA', 'TABLE_NAME', 'PRIMARY_KEY' ];
		$self->{fields}->{CAT} = 1;
		$self->{fields}->{SCHEMA} = 1;
		$self->{fields}->{TABLE_NAME} = 1;
		$self->{fields}->{PRIMARY_KEY} = 1;
		undef @{ $self->{records} };
	my (@keyfields) = split(',', $self->{key_fields});  #JWT: PREVENT DUP. KEYS.
		${$self->{types}}{CAT} = 'VARCHAR2';
		${$self->{types}}{SCHEMA} = 'VARCHAR2';
		${$self->{types}}{TABLE_NAME} = 'VARCHAR2';
		${$self->{types}}{PRIMARY_KEY} = 'VARCHAR2';
		${$self->{lengths}}{CAT} = 50;
		${$self->{lengths}}{SCHEMA} = 50;
		${$self->{lengths}}{TABLE_NAME} = 50;
		${$self->{lengths}}{PRIMARY_KEY} = 50;
		${$self->{defaults}}{CAT} = undef;
		${$self->{defaults}}{SCHEMA} = undef;
		${$self->{defaults}}{TABLE_NAME} = undef;
		${$self->{defaults}}{PRIMARY_KEY} = undef;
		${$self->{scales}}{PRIMARY_KEY} = 50;
		${$self->{scales}}{PRIMARY_KEY} = 50;
		${$self->{scales}}{PRIMARY_KEY} = 50;
		${$self->{scales}}{PRIMARY_KEY} = 50;
	my $results;
	my $keycnt = scalar(@keyfields);
	while (@keyfields)
	{
		push (@{$results}, [0, 0, $table, shift(@keyfields)]);
	}
	unshift (@$results, $keycnt);
	return $results;
}

sub delete_rows
{
    my ($self, $condition) = @_;
    my ($status, $loop);
    local $SIG{'__WARN__'} = sub { $status = -510; $errdetails = "$_[0] at ".__LINE__  };
    local $^W = 0;

    #$status = 1;
    $status = 0;

	my @blobcols;
	foreach my $i (keys %{$self->{types}})
	{
		push (@blobcols, $i)  if (${$self->{types}}{$i} =~ /$REFTYPES/o)
	}
	my ($blobfid, $delfid, $rawvalue);
	
	$loop = 0;
	while (1)
	{
		#last  if ($loop > scalar @{ $self->{records} });
		#last  if (!scalar(@{$self->{records}}) || $loop > scalar @{ $self->{records} });  #JWT: 19991222
		last  if (!scalar(@{$self->{records}}) || $loop >= scalar @{ $self->{records} });  #JWT: 20000609 FIX INFINITE LOOP!

		$_ = $self->{records}->[$loop];
	
		if (eval $condition)
		{
			foreach my $i (@blobcols)
			{
				$rawvalue = $self->{records}->[$loop]->{$i};
				$blobfid = $self->{directory}
						.$self->{separator}->{ $self->{platform} }
						.$self->{table}."_${rawvalue}.ldt";
				$delfid = $self->{directory}
						.$self->{separator}->{ $self->{platform} }
						.$self->{table}."_${rawvalue}_$$.del";
				rename ($blobfid, $delfid);
			}
			#$self->{records}->[$loop] = undef;
			splice(@{ $self->{records} }, $loop, 1);
			++$status;  #LET'S COUNT THE # RECORDS DELETED!
		}
		else
		{
			++$loop;
		}
    }

	$self->{dirty} = 1  if ($status > 0);
    return $status;
}

sub create
{
	my ($self, $query) = @_;

	my ($i, @keyfields, @values);
### create table table1 (field1 number, field2 varchar(20), field3 number(5,3))
    local (*FILE, $^W);
	local ($/) = $self->{_record};    #JWT:SUPPORT ANY RECORD-SEPARATOR!

    $^W = 0;
	if ($query =~ /^create\s+table\s+($self->{path})\s*\((.+)\)\s*$/is)
	{
		my ($table, $extra) = ($1, $2);

	    $query =~ tr/a-z/A-Z/s  unless ($self->{sprite_CaseFieldNames});  #ADDED 20000225;
	    #$extra =~ tr/a-z/A-Z/;  #ADDED 20000225;
		$extra =~ s/^\s*//so;
		$extra =~ s/\s*$//so;
		$extra =~ s/\((.*?)\)/
				my ($precision) = $1;
				$precision =~ s|\,|\x02\^2jSpR1tE\x02|g;   #PROTECT COMMAS IN ().
				"($precision)"/egs;
		$extra =~ s/([\'\"])([^\1]*?)\1/
				my ($quote) = $1;
				my ($str) = $2;
				$str =~ s|\,|\x02\^2jSpR1tE\x02|g;   #PROTECT COMMAS IN QUOTES.
				"$quote$str$quote"/egs;

		my (@fieldlist) = split(/,/o ,$extra);
		my $fieldname;
		for ($i=0;$i<=$#fieldlist;$i++)
		{
			$fieldlist[$i] =~ s/^\s+//gso;
			$fieldlist[$i] =~ s/\s+$//gso;
			if ($fieldlist[$i] =~ s/^PRIMARY\s+KEY\s*\(([^\)]+)\)$//i)
			{
				my $keyfields = $1;
				$keyfields =~ s/\s+//go;
				$keyfields =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
				@keyfields = split(/\x02\^2jSpR1tE\x02/o ,$keyfields);
			}
		}

		#ALTERED THIS ROUTINE 20021024 TO DO CREATES VIA WRITE_FILE (AS IT SHOULD!)
		#SO THAT NEW XML TABLES GET CREATED IN XML!!!!

		@{$self->{order}} = ();
		%{$self->{types}} = ();
		%{$self->{lengths}} = ();
		%{$self->{scales}} = ();
		%{$self->{defaults}} = ();
		while (@fieldlist)
		{
			$i = shift(@fieldlist);
			#$i =~ s/^\s*\(\s*//;
			last  unless ($i =~ /\S/o);
			$i =~ s/\s+DEFAULT\s+(?:([\'\"])([^\1]*?)\1|([\+\-]?[\d\.]+)|(NULL))$/
				my ($value) = $4 || $3 || $2 || $1;
				$value = ''  if ($4);
				push (@values, $value);
				"=<3>"/ieg;
			$i =~ s/\s+/=/o;
			$i =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
			$fieldname = $i;
			$fieldname =~ s/=.*//o;
			#NEXT LINE ADDED 20030901 TO ALLOW PRIMARY-KEY ATTRIBUTE ON SAME LINE AS FIELD.
			push (@keyfields, $fieldname)  if ($i =~ s/\s*PRIMARY\s+KEY\s*//i);
			my ($tp,$len,$scale);
			$i =~ s/\w+\=//o;
			$i =~ s/\s+//go;
			if ($i =~ /(\w+)(?:\((\d+))?(?:\x02\^2jSpR1tE\x02(\d+))?/o)
			{
				$tp = $1;
				$len = $2;
				$scale = $3;
			}
			else
			{
				$tp = 'VARCHAR2';
			}
			unless ($len)
			{
				$len = 40;
				$len = 10    if ($tp =~ /NUM|INT|FLOAT|DOUBLE/o);
				#$len = 5000  if ($tp =~ /LONG|BLOB|MEMO/);  #CHGD TO NEXT 20020110.
				$len = $self->{LongReadLen} || 0  if ($tp =~ /$BLOBTYPES/);
			}
			unless ($scale)
			{
				$scale = $len;
				if ($tp eq 'FLOAT')
				{
					$scale -= 3;
				}
				elsif ($tp =~ /$NUMERICTYPES/)
				{
					$scale = 0;
				}
			}
			my ($value) = '';
			if ($i =~ /\<3\>/)
			{
				$value = shift(@values);
				my ($rawvalue);
				#if ($tp =~ /$NUMERICTYPES/)  #CHGD TO NEXT LINE 20010313.
				if (length($value) > 0 && $tp =~ /$NUMERICTYPES/)
				{
					$rawvalue = sprintf(('%.'.$scale.'f'), 
							$value);
				}
				else
				{
					$rawvalue = $value;
				}
				#$value = substr($rawvalue,0,$len);  #CHGD. TO NEXT 20020110.
				$value = ($tp =~ /$BLOBTYPES/) ? $rawvalue : substr($rawvalue,0,$len);
				unless ($self->{LongTruncOk} || $value eq $rawvalue || 
						($tp eq 'FLOAT'))
				{
					$errdetails = "$fieldname to $len chars";
					return (-519);
				}
				if (($tp eq 'FLOAT') 
						&& (int($value) != int($rawvalue)))
				{
					$errdetails = "$fieldname to $len chars";
					return (-519);
				}
#				if ($tp eq 'CHAR')  #CHGD. TO NEXT 20030812.
				if ($tp eq 'CHAR' && length($rawvalue) > 0)
				{
					$rawvalue = sprintf('%-'.$len.'s',$value);
				}
				else
				{
					$rawvalue = $value;
				}
#				if ($tp eq 'CHAR')  #REDUNDANT CODE REMOVED 20030812
#				{
#					$value = sprintf('%-'.$len.'s',$rawvalue);
#				}
#				else
#				{
#					$value = $rawvalue;
#				}
			}
			push (@{$self->{order}}, $fieldname);
			${$self->{types}}{$fieldname} = $tp;
			${$self->{lengths}}{$fieldname} = $len;
			${$self->{scales}}{$fieldname} = $scale;
			${$self->{defaults}}{$fieldname} = $value;
		}
		$self->{key_fields} = join(',',@keyfields);
		$self->{dirty} = 1;
		@{$self->{records}} = ();    #ADDED 20021025 TO REMOVE DANGLING DATA (CAUSED TESTS TO FAIL AT 9)!

		$self->commit($table);       #ALWAYS AUTOCOMMIT NEW TABLES (ORACLE DOES)!
		my $cfr = $self->check_for_reload($table) || -501;
		return $cfr  if ($cfr < 0);		
	}
	elsif ($query =~ /^create\s+sequence\s+($self->{path})(?:\s+inc(?:rement)?\s+by\s+(\d+))?(?:\s+start\s+with\s+(\d+))?/is)
	{
		my ($seqfid, $incval, $startval) = ($1, $2, $3);

		$incval = 1  unless ($incval);
		$startval = 0  unless ($startval);

		my ($new_file) = $self->get_path_info($seqfid) . '.seq';
####		$new_file =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
		unlink ($new_file)  if ($self->{sprite_forcereplace} && -e $new_file);  #ADDED 20010912.
		if (open (FILE, ">$new_file"))
		{
			print FILE "$startval,$incval\n";
			close (FILE);
		}
		else
		{
			$errdetails = "$@/$? (file:$new_file)";
			return -511;
		}
	}
	else    #ADDED 20020222 TO CHECK WHETHER TABLE CREATED!
	{
		$errdetails = $query;
		return -530;
	}
}

sub alter
{
    my ($self, $query) = @_;
    my ($i, $path, $regex, $table, $extra, $type, $column, $count, $status, $fd);
    my ($posn);
	my (@keyfields) = split(',', $self->{key_fields});  #JWT: PREVENT DUP. KEYS.

    $path  = $self->{path};
    $regex = $self->{column};

	if ($query =~ /^alter\s+table\s+($path)\s+(.+)$/ios)
	{
		($table, $extra) = ($1, $2);
		if ($extra =~ /^(add|modify|drop)\s*(.+)$/ios)
		{
			my ($type, $columnstuff) = ($1, $2);
			$columnstuff =~ s/^\s*\(//s;
			$columnstuff =~ s/\)\s*$//s;
###alter table table2 add (newcol1  varchar(5), newcol2 varchar(10))
			$columnstuff =~ s/\((.*?)\)/
				my ($precision) = $1;
				$precision =~ s|\,|\x02\^2jSpR1tE\x02|g;   #PROTECT COMMAS IN ().
				"($precision)"/egs;
			$columnstuff =~ s/([\'\"])([^\1]*?)\1/
				my ($quote) = $1;
				my ($str) = $2;
				$str =~ s|\,|\x02\^2jSpR1tE\x02|gs;   #PROTECT COMMAS IN QUOTES.
				"$quote$str$quote"/egs;

			#$thefid = $table;
			#$self->check_for_reload ($table) || return (-501);  #CHGD. TO NEXT 20020110 TO BETTER CATCH ERRORS.
			my $cfr = $self->check_for_reload($table) || -501;
			return $cfr  if ($cfr < 0);

			my (@values) = ();
			my (@fieldlist) = split(/,/,$columnstuff);
			my ($olddf, $oldln, $tp, $x);
			while (@fieldlist)
			{
				$i = shift(@fieldlist);
				$i =~ s/^\s+//go;
				$i =~ s/\s+$//go;
				last  unless ($i =~ /\S/o);
				$i =~ s/\x02\^2jSpR1tE\x02/\,/go;
				$i =~ s/\s+DEFAULT\s+(?:([\'\"])([^\1]*?)\1|([\+\-]?[\d\.]+)|(NULL))$/
					my ($value) = $4 || $3 || $2 || $1;
					$value = "\x02\^4jSpR1tE\x02"  if ($4);
					push (@values, $value);
					"=\x02\^3jSpR1tE\x02"/ieg;
				$posn = undef;
				$posn = $1  if ($i =~ s/^(\d+)\s*//o);
				$i =~ s/\s+/=/o;
				$fd = $i;
				$fd =~ s/=.*//o;
				$fd =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
				for (my $j=0;$j<=$#keyfields;$j++)
				{
					$i =~ s/=/=*/o  if ($fd eq $keyfields[$j]);
				}
				$x = undef;
				$tp = undef;
				$i =~ /\w+\=[\*]?(\w*)\s*(.*)/o;
				($tp, $x) = ($1, $2);
				$oldln = 0;
				$tp =~ tr/a-z/A-Z/;
				if ($type =~ /modify/io)
				{
					unless ($tp =~ /[a-zA-Z]/)
					{
						$tp = $self->{types}->{$fd};
					}
					unless ($tp eq $self->{types}->{$fd})
					{
						if ($#{$self->{records}} >= 0)
						{
							$errdetails = ($#{$self->{records}}+1) . ' records!';
							return -521;
						}
					}
					$olddf = undef;
					$olddf = $self->{defaults}->{$fd}  if (defined $self->{defaults}->{$fd});
					unless ($tp eq $self->{types}->{$fd})
					{
						$self->{lengths}->{$fd} = 0;
						$self->{scales}->{$fd} = 0;
					}
					$oldln = $self->{lengths}->{$fd};
				}
				$self->{defaults}->{$fd} = undef;
				$self->{lengths}->{$fd} = $1  if ($x =~ s/(\d+)//o);
				unless ($self->{lengths}->{$fd})
				{
					$self->{lengths}->{$fd} = 40;
					$self->{lengths}->{$fd} = 10  if ($tp =~ /NUM|INT|FLOAT|DOUBLE/o);
					#$self->{lengths}->{$fd} = 5000  if ($tp =~ /$BLOBTYPES/);  #CHGD. 20020110
					$self->{lengths}->{$fd} = $self->{LongReadLen} || 0  if ($tp =~ /$BLOBTYPES/);
				}
				if ($self->{lengths}->{$fd} < $oldln && $tp !~ /$BLOBTYPES/)
				{
					$errdetails = $fd;
					return -522;
				}
				$x =~ s/\x02\^3jSpR1tE\x02/
						$self->{defaults}->{$fd} = shift(@values);
						#$self->{defaults}->{$fd} =~ s|\x02\^2jSpR1tE\x02|\,|g;
						$self->{defaults}->{$fd}/eg;
				$self->{fields}->{$fd} = 1;
				if ($self->{types}->{$fd} =~ /$REFTYPES/o || $tp =~ /$REFTYPES/o)
				{
					$errdetails = "$fd: ".$self->{types}->{$fd}." <=> $tp";
					return -529;
				}
				$self->{types}->{$fd} = $tp;
				$self->{defaults}->{$fd} = $olddf  
					if ((defined $olddf) && !(defined $self->{defaults}->{$fd}));
				$self->{defaults}->{$fd} = undef  if ($self->{defaults}->{$fd} eq "\x02\^4jSpR1tE\x02");
				if ($x =~ s/\,\s*(\d+)//o)
				{
					$self->{scales}->{$fd} = $1;
				}
				elsif ($self->{types}->{$fd} eq 'FLOAT')
				{
					$self->{scales}->{$fd} = $self->{lengths}->{$fd} - 3;
				}
				if (defined $self->{defaults}->{$fd})
				{
					my ($val);
					#if (${$self->{types}}{$fd} =~ /$NUMERICTYPES/)  #CHGD TO NEXT LINE 20010313.
					if (length($self->{defaults}->{$fd}) > 0 && ${$self->{types}}{$fd} =~ /$NUMERICTYPES/)
					{
						$val = sprintf(('%.'.${$self->{scales}}{$fd}.'f'),
								$self->{defaults}->{$fd});
					}
					else
					{
						$val = $self->{defaults}->{$fd};
					}
					#$self->{defaults}->{$fd} = substr($val,0,  #CHGD. TO NEXT 2 20020110
					#		${$self->{lengths}}{$fd});
					$self->{defaults}->{$fd} = (${$self->{types}}{$fd} =~ /$BLOBTYPES/) ? $val : substr($val,0,${$self->{lengths}}{$fd});
					unless ($self->{LongTruncOk} || ${$self->{types}}{$fd} =~ /$BLOBTYPES/
							|| $self->{defaults}->{$fd} eq $val
							|| ${$self->{types}}{$fd} eq 'FLOAT')
					{
						$errdetails = "$fd to ${$self->{lengths}}{$fd} chars";
						return (-519);
					}
					if (${$self->{types}}{$fd} eq 'FLOAT' && 
							int($self->{defaults}->{$fd}) != int($val))
					{
						$errdetails = "$fd to ${$self->{lengths}}{$fd} chars";
						return (-519);
					}
					#if (${$self->{types}}{$fd} eq 'CHAR')  #CHGD TO NEXT 20030812.
					if (${$self->{types}}{$fd} eq 'CHAR' && length($self->{defaults}->{$fd}) > 0)
					{
						$val = sprintf('%-'.${$self->{lengths}}{$fd}.'s', 
								$self->{defaults}->{$fd});
						$self->{defaults}->{$fd} = $val;
					}

					#THIS CODE SETS ALL EMPTY VALUES FOR THIS FIELD TO THE 
					#DEFAULT VALUE.  ORACLE DOES NOT DO THIS!
					#for ($j=0;$j < scalar @{ $self->{records} }; $j++)
					#{
					#	$self->{records}->[$j]->{$fd} = $self->{defaults}->{$fd}  
					#			unless (length($self->{records}->[$j]->{$fd}));
					#}
				}
				if ($type =~ /add/io)
				{
					if (defined $posn)
					{
						my (@myorder) = (@{ $self->{order} }[0..($posn-1)], 
							$fd, 
							@{ $self->{order} }[$posn..$#{ $self->{order} }]);
						@{ $self->{order} } = @myorder;
					}
					else
					{
						push (@{ $self->{order} }, $fd);
					}
				}
				elsif ($type =~ /modify/io)
				{
					if (defined $posn)
					{
						for (my $j=0;$j<=$#{ $self->{order} };$j++)
						{
							if (${ $self->{order} }[$j] eq $fd)
							{
								splice (@{ $self->{order} }, $j, 1);
								my (@myorder) = (@{ $self->{order} }[0..($posn-1)], 
									$fd, 
									@{ $self->{order} }[$posn..$#{ $self->{order} }]);
								@{ $self->{order} } = @myorder;
								last;
							}
						}
					}
				}
				elsif ($type =~ /drop/io)
				{
					$self->check_columns ($fd) || return (-502);
					$count = -1;
					foreach (@{ $self->{order} })
					{
						++$count;
						last if ($_ eq $fd);
					}
					splice (@{ $self->{order} }, $count, 1);
					delete $self->{fields}->{$fd};
					delete $self->{types}->{$fd};
					delete $self->{lengths}->{$fd};
					delete $self->{scales}->{$fd};
				}
			}

			$status = $self->parse_columns ("\L$type\E", $column);
			$self->{dirty} = 1;
			$self->commit($table);   #ALWAYS AUTOCOMMIT TABLE ALTERATIONS!
			return $status;
		}
		else
		{
			$errdetails = $extra;
	 	   return (-506);
		}
	}
	else
	{
		$errdetails = $query;
		return (-507);
	}
}

sub insert
{
    my ($self, $query) = @_;
    my ($i, $path, $table, $columns, $values, $status);
    $path = $self->{path};
    if ($query =~ /^insert\s+into\s+                            # Keyword
                   ($path)\s*                                  # Table
                   (?:\((.+?)\)\s*)?                               # Keys
                   values\s*                                    # 'values'
                   \((.+)\)$/ixos)
{   #JWT: MAKE COLUMN LIST OPTIONAL!

	($table, $columns, $values) = ($1, $2, $3);
	return (-523)  if ($table =~ /^DUAL$/io);
	#$thefid = $table;
	#$self->check_for_reload ($table) || return (-501);  #CHGD. TO NEXT 20020110 TO BETTER CATCH ERRORS.
	my $cfr = $self->check_for_reload($table) || -501;
	return $cfr  if ($cfr < 0);

	$columns ||= '';
	$columns =~ s/\s//gso;
	$columns = join(',', @{ $self->{order} })  unless ($columns =~ /\S/o);  #JWT
	#$self->check_for_reload ($table) || return (-501);
	return (-511)  unless (-w $self->{file});
	unless ($columns =~ /\S/o)
	{
		#$thefid = $self->{file};
		$columns = &load_columninfo($self, ',');
		return $columns  if ($columns =~ /^\-?\d+$/o);
	}

	$values =~ s/\\\\/\x02\^2jSpR1tE\x02/gso;    #PROTECT "\\"  #XCHGD. TO 4 LINES DOWN 20020111
	#$values =~ s/\\\'/\x02\^3jSpR1tE\x02/gs;   #CHGD. TO NEXT 20060720.
	$values =~ s/\\\'/\x02\^3jSpR1tE\x02/gso;    #PROTECT ESCAPED QUOTES.
	$values =~ s/\\\"/\x02\^5jSpR1tE\x02/gso;

	1 while ($values =~ s/\(([^\)]*?)\)/
			my ($j)=$1; 
			$j=~s|\,|\x02\^4jSpR1tE\x02|gso;         #PROTECT "," IN PARENTHESIS (FUNCTION-CALL ARG-LISTS).
			"($j\x02\^6jSpR1tE\x02"
	/egs);
#	$values =~ s/\'([^\']*?)\'/          #CHGD. TO NEXT 20060720.
	$values =~ s/([\'\"])([^\1]*?)\1/
			my ($j)=$2; 
			$j=~s|\,|\x02\^4jSpR1tE\x02|gso;         #PROTECT "," IN QUOTES.
			"'$j'"
	/egs;
	$values =~ s/\x02\^6jSpR1tE\x02/\)/gso;

	my $x;
	my @values = split(/\,\s*/o ,$values);
	$values = '';
	for $i (0..$#values)
	{
		$values[$i] =~ s/^\s+//so;      #STRIP LEADING & TRAILING SPACES.
		$values[$i] =~ s/\s+$//so;
		$values[$i] =~ s/\x02\^5jSpR1tE\x02/\\\"/gso;  #RESTORE PROTECTED SINGLE QUOTES HERE.
		$values[$i] =~ s/\x02\^3jSpR1tE\x02/\\\'/gso;  #RESTORE PROTECTED SINGLE QUOTES HERE.
		$values[$i] =~ s/\x02\^2jSpR1tE\x02/\\\\/gso;  #RESTORE PROTECTED SLATS HERE.
		$values[$i] =~ s/\x02\^4jSpR1tE\x02/\,/gos;    #RESTORE PROTECTED COMMAS HERE.
		if ($values[$i] =~ /^[_a-zA-Z]/so)
		{
			if ($values[$i] =~ /\s*(\w+).NEXTVAL\s*$/o 
					|| $values[$i] =~ /\s*(\w+).CURRVAL\s*$/o)
			{
				my ($seq_file) = $self->get_path_info($1) . '.seq';
				#### REMOVED 20010814 - ALREAD DONE IN GET_PATH_INFO!!!! ####$seq_file =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
				#open (FILE, "<$seq_file") || return (-511);
				unless (open (FILE, "<$seq_file"))
				{
					$errdetails = "$@/$? (file:$seq_file)";
					return (-511);
				}
				$x = <FILE>;
				#chomp($x);
				$x =~ s/\s+$//;   #20000113  CHOMP WON'T WORK HERE IF RECORD DELIMITER SET TO OTHER THAN \n!
				my ($incval, $startval) = split(/,/o ,$x);
				close (FILE);
				$_ = $values[$i];
				if (/\s*(\w+).NEXTVAL\s*$/o)
				{
					#open (FILE, ">$seq_file") || return (-511);
					unlink ($seq_file)  if ($self->{sprite_forcereplace} && -e $seq_file);  #ADDED 20010912.
					unless (open (FILE, ">$seq_file"))
					{
						$errdetails = "$@/$? (file:$seq_file)";
						return (-511);
					}
					$incval += ($startval || 1);
					print FILE "$incval,$startval\n";
					close (FILE);
				}
				$values[$i] = $incval;
				$self->{sprite_lastsequence} = $incval;    #ADDED 20020905 TO SUPPORT DBIx::GeneratedKey!
			}
			else
			{
				#eval {$values[$i] = &{$values[$i]} };
				$values[$i] = eval &chkcolumnparms($self, $values[$i]);   #FUNCTION EVAL 2
				return (-517)  if ($@);
			}
		}
	};
	chop($values);
	$self->check_columns ($columns)  || return (-502);

	$status = $self->insert_data ($columns, @values);
					      
	return $status;
	} else {
		$errdetails = $query;
		return (-508);
	}
}

sub insert_data
{
    my ($self, $column_string, @values) = @_;
    my (@columns, $hash, $loop, $column, $j, $k, $autoColumnIncluded);
	$column_string =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
    @columns = split (/,/, $column_string);
    foreach my $i (@{ $self->{order} })   #NEXT LOOP ADDED 20040913 TO SUPPORT AUTONUMBERING W/O SPECIFYING COLUMN ON INSERT (LIKE MYSQL)?
    {
		if (${$self->{types}}{$i} =~ /AUTO/io)
		{
			$autoColumnIncluded = 0;
			foreach my $j (@columns)
			{
				if ($j eq $i)
				{
					$autoColumnIncluded = 1;
					last;
				}
			}
			unless ($autoColumnIncluded)
			{
				push (@columns, $i);
				push (@values, '');
			}
		}
	}
	$column_string = join(',', @columns);
    #JWT: @values  = $self->quotewords (',', 0, $value_string);
#	if ($#columns > $#values)  #ADDED 20011029 TO DO AUTOSEQUENCING!
#	{
#		$column_string .= ','  unless ($column_string =~ /\,\s*$/);
#		for (my $i=0;$i<=$#columns;$i++)
#		{
#			if (${$self->{types}}{$columns[$i]} =~ /AUTO/)
#			{
#				$column_string =~ s/$columns[$i]\,//;
#				$column_string .= $columns[$i] . ',';
#				push (@values, "''");
#			}
#		}
#		$column_string =~ s/\,\s*$//;
#		@columns = split (/\,/, $column_string);
#	}
    if ($#columns == $#values) {
    
	my (@keyfields) = split(',', $self->{key_fields});  #JWT: PREVENT DUP. KEYS.
	my ($matchcnt) = 0;
	
	$hash = {};

    foreach $column (@{ $self->{order} })
    {
		$column =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});   #JWT
		$hash->{$column} = $self->{defaults}->{$column}  
				if (defined($self->{defaults}->{$column}) && length($self->{defaults}->{$column}));
    }

	for ($loop=0; $loop <= $#columns; $loop++)
	{
	    $column = $columns[$loop];
		$column =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
	
		my ($v);
		if ($self->{fields}->{$column})
		{
			$values[$loop] =~ s/^\'(.*)\'$/my ($stuff) = $1; 
			#$stuff =~ s|\'|\\\'|gs;
			$stuff =~ s|\'\'|\'|gso;
			$stuff/es;
			$values[$loop] =~ s|^\'$||so;      #HANDLE NULL VALUES!!!.
			if (${$self->{types}}{$column} =~ /AUTO/o)  #NEXT 12 ADDED 20011029 TO DO ODBC&MYSQL-LIKE AUTOSEQUENCING.
			{
				if (length($values[$loop]))
				{
					$errdetails = "value($values[$loop]) into column($column)";
					return (-524);
				}
				else
				{
					$v = ++$self->{defaults}->{$column};
					$self->{sprite_lastsequence} = $v;    #ADDED 20020905 TO SUPPORT DBIx::GeneratedKey!
				}
			}
			elsif (length($values[$loop]) || !length($self->{defaults}->{$column}))
			{
				$v = $values[$loop];
			}
			else
			{
				$v = $self->{defaults}->{$column};
			}
			#if (${$self->{types}}{$column} =~ /$NUMERICTYPES/)  #CHGD TO NEXT LINE 20010313.
			if (length($v) > 0 && ${$self->{types}}{$column} =~ /$NUMERICTYPES/)
			{
				$hash->{$column} = sprintf(('%.'.${$self->{scales}}{$column}.'f'), $v);
			}
			elsif (${$self->{types}}{$column} =~ /$REFTYPES/o)  #ADDED 20020124 TO SUPPORT REFERENCED TYPES.
			{
				my $randblobid = int(rand(99999));
				my $randblobfid;
				do {
					$randblobid = int(rand(99999));
					$randblobfid = $self->{directory}
							.$self->{separator}->{ $self->{platform} }
							.$self->{table}."_${randblobid}_$$.tmp";
				} while (-e $randblobfid);
				if (open(FILE, ">$randblobfid"))
				{
					binmode FILE;
					if ($self->{CBC} && $self->{sprite_Crypt} <= 2)  #ADDED: 20020109
					{
						print FILE $self->{CBC}->encrypt($v);
					}
					else
					{
						print FILE $v;
					}
					close FILE;
					$hash->{$column} = $randblobid;
				}
				else
				{
					$errdetails = "$randblobfid: ($?)";
					return (-528);
				}
			}
			else
			{
				$hash->{$column} = $v;
			}
			#$v = substr($hash->{$column},0,${$self->{lengths}}{$column});  #CHGD TO NEXT (20020110)
			$v = (${$self->{types}}{$column} =~ /$BLOBTYPES/) ? $hash->{$column} : substr($hash->{$column},0,${$self->{lengths}}{$column});
			unless ($self->{LongTruncOk} || $v eq $hash->{$column} || 
					(${$self->{types}}{$column} eq 'FLOAT'))
			{
				$errdetails = "$column to ${$self->{lengths}}{$column} chars";
				return (-519);
			}
			if ((${$self->{types}}{$column} eq 'FLOAT') 
					&& (int($v) != int($hash->{$column})))
			{
				$errdetails = "$column to ${$self->{lengths}}{$column} chars";
				return (-519);
			}
			#elsif (${$self->{types}}{$column} eq 'CHAR')   #CHGD. TO NEXT 20030812.
			elsif (${$self->{types}}{$column} eq 'CHAR' && length($v) > 0)
			{
				$hash->{$column} = sprintf('%-'.${$self->{lengths}}{$column}.'s',$v);
			}
			else
			{
				$hash->{$column} = $v;
			}
		}
	}

	#20000201 - FIX UNIQUE-KEY TEST FOR LARGE DATASETS.

recloop: 	for ($k=0;$k < scalar @{ $self->{records} }; $k++)  #CHECK EACH RECORD.
	{
		$matchcnt = 0;
valueloop:		foreach $column (keys %$hash)   #CHECK EACH NEW VALUE AGAINST IT'S RESPECTIVE COLUMN.
		{
keyloop:			for ($j=0;$j<=$#keyfields;$j++)  
			{
				if ($column eq $keyfields[$j])
				{
					if ($self->{records}->[$k]->{$column} eq $hash->{$column})
					{
						++$matchcnt;
						return (-518)  if ($matchcnt && $matchcnt > $#keyfields);  #ALL KEY FIELDS WERE DUPLICATES!
					}
				}
			}
		}
		#return (-518)  if ($matchcnt && $matchcnt > $#keyfields);  #ALL KEY FIELDS WERE DUPLICATES!
	}


	push @{ $self->{records} }, $hash;
	
	$self->{dirty} = 1;
	return (1);
    } else {
		$errdetails = "$#columns != $#values";   #20000114
		return (-509);
    }
}						    

sub write_file
{
    my ($self, $new_file) = @_;
    my ($i, $j, $status, $loop, $record, $column, $value, $fields, $record_string);
	my (@keyfields) = split(',', $self->{key_fields});  #JWT: PREVENT DUP. KEYS.
	return ($self->display_error (-531) * -531)
			if (($self->{_write} =~ /^xml/io) && $self->{CBC} && $self->{sprite_Crypt} <= 2);

    local (*FILE, $^W);
	local ($/);
	if ($self->{CBC} && $self->{sprite_Crypt} <= 2)  #ADDED: 20020109
	{
		$/ = "\x03^0jSp".$self->{_record};    #(EOR) JWT:SUPPORT ANY RECORD-SEPARATOR!
	}
	elsif ($self->{_write} !~ /^xml/io)
	{
		$/ = $self->{_record};    #JWT:SUPPORT ANY RECORD-SEPARATOR!
	}

    $^W = 0;

    #$status = (scalar @{ $self->{records} }) ? 1 : -513;
    $status = 1;   #JWT 19991222

	return 1  if $#{$self->{order}} < 0;  #ADDED 20000225 PREVENT BLANKING OUT TABLES, IE IF USER CREATES SEQUENCE W/SAME NAME AS TABLE, THEN COMMITS!
	
		#########$new_file =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
	unlink ($new_file)  if ($status >= 1 && $self->{sprite_forcereplace} && -e $new_file);  #ADDED 20010912.
    if ( ($status >= 1) && (open (FILE, ">$new_file")) ) {
	binmode FILE;   #20000404

	#if (($^O eq 'MSWin32') or ($^O =~ /cygwin/i)) #CHGD. TO NEXT 20020221
	if ($self->{platform} eq 'PC')
	{
		$self->lock || $self->display_error (-515);
	}
	else    #GOOD, MUST BE A NON-M$ SYSTEM :-)
	{
		eval { flock (FILE, $JSprite::LOCK_EX) || die };

		if ($@)
		{
			$self->lock || $self->display_error (-515)  if ($@);
		}
	}

	$fields = '';

	my $reccnt = scalar @{ $self->{records} };
	if ($self->{_write} =~ /^xml/io)
	{
		require MIME::Base64;
		$fields = <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
END_XML
		$fields .= <<END_XML  if ($self->{sprite_xsl});
<?xml-stylesheet type="text/xsl" href="$self->{sprite_xsl}"?>
END_XML
		$fields .= <<END_XML;
<database name="$self->{dbname}" user="$self->{dbuser}">
 <select query="select * from $self->{table}" rows="$reccnt">
END_XML
		$fields .= '  <columns order="'.join(',',@{ $self->{order} }).'">'."\n";
		my ($iskey, $haveadefault, $havemaxsize, $typeinfo);
		for $i (0..$#{$self->{order}})
		{
			$iskey = 'NO';
			for ($j=0;$j<=$#keyfields;$j++)  #JWT: MARK KEY FIELDS.
			{
				if (${$self->{order}}[$i] eq $keyfields[$j])
				{
					$iskey = 'PRIMARY';
					last;
				}
			}
			$haveadefault = ${$self->{defaults}}{${$self->{order}}[$i]};
			$havemaxsize = (${$self->{types}}{${$self->{order}}[$i]} =~ /$BLOBTYPES/) 
					? ($self->{LongReadLen} || '0') 
					: ($self->{maxsizes}->{${$self->{types}}{${$self->{order}}[$i]}} 
					|| ${$self->{lengths}}{${$self->{order}}[$i]} || '0');
			$fields .= <<END_XML
   <column>
    <name>${$self->{order}}[$i]</name>
    <type>${$self->{types}}{${$self->{order}}[$i]}</type>
    <size>$havemaxsize</size>
    <precision>${$self->{lengths}}{${$self->{order}}[$i]}</precision>
    <scale>${$self->{scales}}{${$self->{order}}[$i]}</scale>
    <nullable>NULL</nullable>
    <key>$iskey</key>
    <default>$haveadefault</default>
   </column>
END_XML
		}
		$fields .= "  </columns>\n";
	}
	else
	{
		for $i (0..$#{$self->{order}})
		{
			$fields .= ${$self->{order}}[$i] . '=';
			for ($j=0;$j<=$#keyfields;$j++)  #JWT: MARK KEY FIELDS.
			{
				$fields .= '*'  if (${$self->{order}}[$i] eq $keyfields[$j])
			}
			#$fields .= ${$self->{types}}{${$self->{order}}[$i]} . '('   #CHGD. TO NEXT 20020110
			#		. ${$self->{lengths}}{${$self->{order}}[$i]};
			$fields .= ${$self->{types}}{${$self->{order}}[$i]};
			unless (${$self->{types}}{${$self->{order}}[$i]} =~ /$BLOBTYPES/)
			{
				$fields .= '(' . ${$self->{lengths}}{${$self->{order}}[$i]};
				if (${$self->{scales}}{${$self->{order}}[$i]} 
						&& ${$self->{types}}{${$self->{order}}[$i]} =~ /$NUMERICTYPES/)
				{
					$fields .= ',' . ${$self->{scales}}{${$self->{order}}[$i]}
				}
				#$fields .= ')' . $self->{_write};
				$fields .= ')';
			}
			$fields .= '='. ${$self->{defaults}}{${$self->{order}}[$i]}  
					if (length(${$self->{defaults}}{${$self->{order}}[$i]}));
			$fields .= $self->{_write};
		}
		$fields =~ s/$self->{_write}$//;
	}

	if ($self->{CBC} && $self->{sprite_Crypt} <= 2)  #ADDED: 20020109
	{
		print FILE $self->{CBC}->encrypt($fields).$/;
	}
	else
	{
		print FILE "$fields$/";
	}
	my $rsinit = ($self->{_write} =~ /^xml/io) ? "  <row>\n" : '';
	my $rsend = $rsinit ? "  </row>\n" : '';

	for ($loop=0; $loop < $reccnt; $loop++) {
		#++$loop1;
	    $record = $self->{records}->[$loop];

	    next unless (defined $record);

		$record_string = $rsinit;
		#$record_string =~ s/\?/$loop1/;

 	    foreach $column (@{ $self->{order} })
 	    {
			#if (${$self->{types}}{$column} eq 'CHAR') #CHGD. TO NEXT 20030812.
			if (${$self->{types}}{$column} eq 'CHAR' && length($record->{$column}) > 0)
			{
				$value = sprintf(
						'%-'.${$self->{lengths}}{$column}.'s',
						$record->{$column});
			}
			#elsif (${$self->{types}}{$column} =~ /$NUMERICTYPES/)
			#{
			#	$value = sprintf(('%.'.${$self->{scales}}{$column}.'f'), 
			#			$record->{$column});
			#}
			else
			{
				$value = $record->{$column};
			}

			#NEXT 2 ADDED 20020111 TO PERMIT EMBEDDED RECORD & FIELD SEPERATORS.
			$value =~ s/$self->{_record}/\x02\^0jSpR1tE\x02/gso;   #PROTECT EMBEDDED RECORD SEPARATORS.
			$value =~ s/$self->{_write}/\x02\^1jSpR1tE\x02/gso;   #PROTECT EMBEDDED RECORD SEPARATORS.
			$record_string .= $rsinit ? (&xmlescape($column,$value)."\n") 
					: "$self->{_write}$value";
	    }

	    #$record_string =~ s/^$self->{_write}//o;  #CHGD TO NEXT LINE 20010917.
	    $record_string =~ s/^$self->{_write}//s;
	    $record_string .= $rsend;

		if ($self->{CBC} && $self->{sprite_Crypt} <= 2)  #ADDED: 20020109
		{
			print FILE $self->{CBC}->encrypt($record_string).$/;
		}
		else
		{
		    print FILE "$record_string$/";
		}
	}
	if ($rsend)
	{
		$rsend = " </select>\n</database>\n";
		if ($self->{CBC} && $self->{sprite_Crypt} <= 2)  #ADDED: 20020109
		{
			print FILE $self->{CBC}->encrypt($rsend).$/;
		}
		else
		{
		    print FILE "$rsend$/";
		}
	}
	close (FILE);

	my (@stats) = stat ($new_file);
	$self->{timestamp} = $stats[9];

        $self->unlock || $self->display_error (-516);
    } else {
		$status = ($status < 1) ? $status : -511;
    }
    return $status;
}

{
	my %xmleschash = (
		'<' => '&lt;',
		'>' => '&gt;',
		'"' => '&quot;',
		'--' => '&#45;&#45;',
	);
	sub xmlescape
	{
		my $res;

		$_[1] =~ s/\&/\&amp;/gs;
		eval "\$_[1] =~ s/(".join('|', keys(%xmleschash)).")/\$xmleschash{\$1}/gs;";
		#$_[1] =~ s/([\x01-\x1b\x7f-\xff])/"\&\#".ord($1).';'/egs;
		if ($_[1] =~ /[\x00-\x08\x0A-\x0C\x0E-\x19\x7f-\xff]/o)
		{
			return "   <$_[0] xml:encoding=\"base64\">" 
					. MIME::Base64::encode_base64($_[1]) . "</$_[0]>";
		}
		else
		{
			return "   <$_[0]>$_[1]</$_[0]>";
		}	
	}
}

sub load_database 
{
    my ($self, $file) = @_;

	return -531 
			if (($self->{_read} =~ /^xml/io) && $self->{CBC} && $self->{sprite_Crypt} <= 2);

    my ($i, $header, @fields, $no_fields, @record, $hash, $loop, $tp, $dflt);
    local (*FILE);
	local ($/);
	if ($self->{CBC} && $self->{sprite_Crypt} != 2)  #ADDED: 20020109
	{
		$/ = "\x03^0jSp".$self->{_record};    #JWT:SUPPORT ANY RECORD-SEPARATOR!
	}
	else
	{
		$/ = $self->{_record};    #JWT:SUPPORT ANY RECORD-SEPARATOR!
	}

	########$file =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
	#$thefid = $file;
#    open (FILE, $file) || return (-501);
#	binmode FILE;   #20000404

	undef @{ $self->{records} } if (scalar @{ $self->{records} });
	$self->{use_fields} = '';
	$self->{key_fields} = '';   #20000223 - FIX LOSS OF KEY ASTERISK ON ROLLBACK!
	if ($self->{_read} =~ /^xml/io)
	{
		return -532  unless ($XMLavailable);
		my $xs1 = XML::Simple->new();
		my $xmldoc;
		eval {$xmldoc = $xs1->XMLin($file, suppressempty => undef); };
		$errdetails = $@;
		return -501  unless ($xmldoc);
		@fields = ($xmldoc->{select}->{columns}->{order}) 
				? split(/\,/, $xmldoc->{select}->{columns}->{order}) 
				: keys(%{$xmldoc->{select}->{columns}->{column}});
		foreach my $i (0..$#fields)
		{
			#$fields[$i] =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});  #DON'T *SEEM* TO NEED, BUT ADD IF NEEDED!
			$self->{key_fields} .= ($fields[$i] . ',')
					if ($xmldoc->{select}->{columns}->{column}->{$fields[$i]}->{key} 
							eq 'PRIMARY');
			${$self->{types}}{$fields[$i]} = 
					$xmldoc->{select}->{columns}->{column}->{$fields[$i]}->{type};
			${$self->{lengths}}{$fields[$i]} = 
					$xmldoc->{select}->{columns}->{column}->{$fields[$i]}->{precision};
			${$self->{scales}}{$fields[$i]} = 
					$xmldoc->{select}->{columns}->{column}->{$fields[$i]}->{scale};
			${$self->{defaults}}{$fields[$i]} = undef;
			if (length($xmldoc->{select}->{columns}->{column}->{$fields[$i]}->{default}) > 0)
			{
				${$self->{defaults}}{$fields[$i]} = 
						$xmldoc->{select}->{columns}->{column}->{$fields[$i]}->{default};
			}
			$self->{use_fields} .= $fields[$i] . ',';
		}
		if (ref($xmldoc->{select}->{row}) eq 'ARRAY')  #ADDED IF-STMT 20020611 TO HANDLE TABLES W/0 OR 1 RECORD!
		{
			$self->{records} = $xmldoc->{select}->{row};   #TABLE HAS >1 RECORD.
		}
		elsif (ref($xmldoc->{select}->{row}) eq 'HASH')
		{
			$self->{records}->[0] = $xmldoc->{select}->{row};  #TABLE HAS 1 RECORD.
		}
		else
		{
			$self->{records} = undef;   #TABLE HAS NO RECORDS!
		}			
		$xmldoc = undef;

		#UNESCAPE ALL VALUES.

		if (ref($self->{records}) eq 'ARRAY')  #ADDED IF-STMT 20020611 TO SKIP TABLES W/NO RECORDS!
		{
			require MIME::Base64;  #ADDED 20020816!

			for (my $i=0;$i<=$#{$self->{records}};$i++)
			{
				foreach my $j (@fields)
				{
					if ($self->{records}->[$i]->{$j}->{'xml:encoding'})
					{
						$self->{records}->[$i]->{$j} = MIME::Base64::decode_base64($self->{records}->[$i]->{$j}->{content});
					}
					$self->{records}->[$i]->{$j} = ''  if (ref($self->{records}->[$i]->{$j}));
					$self->{records}->[$i]->{$j} =~ s/\&lt;/\</gso;
					$self->{records}->[$i]->{$j} =~ s/\&gt;/\>/gso;
					$self->{records}->[$i]->{$j} =~ s/\&quot;/\"/gso;
					$self->{records}->[$i]->{$j} =~ s/\&\#45;/\-/gso;
					#$self->{records}->[$i]->{$j} =~ s/\&\#0;/\0/gs;
					#$self->{records}->[$i]->{$j} =~ s/\&\#(\d+);/pack('C', $1)/egs;
					$self->{records}->[$i]->{$j} =~ s/\&amp;/\&/gso;
				}
			}
		}
	}
	else
	{
		open (FILE, $file) || return (-501);
		binmode FILE;   #20000404

#		if (($^O eq 'MSWin32') or ($^O =~ /cygwin/i))  #CHGD. TO NEXT 20020221
		if ($self->{platform} eq 'PC')
		{
			$self->lock || $self->display_error (-515);
		}
		else    #GOOD, MUST BE A NON-M$ SYSTEM :-)
		{
			eval { flock (FILE, $JSprite::LOCK_EX) || die };
	
			if ($@)
			{
				$self->lock || $self->display_error (-515)  if ($@);
			}
		}
		$_ = <FILE>;
		chomp;          #JWT:SUPPORT ANY RECORD-SEPARATOR!
		my $t = $_;
		$_ = $self->{CBC}->decrypt($t)  if ($self->{CBC} && $self->{sprite_Crypt} != 2);  #ADDED: 20020109
		return -527  unless (/^\w+\=/o);   #ADDED 20020110

		($header)  = /^ *(.*?) *$/o;
		#####################$header =~ tr/a-z/A-Z/;   #JWT  20000316
	    #@fields    = split (/$self->{_read}/o, $header);  #CHGD TO NEXT LINE 20021216.
		@fields    = split (/\Q$self->{_read}\E/, $header);
		$no_fields = $#fields;

		undef %{ $self->{types} };
		undef %{ $self->{lengths} };
		undef %{ $self->{scales} };   #ADDED 20000306.

		my $ln;
		foreach $i (0..$#fields)
		{
			$dflt = undef;
			($fields[$i],$tp,$dflt) = split(/\=/o ,$fields[$i]);
			$fields[$i] =~ tr/a-z/A-Z/  unless ($self->{sprite_CaseFieldNames});
			$tp = 'VARCHAR(40)'  unless($tp);
			$tp =~ tr/a-z/A-Z/;
			$self->{key_fields} .= $fields[$i] . ',' 
					if ($tp =~ s/^\*//o);   #JWT:  *TYPE means KEY FIELD!
			$ln = 40;
			$ln = 10  if ($tp =~ /NUM|INT|FLOAT|DOUBLE/);
			#$ln = 5000  if ($tp =~ /$BLOBTYPES/);   #CHGD. 20020110.
			$ln = $self->{LongReadLen} || 0  if ($tp =~ /$BLOBTYPES/);
			$ln = $2  if ($tp =~ s/(.*)\((.*)\)/$1/);
			${$self->{types}}{$fields[$i]} = $tp;
			${$self->{lengths}}{$fields[$i]} = $ln;
			${$self->{defaults}}{$fields[$i]} = undef;
			${$self->{defaults}}{$fields[$i]} = $dflt  if (defined $dflt);
			if (${$self->{lengths}}{$fields[$i]} =~ s/\,(\d+)//)
			{
				#NOTE:  ORACLE NEGATIVE SCALES NOT CURRENTLY SUPPORTED!

				${$self->{scales}}{$fields[$i]} = $1;
			}
			elsif (${$self->{types}}{$fields[$i]} eq 'FLOAT')
			{
				${$self->{scales}}{$fields[$i]} = ${$self->{lengths}}{$fields[$i]} - 3;
			}
			${$self->{scales}}{$fields[$i]} = '0'  unless (${$self->{scales}}{$fields[$i]});

			# (JWT 8/8/1998) $self->{use_fields} .= $column_string . ',';    #JWT
			$self->{use_fields} .= $fields[$i] . ',';    #JWT
		}

		while (<FILE>)
		{
			chomp;
			$t = $_;
			$_ = $self->{CBC}->decrypt($t)  if ($self->{CBC} && $self->{sprite_Crypt} != 2);  #ADDED: 20020109

			next unless ($_);

			#@record = split (/$self->{_read}/s, $_);   #CHGD. TO NEXT LINE 20021216
			@record = split (/\Q$self->{_read}\E/s, $_);

			$hash = {};

			for ($loop=0; $loop <= $no_fields; $loop++)
			{
				#NEXT 2 ADDED 20020111 TO PERMIT EMBEDDED RECORD & FIELD SEPERATORS.
				$record[$loop] =~ s/\x02\^0jSpR1tE\x02/$self->{_record}/gs;   #RESTORE EMBEDDED RECORD SEPARATORS.
				$record[$loop] =~ s/\x02\^1jSpR1tE\x02/$self->{_read}/gs;   #RESTORE EMBEDDED RECORD SEPARATORS.
				$hash->{ $fields[$loop] } = $record[$loop];
			}

			push @{ $self->{records} }, $hash;
		}

		close (FILE);

		$self->unlock || $self->display_error (-516);
	}

	chop ($self->{use_fields})  if ($self->{use_fields});  #REMOVE TRAILING ','.
	chop ($self->{key_fields})  if ($self->{key_fields});

	undef %{ $self->{fields} };
	undef @{ $self->{order}  };

	$self->{order} = [ @fields ];
	$self->{fieldregex} = $self->{use_fields};
	$self->{fieldregex} =~ s/,/\|/go;

	map    { $self->{fields}->{$_} = 1 } @fields;

    return (1);
}

sub load_columninfo
{
	my ($self) = shift;
	my ($sep) = shift;

	my $colmlist;

	if ($#{$self->{order}} >= 0)
	{
		$colmlist = join($sep, @{$self->{order}});
	}
	else
	{
		local (*FILE);
		local ($_);
		local ($/) = $self->{_record};    #JWT:SUPPORT ANY RECORD-SEPARATOR!
	
		open(FILE, $self->{file}) || return -501;
		binmode FILE;         #20000404
		if ($self->{_read} =~ /^xml/io)
		{
			return -531  if ($self->{CBC} && $self->{sprite_Crypt} <= 2);
			return -532  unless ($XMLavailable);
	
			my $xs1 = XML::Simple->new();
			my $xmltext = '';
			my $xmldoc;
#			eval {$xmldoc = $xs1->XMLin($self->{file}, suppressempty => undef); };
			while (<FILE>)
			{
				last  if (/^\s*\<row.*\>\s*$/o);
				$xmltext .= $_;
			}
			$xmltext .= <<END_XML;  #MAKE IT WELL-FORMED!
  </row>
 </select>
</database>
END_XML
			eval {$xmldoc = $xs1->XMLin($xmltext, suppressempty => undef); };
			$errdetails = $@;
			return -501  unless ($xmldoc);
			$colmlist = $xmldoc->{select}->{columns}->{order};
			if ($colmlist)
			{
				@{$self->{order}} = split(/$sep/, $colmlist);
			}
			else
			{
				@{$self->{order}} = keys(%{$xmldoc->{select}->{columns}->{column}});
				$colmlist = join($sep, @{$self->{order}});
			}
		}
		else
		{
			my $colmlist = <FILE>;
			chomp ($colmlist);
			#$colmlist =~ s/$self->{_read}/$sep/g;   #CHGD. TO NEXT LINE 20021216
			$colmlist =~ s/\Q$self->{_read}\E/$sep/g;
			@{$self->{order}} = split(/$sep/, $colmlist);
		}
		close FILE;
	}
	return $colmlist;
}

sub pscolfn
{
	my ($self,$id) = @_;
	return $id  unless ($id =~ /CURRVAL|NEXTVAL/);
	my ($value) = '';
	my ($seq_file,$col) = split(/\./,$id);
	$seq_file = $self->get_path_info($seq_file) . '.seq';
#	$seq_file =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE! - REMOVED 20011218 (get_path_info HANDLES THIS RIGHT!)
	#open (FILE, "<$seq_file") || return (-511);
	unless (open (FILE, "<$seq_file"))
	{
		$errdetails = "$@/$? (file:$seq_file)";
		return (-511);
	}
	my $x = <FILE>;
	#chomp($x);
	$x =~ s/\s+$//o;   #20000113
	my ($incval, $startval) = split(/\,/o ,$x);
	close (FILE);
	if ($id =~ /NEXTVAL/o)
	{
		#open (FILE, ">$seq_file") || return (-511);
		unlink ($seq_file)  if ($self->{sprite_forcereplace} && -e $seq_file);  #ADDED 20010912.
		unless (open (FILE, ">$seq_file"))
		{
			$errdetails = "$@/$? (file:$seq_file)";
			return (-511);
		}
		$incval += ($startval || 1);
		print FILE "$incval,$startval\n";
		close (FILE);
	}
	$value = $incval;
	$self->{sprite_lastsequence} = $incval;    #ADDED 20020905 TO SUPPORT DBIx::GeneratedKey!
	return $value;
}

##++
##  NOTE: Derived from lib/Text/ParseWords.pm. Thanks Hal!
##--

sub quotewords {   #SPLIT UP USER'S SEARCH-EXPRESSION INTO "WORDS" (TOKENISE)!

# THIS CODE WAS COPIED FROM THE PERL "TEXT" MODULE, (ParseWords.pm),
# written by:  Hal Pomeranz (pomeranz@netcom.com), 23 March 1994
# (Thanks, Hal!)
# MODIFIED BY JIM TURNER (6/97) TO ALLOW ESCAPED (REGULAR-EXPRESSION)
# CHARACTERS TO BE INCLUDED IN WORDS AND TO COMPRESS MULTIPLE OCCURRANCES
# OF THE DELIMITER CHARACTER TO BE COMPRESSED INTO A SINGLE DELIMITER
# (NO EMPTY WORDS).
#
# The inner "for" loop builds up each word (or $field) one $snippet
# at a time.  A $snippet is a quoted string, a backslashed character,
# or an unquoted string.  We fall out of the "for" loop when we reach
# the end of $_ or when we hit a delimiter.  Falling out of the "for"
# loop, we push the $field we've been building up onto the list of
# @words we'll be returning, and then loop back and pull another word
# off of $_.
#
# The first two cases inside the "for" loop deal with quoted strings.
# The first case matches a double quoted string, removes it from $_,
# and assigns the double quoted string to $snippet in the body of the
# conditional.  The second case handles single quoted strings.  In
# the third case we've found a quote at the current beginning of $_,
# but it didn't match the quoted string regexps in the first two cases,
# so it must be an unbalanced quote and we croak with an error (which can
# be caught by eval()).
#
# The next case handles backslashed characters, and the next case is the
# exit case on reaching the end of the string or finding a delimiter.
#
# Otherwise, we've found an unquoted thing and we pull of characters one
# at a time until we reach something that could start another $snippet--
# a quote of some sort, a backslash, or the delimiter.  This one character
# at a time behavior was necessary if the delimiter was going to be a
# regexp (love to hear it if you can figure out a better way).

	my ($self, $delim, $keep, @lines) = @_;
	my (@words,$snippet,$field,$q,@quotes);

	$_ = join('', @lines);
	while ($_) {
		$field = '';
		for (;;) {
			$snippet = '';
			@quotes = ('\'','"');
			if (s/^(["'`])(.+?)\1//) {
				$snippet = $2;
				$snippet = "$1$snippet$1" if ($keep);
$field .= $snippet;
last;
			}	
			elsif (/^["']/o) {
				$self->display_error(-512);
				return ();
			}
			elsif (s/^\\(.)//o) {
				$snippet = $1;
				$snippet = "\\$snippet" if ($keep);
			}
			elsif (!$_ || s/^$delim//) {  #REMOVE "+" TO REMOVE DELIMITER-COMPRESSION.
				last;
			}
			else {
				while ($_ && !(/^$delim/)) {  #ATTEMPT TO HANDLE TWO QUOTES IN A ROW.
					last  if (/^['"]/ && ($snippet !~ /\\$/o));
					$snippet .= substr($_, 0, 1);
					substr($_, 0, 1) = '';
				}
			}
			$field .= $snippet;
		}
	push(@words, $field);
	}
	@words;
}

sub chkcolumnparms   #ADDED 20001218 TO CHECK FUNCTION PARAMETERS FOR FIELD-NAMES.
{
	my ($self) = shift;
	my ($evalstr) = shift;

#	$evalstr =~ s/\\\'|\'\'/\x02\^2jSpR1tE\x02/g;   #PROTECT QUOTES W/N QUOTES.
#	$evalstr =~ s/\\\"|\"\"/\x02\^3jSpR1tE\x02/g;   #PROTECT QUOTES W/N QUOTES.
	$evalstr =~ s/\\\'/\x02\^2jSpR1tE\x02/gso;   #PROTECT ESCAPED QUOTES.
	$evalstr =~ s/\\\"/\x02\^3jSpR1tE\x02/gso;   #PROTECT ESCAPED QUOTES.
	
	my $i = -1;
	my (@strings);     #PROTECT ANYTHING BETWEEN QUOTES (FIELD NAMES IN LITERALS).
	$evalstr =~ s/([\'\"])([^\1]*?)\1/
			my ($one, $two) = ($1, $2);
			++$i;
			$two =~ s|([\'\"])|$1$1|g;
			$strings[$i] = "$one$two$one";
			"\x02\^4jSpR1tE\x02$i";
	/egs;

	#FIND EACH FIELD NAME PARAMETER & REPLACE IT WITH IT'S VALUE || NAME || EMPTY-STRING.
	#$evalstr =~ s/($fieldregex)/   #CHGD. TO NEXT 20020530 + REMVD THIS VBLE.
	$evalstr =~ s/($self->{fieldregex})/
				my ($one) = $1;
				$one =~ tr!a-z!A-Z!;
				my $res = (defined $_->{$one}) ? $_->{$one} : $one;

				#$res ||= '""';    #CHGD. TO NEXT (20020225)!
				$res = '"'.$res.'"'  unless (${$self->{types}}{$one} =~ m#$NUMERICTYPES#i);
				$res;
	/eigs;

	$evalstr =~ s/\x02\^4jSpR1tE\x02(\d+)/$strings[$1]/g;   #UNPROTECT LITERALS
	$evalstr =~ s/\x02\^3jSpR1tE\x02/\\\'/go;                #UNPROTECT QUOTES.
	$evalstr =~ s/\x02\^2jSpR1tE\x02/\\\"/go;
	return $evalstr;
}

sub SYSTIME
{
	return time;
}

sub SYSDATE
{
	return time;
}

sub NUM
{
	return shift;
}

sub NULL
{
	return '';
}

sub ROWNUM
{
	return (scalar (@$results) + 1);
}

sub USER
{
	return $sprite_user;
}

sub fn_register   #REGISTER SQL-CALLABLE FUNCTIONS.
{
	shift  if (ref($_[0]) eq 'HASH');   #20000224
	my ($fnname, $packagename) = @_;
	$packagename = 'main'  unless ($packagename);

	eval <<END_EVAL;
		sub $fnname
		{
			return &${packagename}::$fnname;
		}
END_EVAL
}

1;
