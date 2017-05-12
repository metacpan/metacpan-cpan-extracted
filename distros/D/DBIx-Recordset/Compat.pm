
###################################################################################
#
#   DBIx::Compat - Copyright (c) 1997-1998 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS IS BETA SOFTWARE!
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Compat.pm,v 1.27 2001/07/10 05:06:51 richter Exp $
#
###################################################################################

package DBIx::Compat ;

use DBI ;

sub SelectFields

    {
    my $hdl   = shift ; 
    my $table = shift ; 
    
    my $sth = $hdl -> prepare ("select * from $table where 1=0") ;
    if (!$sth -> execute ())
        {
        warn "select * from $table where 1=0  failed $DBI::errstr" ;
        return undef ;
        }
    
    return $sth ;
    }

sub SelectFieldsQuoted

    {
    my $hdl   = shift ; 
    my $table = shift ; 
    
    my $sth = $hdl -> prepare ("select * from \"$table\" where 1=0") ;
    if (!$sth -> execute ())
        {
        warn "select * from \"$table\" where 1=0  failed $DBI::errstr" ;
        return undef ;
        }
    
    return $sth ;
    }

sub SelectAllFields

    {
    my $hdl   = shift ; 
    my $table = shift ; 
    
    my $sth = $hdl -> prepare ("select * from $table") ;
    if (!$sth -> execute ())
        {
        warn "select * from $table  failed $DBI::errstr" ;
        return undef ;
        }
    
    return $sth ;
    }



sub ListFields

    {
    my $hdl   = shift ; 
    my $table = shift ; 
    
    my $sth = $hdl -> prepare ("LISTFIELDS $table") ;
    $sth -> execute () or return undef ;

    # Meaning of TYPE has changed from 1.19_18 -> 1.19_19
    $Compat{mSQL}{QuoteTypes} = {   1=>1,   12=>1,   -1=>1 } if (exists ($sth -> {msql_type})) ;

    return $sth ;
    }

sub ListFieldsFunc

    {
    my $hdl   = shift ; 
    my $table = shift ; 
    
    my $sth = $hdl -> func($table, 'listfields' )  or return undef ;
    
    return $sth ;
    }


sub ListTables

    {
    my $hdl   = shift ; 

    return $hdl -> tables ;
    }

sub ListTablesODBC

    {
    my $hdl   = shift ; 

    return grep (!/^MSys/, $hdl -> tables)  ;
    }

