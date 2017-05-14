#=============================== ldconfig.pm =================================
# Filename:		ldconfig.pm
# Description:	        Load configuration variables from database.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:			$Date: 2008-08-28 23:14:03 $
# Version:		$Revision: 1.8 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
# Independance guarantee: No function placed in here calls any other *local* 
# modules and thus will be unaffected by changes in abstraction layer API's.
#
#=============================================================================
use strict;

package DMA::ldconfig;
use Exporter ();
use vars qw{@ISA},qw{@EXPORT};
@ISA    = qw (Exporter);
@EXPORT = qw(load_local_configuration
	     );
use DBI;

#=============================================================================
#			Exported Routines
#=============================================================================

sub load_local_configuration {
  my ($db,$usr,$pass) = @_;
  defined $db   || (return 0);
  defined $usr  || (return 0);
  defined $pass || (return 0);

  my ($dbh,$sth,@row,$expr);

  ($dbh = DBI->connect ("DBI:mysql:${db}", $usr, $pass)) || (return 0);
  ($sth = $dbh->prepare ("SELECT * FROM configuration")) || (return 0);
  ($sth->execute())                                      || (return 0);

  while (@row = $sth->fetchrow_array) {
    $expr = '$::CFG_' . $row[0] . ' = "' . $row[1] . '";';
    eval $expr;
  }

  $sth->finish;
  $dbh->disconnect;
  return 1;
}

#==============================================================================
#                       Pod Documentation
#==============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 DMA::ldconfig - Load configuration variables from database.

=head1 SYNOPSIS

 use DMA::ldconfig
 $t = load_local_configuration ($db, $usr, $pass); 

=head1 Inheritance

 None.

=head1 Description

Most programs have a need for configuration and this lets you keep all of 
your configuration data in a MySQL database. To use it there must be a 
configuration Table defined this way:

 CREATE TABLE configuration (
              Name   VARCHAR(100)  NOT NULL, 
              Value  VARCHAR(100)  NOT NULL, 
 PRIMARY KEY  (Name));

If you are setting this up for the first time, you might do something like 
the following. First make sure the user of this database has a password set.
You can set it:

 mysqladmin -u cfguser --password= password foobaz

or change it:

 mysqladmin -u cfguser --password=foobaz password newbar

Then create the database and load your definition file

  mysqladmin -u cfguser --password=newbar create mydatabase
  mysql -u cfguser --password=newbar < base.mysql

Where 'base.mysql' (or whatever) contains the lines needed to set up the 
database:

 use mydatabase;
 CREATE TABLE configuration (
              Name   VARCHAR(100)  NOT NULL, 
              Value  VARCHAR(100)  NOT NULL, 
 PRIMARY KEY  (Name));
 INSERT INTO configuration VALUES ("MYVAR",    "True");
 INSERT INTO configuration VALUES ("MYNUMVAR", "5");

Note that DMA::ldconfig imports its single function into your name space. 
You should run it in the MAIN namespace so all of your configuration variable
are imported into that namespace for easy global usage. To avoid the 
possibility of namespace collision you should not use a prefix of '$::CFG_' 
on any of  your variables.

After running load_local_configuration ("mydbname", "cfguser", "newbar") with
the above example, your main namespace would contain the scalar variable Names
$::CFG_MYVAR and $::CFG_MYNUMVAR initialized to the Values shown in the table
example. By re-running this routine you can dynamically update your default 
values, a feature which is both useful and potentially perilous.

If it is not obvious, to use this class you must have a MySQL database server
running and accepting localhost connections. 

Since the class is based on the Perl DBI class, it would be very easy to 
change to a different database.

Note that MySQL requires a license for commercial use. The licenses are quite
inexpensive.

=head1 Examples

 use DMA::ldconfig
 $t = load_local_configuration ("mydbname", "cfguser", "newbar");
 if ($::CFG_MYVAR eq "True") {print "Yep, we got it!");

=head1 Variables

 None.

=head1 Functions

=over 4

=item B<$t = load_local_configuration ($db, $usr, $pass)>

Load the contents of a configuration table taken from local MySQL database 
$db.  Connect to it as user $usr with password $pass. For every Name and 
Value pair in the table's records, generate $::CFG_thisname = $thisvalue. 
Return true if it this succeeds.

=back 4

=head1 Private Functions

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

DBI

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: ldconfig.pm,v $
# Revision 1.8  2008-08-28 23:14:03  amon
# perldoc section regularization.
#
# Revision 1.7  2008-08-15 21:47:52  amon
# Misc documentation and format changes.
#
# Revision 1.6  2008-04-18 14:07:54  amon
# Minor documentation format changes
#
# Revision 1.5  2008-04-11 22:25:23  amon
# Add blank line after cut.
#
# Revision 1.4  2008-04-11 18:56:35  amon
# Fixed quoting problem with formfeeds.
#
# Revision 1.3  2008-04-11 18:39:15  amon
# Implimented new standard for headers and trailers.
#
# Revision 1.2  2008-04-10 15:01:08  amon
# Added license to headers, removed claim that the documentation section still
# relates to the old doc file.
#
# 20041105	Dale Amon <amon@vnl.com>
#		Generalized, added error checking
#		and documentation.
#
# 20000120	Dale Amon <amon@vnl.com>
#		Created.
1;