sub ListTablesFunc

    {
    my $hdl   = shift ; 

    my @tabs ;

    eval { @tabs = $hdl -> tables } ;
    
    # try the _ListTables function for DBD::mysql before 1.21..
    @tabs = $hdl -> func('_ListTables' ) if ($#tabs < 0 || $@) ;

    return @tabs ;
    }

sub ListTablesPg

    {
    my $hdl   = shift ; 
    my @tabs ;
    my $st = $hdl -> tables ;

    while ($dat = $st -> fetch)
        {
        push @tabs, $dat -> [0] ;
        }	

    return @tabs ;
    }


sub ListTablesIfmx

    {
    my $hdl   = shift ; 

    my @tabs = $hdl -> func('_tables' );

    return @tabs ;
    }


sub LimitOffsetStrPg

    {
    my ($start,$max) = @_;
     
    return ($max > 0?"LIMIT $max":'') . ($start > 0?" OFFSET $start":'') ;
    }	


sub LimitOffsetStrMySQL

    {
    my ($start,$max) = @_;

    $start ||= 0 ;
     
    return ($max > 0)?"LIMIT $start,$max":''  ;
    }	

sub MysqlGetSerial

    {
    my ($dbh, $table) = @_ ;
    
    return $dbh -> {'mysql_insertid'} ;
    }
    
sub SeqGetSerial

    {    
    my ($dbh, $table, $seq) = @_ ;
    
    $seq  ||= ($table . '_seq') ;
    my $sth = $dbh -> prepare ("select $seq.nextval from dual") ;
    $sth -> execute () or die "Cannot get serial from $seq ($DBI::errstr)" ;
    my $row = $sth -> fetchrow_arrayref ;
    
    return $row->[0] ;
    }
    
sub PgGetSerial

    {    
    my ($dbh, $table, $seq) = @_ ;
    
    $seq  ||= ($table . '_seq') ;
    my $sth = $dbh -> prepare ("select nextval ('$seq')") ;
    $sth -> execute () or die "Cannot get serial from $seq ($DBI::errstr)" ;
    my $row = $sth -> fetchrow_arrayref ;
    
    return $row->[0] ;
    }
    

sub InformixGetSerial

    {
    my ($dbh, $table) = @_ ;
    
    my $sth = $dbh -> prepare ("select distinct dbinfo('sqlca.sqlerrd1') from $table") ;
    $sth -> execute () or die "Cannot get serial from $seq ($DBI::errstr)" ;
    my $row = $sth -> fetchrow_arrayref ;
    
    return $row->[0] ;
    }

    
####################################################################################


%Compat =
    (
    '*'  =>
            {
            'Placeholders'   => 10,              # Default: Placeholder are supported
            'ListFields'     => \&SelectFields,  # Default: Use Select to get field names
            'ListTables'     => \&ListTables,    # Default: Use DBI $dbh -> tables
            # QuoteTypes isn't used anymore !!
            'QuoteTypes'   => {   1=>1,   12=>1,  -1=>1, 9 => 1, 10 => 1, 11 => 1}, # Default: ODBC Types, quote char, varchar and longvarchar
            'NumericTypes'   => { 2 => 1, 3 => 1, 4 => 1, 5 => 1, 6 => 1, 7 => 1, 8 => 1, -5 => 1, -6 => 1}, # Default numeric ODBC Types
            'SupportJoin'    => 1,               # Default: Driver supports joins (select with multiple tables)
            'SupportSQLJoin' => 1,               # Default: Driver supports INNER/LEFT/RIGHT JOIN Syntax in SQL select
            'SQLJoinOnly2Tabs' => 0,             # Default: Driver supports LEFT/RIGHT JOIN with more then two tables
            'HaveTypes'      => 1,               # Default: Driver supports $sth -> {TYPE}
            'NullOperator'   => 'IS',            # Default: Operator to compare with NULL is IS
            'HasInOperator'  => 1,               # Default: DBMS support x IN (y)
	    'NeedNullInCreate' => '',            # Default: NULL allowed without explicit declare in CREATE
	    'EmptyIsNull'    => 0,		 # Default: Empty strings ('') and NULL are different
	    'LimitOffset'    => undef,		 # Default: Don't use LIMIT/OFFSET in SELECTs
            'GetSerialPreInsert' => undef,       # Default: Driver does not support serials
            'GetSerialPostInsert' => undef,      # Default: Driver does not support serials
            'CreateTypes' => {},                 # conversion for CreateTables
            'CreateSeq'    => 0,                 # Create sequence for counter
            'CreatePublic' => 0,                 # Create public synonym for table
            'CanDropColumn' => 1,                # DBMS can drop a column
            'QuoteIdentifier' => undef,          # DBMS can handle idntifiers with spaces by quoteing them. Default: no
             },
    'SQLite'  =>
            {
            'Placeholders'   => 10,              # Default: Placeholder are supported
            'ListFields'     => \&SelectFields,  # Default: Use Select to get field names
            'ListTables'     => \&ListTables,    # Default: Use DBI $dbh -> tables
            # QuoteTypes isn't used anymore !!
            'QuoteTypes'   => {   1=>1,   12=>1,  -1=>1, 9 => 1, 10 => 1, 11 => 1}, # Default: ODBC Types, quote char, varchar and longvarchar
            'NumericTypes'   => { 2 => 1, 3 => 1, 4 => 1, 5 => 1, 6 => 1, 7 => 1, 8 => 1, -5 => 1, -6 => 1}, # Default numeric ODBC Types
            'SupportJoin'    => 1,               # Default: Driver supports joins (select with multiple tables)
            'SupportSQLJoin' => 4,               # Default: Driver supports INNER/LEFT/RIGHT JOIN Syntax in SQL select
            'SQLJoinOnly2Tabs' => 0,             # Default: Driver supports LEFT/RIGHT JOIN with more then two tables
            'HaveTypes'      => 0,               # Default: Driver supports $sth -> {TYPE}
            'NullOperator'   => 'IS',            # Default: Operator to compare with NULL is IS
            'HasInOperator'  => 1,               # Default: DBMS support x IN (y)
	    'NeedNullInCreate' => '',            # Default: NULL allowed without explicit declare in CREATE
	    'EmptyIsNull'    => 0,		 # Default: Empty strings ('') and NULL are different
	    'LimitOffset'    => \&LimitOffsetStrPg,		 # Default: Don't use LIMIT/OFFSET in SELECTs
            'GetSerialPreInsert' => undef,       # Default: Driver does not support serials
            'GetSerialPostInsert' => undef,      # Default: Driver does not support serials
            'CreateTypes' =>                        # conversion for CreateTables
                    {
                    'counter'  => 'INTEGER PRIMARY KEY',
                    },
            'CreateSeq'    => 0,                 # Create sequence for counter
            'CreatePublic' => 0,                 # Create public synonym for table
            'CanDropColumn' => 0,                # DBMS can drop a column
            'QuoteIdentifier' => undef,          # DBMS can handle idntifiers with spaces by quoteing them. Default: no
             },

    'ConfFile' =>
	{
            'Placeholders' => 2,		# Placeholders supported, but the perl
						#   type must be the same as the db type
            'ListFields'     => \&SelectFields,     
            'SupportJoin'    => 0,
            'HaveTypes'      => 0		# Driver does not support $sth -> {TYPE}
	},	

    'CSV' =>
	{
            'Placeholders' => 2,                # Placeholders supported, but the perl
						#   type must be the same as the db type
            'ListFields'     => \&SelectFields,      
            'SupportJoin'    => 0,
            'SupportSQLJoin'	=> 0,		    # Driver does not supports INNER/LEFT/RIGHt JOIN Syntax in SQL select
            'HaveTypes'      => 0,              # Driver does not support $sth -> {TYPE}
            'ListTables'     => undef,		# no tables
	    'EmptyIsNull'    => 1,		# DBD::CSV does not really knows about NULL
            'HasInOperator'  => 0,              # DBD::CSV does not support x IN (y)
	},	

    'XBase' =>
	{
          #  'Placeholders' => 2,               # Placeholders supported, but the perl
						#   type must be the same as the db type
            'ListFields'     => \&SelectAllFields,      
            'SupportJoin'    => 0,
            'HaveTypes'      => 0               # Driver does not support $sth -> {TYPE}
	},	

     'Pg' => 
     {
      'Placeholders' => 2,                # Placeholders supported, but the perl
						#   type must be the same as the db type

      'SupportSQLJoin' => 1,              # Driver does not supports INNER/LEFT/RIGHt JOIN Syntax in SQL select
      'NumericTypes'   => { 
                                20 => 1, 
                                21 => 1, 
                                22 => 1, 
                                23 => 1, 
                                700 => 1, 
                                701 => 1, 
                                1005 => 0, 
                                1006 => 1, 
                                1007 => 1, 
                                }, 

     
      'QuoteTypes' =>
                {   16 => 1, 17=>1,   18=>1,   19=>1,   20=>1,   25=>1,  409=>1,  410=>1,
                    411=>1,  605=>1, 
                    702  =>1,   # abstime
                    703  =>1,   # reltime
                    1002=>1, 1003=>1, 1004=>1, 1009=>1, 1026=>1,
                    1039=>1, 1040=>1, 1041=>1, 1042=>1, 1043=>1,
                    1082 =>1,   # date
                    1083 =>1,   # time
                    1184 =>1,   # datetime
                    1186 =>1,   # interval
                    1296 =>1
                 },
      'LimitOffset'    => \&LimitOffsetStrPg, # Only PostgreSQL 6.5+

#### Use the following line for older DBD::Pg versions (< 0.89) which does
#    not support the table_info function
      #            'ListTables'     => \&ListTablesPg,    # DBD::Pg
      'GetSerialPreInsert' => \&PgGetSerial,
      'CreateTypes' =>                 # conversion for CreateTables
      {
       'counter'  => 'serial',
      }
     },


    
  'mSQL' => {
            'Placeholders'	=> 2,		    # Placeholders supported, but the perl
						    #   type must be the same as the db type
            'SupportSQLJoin'	=> 0,		    # Driver does not supports INNER/LEFT/RIGHt JOIN Syntax in SQL select
            'ListFields'	=> \&ListFields,    # mSQL has it own ListFields function
            'ListTables'	=> \&ListTablesFunc,# DBD::mysql $dbh -> func
            'NullOperator'	=> '=',		    # Operator to compare with NULL is =
            'QuoteTypes'	=> {   1=>1,   12=>1,   -1=>1 }
# ### use the following line for older mSQL drivers
#            'QuoteTypes'	=> {   2=>1,   6=>1 }
            },

    'mysql' => {
            'ListFields'   => \&ListFields,	    # mysql has it own ListFields function
            'QuoteTypes'   => {   1=>1,   12=>1,   -1=>1 , 9=>1},
            'Placeholders' => 10,		    # Placeholders supported, but the perl
						    #   type must be the same as the db type
            'SQLJoinOnly2Tabs' => 0,		    # mysql supports LEFT/RIGHT JOIN with more than two tables
            'ListTables'     => \&ListTablesFunc,   # DBD::mysql $dbh -> func
	    'LimitOffset'    => \&LimitOffsetStrMySQL, 
            'GetSerialPostInsert' => \&MysqlGetSerial,
            'CreateTypes' =>                        # conversion for CreateTables
                    {
                    'counter'  => 'integer not null auto_increment',
                    }
            },

    'Solid' => {
            'Placeholders' => 3,		    # Placeholders supported, but cannot use a
						    #   string where a number expected
            'QuoteTypes'   => {   1=>1,   12=>1,   -1=>1, 9=> 1 }
            },

    'ODBC' => {
            'Placeholders' => 10,		    # Placeholders supported, but seems not
						    #   to works all the time ?
            'QuoteTypes'   => {   1=>1,   12=>1,   -1=>1},
 	    'NeedNullInCreate' => 'NULL',          
            'ListTables'     => \&ListTablesODBC,    # Use DBI $dbh -> tables, exclude /^MSys/
            'SQLJoinOnly2Tabs' => 0,             # Driver supports LEFT/RIGHT JOIN only with two tables
            'CreateTypes' =>                        # conversion for CreateTables
                        {
                        'tinytext' => 'text',
                        'text'     => 'longtext',
                        },
           },
    'Oracle' => {
            'Placeholders' => 3,		    # Placeholders supported, but cannot use a
						    #   string where a number expected
            'QuoteTypes'   => {   
                            -4=>1,
                            -3=>1,
                            -1=>1,
                            1=>1, 9=>1,  11=>1,   12=>1, },
            'SupportSQLJoin' => 3,		    # Oracle need  a = b (+) instead of  INNER/LEFT/RIGHt JOIN Syntax in SQL select
	    'EmptyIsNull'    => 1,		    # Oracle converts empty strings ('') to NULL
# older DBD::Orcales only need the following one entry, but some test may fail
#		'HaveTypes'      => 0		    #  Driver does not supports $sth -> {TYPE}
            'GetSerialPreInsert' => \&SeqGetSerial,
            'CreateTypes' =>                        # conversion for CreateTables
                        {
                        'counter'  => 'integer',
                        'tinytext' => 'varchar2(256)',
                        'text'     => 'varchar2(2000)',
                        'datetime' => 'date',
                        'bool'     => 'number(1)',
                        'bit'      => 'number(1)',
                        },
            'CreateSeq'    => 1,                      # Create sequence for counter
            'CreatePublic' => 1,                      # Create public synonym for table
            'CanDropColumn' => 0,                     # DBMS can drop a column
            'QuoteIdentifier' => '""',                # DBMS can handle idntifiers with spaces by quoteing them.
##            'ListFields'     => \&SelectFieldsQuoted, # Use Select to get field names
            },

    'Sybase'  =>
            {
            'Placeholders'   => 10,
            'ListFields'     => \&SelectFields,  
            'QuoteTypes'     => {
                -6=>0, -4=>0, -2=>0, -1=>1, 1=>1, 2=>0, 3=>1,
                4=>0, 6=>0, 7=>0, 9=>0 

				},
            'SupportSQLJoin' => 2,               # Driver need *= instead of  INNER/LEFT/RIGHt JOIN Syntax in SQL select
            'HaveTypes'      => 1,       
            'NullOperator'   => 'IS',
	    'NeedNullInCreate' => 'NULL'          
	    },

    'Informix' => {
            'Placeholders' => 2,
            'SupportSQLJoin' => 4,
            'SQLJoinOnly2Tabs' => 0,
            'ListTables'     => \&ListTablesIfmx,
            'GetSerialPostInsert' => \&InformixGetSerial,
            'QuoteIdentifier' => $ENV{DELIMIDENT}?'""':undef,        # DBMS can handle idntifiers with spaces by quoteing them.
            },


    'Sprite' => {
            'Placeholders' => 2,            # Placeholders supported, but perl type must be the same as type in db
                            #   string where a number expected
            'QuoteTypes'   => {   
                            -4=>1,
                            -3=>1,
                            -1=>1,
                            1=>1, 9=>1,  11=>1,   12=>1, },
            'SupportJoin' => 0,         # NO JOINS (YET) IN SPRITE! 
            'SupportSQLJoin' => 0,          # Oracle need  a = b (+) instead of  INNER/LEFT/RIGHt JOIN Syntax in SQL select
            'EmptyIsNull'    => 1,          # Sprite converts empty strings ('') to NULL
            'HaveTypes'      => 1,      #  Driver does supports $sth -> {TYPE}
            'GetSerialPreInsert' => \&SeqGetSerial,
            'HasInOperator'  => 0,               # DBMS not support x IN (y)
            },



    ) ;    


###########################################################################################################

sub GetItem

    {
    my ($driver, $name) = @_ ;

    return $Compat{$driver}{$name}  if (exists ($Compat{$driver}{$name})) ;
    return $Compat{'*'}{$name} ; 
    }

1 ;


=head1 NAME

DBIx::Compat - Perl extension for Compatibility Infos about DBD Drivers

=head1 SYNOPSIS

  use DBIx::Compat;

  my $HaveTypes  = DBIx::Compat::GetItem ($drv, 'HaveTypes') ;

=head1 DESCRIPTION

DBIx::Compat contains a hash which gives information about DBD drivers, to allow
to write driver independent programs.

Currently there are the following attributes defined:


=head2 B<ListFields>

A function which will return information about all fields of an table.
Needs an database handle and a tablename as argument.
Must at least return the fieldnames and the fieldtypes.

 Example:
  
  $ListFields = $DBIx::Compat::Compat{$Driver}{ListFields} ;
  $sth = &{$ListFields}($DBHandle, $Table) or die "Cannot list fields" ;
    
  @{ $sth -> {NAME} } ; # array of fieldnames
  @{ $sth -> {TYPE} } ; # array of filedtypes

  $sth -> finish ;



=head2 B<ListTables>

A function which will return an array of all tables of the datasource. Defaults to
C<$dbh> -> C<tables>.

=head2 B<NumericTypes>

Hash which contains one entry for all datatypes that are numeric.

=head2 B<SupportJoin>

Set to true if the DBMS supports joins (select with multiple tables)

=head2 B<SupportSQLJoin>

Set to 1 if the DBMS supports INNER/LEFT/RIGHT JOIN Syntax in SQL select.
Set to 2 if DBMS needs a *= b syntax for inner join (MS-SQL, Sybase).
Set to 3 if DBMS needs a = b (+) syntax for inner join (Oracle syntax).


=head2 B<SQLJoinOnly2Tabs>

Set to true if DBMS can only support two tables in inner joins.

=head2 B<HaveTypes>

Set to true if DBMS supports datatypes (most DBMS will do)

=head2 B<NeedNullInCreate>

Set to C<'NULL'> if DBMS requires the NULL keyword when creating tables
where fields should contains nulls.

=head2 B<EmptyIsNull>

Set to true if an empty string ('') and NULL is the same for the DBMS.

=head2 B<LimitOffset>

An function which will be used to create a SQL text for limiting the
number of fetched rows and selecting the starting row in selects.


=head1 B<Keys that aren't needed anymore>


=head2 B<Placeholders>

Gives information if and how placeholders are supported:

=over 4

=item B<0> = Not supported

=item B<1> = Supported, but not fully, unknown how much

=item B<2> = Supported, but perl type must be the same as type in db

=item B<3> = Supported, but can not give a string when a numeric type is in the db

=item B<10> = Supported under all circumstances

=back


=head2 B<QuoteTypes>

Gives information which datatypes must be quoted when passed literal
(not via a placeholder). Contains a hash with all type number which
need to be quoted.

  $DBIx::Compat::Compat{$Driver}{QuoteTypes}{$Type} 
  
will be true when the type in $Type for the driver $Driver must be
quoted.


=head1 Supported Drivers

Currently there are entry for

=item B<DBD::mSQL>

=item B<DBD::mysql>

=item B<DBD::Pg>

=item B<DBD::Solid>

=item B<DBD::ODBC>

=item B<DBD::CSV>

=item B<DBD::Oracle>

=item B<DBD::Sysbase>

=item B<DBD::Informix>

if you detect an error in the definition or add an definition for a new
DBD driver, please mail it to the author.


=head1 AUTHOR

G.Richter <richter*dev.ecos.de>

=head1 SEE ALSO

perl(1), DBI(3), DBIx::Recordset(3)

=cut
