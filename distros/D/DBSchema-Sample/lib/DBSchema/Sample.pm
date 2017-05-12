package DBSchema::Sample;


use strict;
use warnings;

use DBIx::AnyDBD;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBSchema::Sample ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(load
	
);

our $VERSION = '2.0.a';


# Preloaded methods go here.


# Building Makefile for DBSchame::Sample



# Ignore the following DBD Drivers

my %drivers;

my %ignore = ('ExampleP' => 1,
           'NullP'    => 1,
           'Sponge'   => 1,
           'Proxy'   => 1,
	   'File'     => 1) ;

my %datasource = ('Pg'     => 'dbi:Pg:dbname=test',
               'SQLite' => 'dbi:SQLite:test',
               'mysql'  => 'dbi:mysql:dbname=test',
	       ) ;

## ----------------------------------------------------------------------------

sub MY::test_via_script 
	{
	my ($txt) = shift -> MM::test_via_script (@_) ;

	$txt =~ s/\$\(TEST_FILE\)/\$(TEST_FILE) \$(TESTARGS)/g ;

	return $txt ;
	}
	

## ----------------------------------------------------------------------------

sub GetString
	{
	my ($prompt, $default) = @_ ;

	printf ("%s [%s]", $prompt, $default) ;
	chop ($_ = <STDIN>) ;
	if (!/^\s*$/)
	    {return $_ ;}
	else
    	{
        if ($_ eq "")
	        {return $default ;}
	    else
            { return "" ; }
    
        }
    }

## ----------------------------------------------------------------------------

sub GetYesNo
	{
	my ($prompt, $default) = @_ ;
	my ($value) ;

	do
	    {
	    $value = lc (GetString ($prompt . "(y/n)", ($default?"y":"n"))) ;
	    }
	until (($value cmp "j") == 0 || ($value cmp "y") == 0 || ($value cmp "n" ) == 0) ;

	return ($value cmp "n") != 0 ;
	}

## ----------------------------------------------------------------------------

sub load {

  print "\n";

  my @prereq = qw(DBI DBIx::AnyDBD);

  for my $prereq (@prereq) {

    eval "use $prereq" ;

    die "\nPlease install $prereq before installing DBSchema::Sample" if ($@) ;
    my $v = $prereq->VERSION;
    my $v2 = eval $v;
    print "Found $prereq version $v2\n" ;

  }

  my @drvs = DBI::available_drivers () ;

  my $driversinstalled;

  foreach my $drv (@drvs)
    {
      next if (exists ($ignore{$drv})) ;
    
      $drivers{$drv}{dsn} = $datasource{$drv} || "dbi:$drv:test" ;

      ++$driversinstalled;
    }

  unless ($driversinstalled)
    {
      die 
	"At least one DBD driver must be installed before running load" ;
    }

  print "Found the following DBD drivers:\n" ;

  my @drivers = sort keys %drivers ;
  my $i = 1 ;

  foreach (@drivers)
    {
      print "$i.) $_\n" ;
      $i++ ;
    }

  print "\n" ;
  print "We need an existing datasource for each\n" ;
  print "DBD driver to populate the database.\n" ;
  print "Please enter a valid datasource (or accept the default) for each DBD driver\n" ;
  print "or enter a '.' if you do not want to load the sample schema using this driver\n" ;
  print "\n" ;

  $i = 1 ;
  my ($user, $pass);
  foreach my $drv (@drivers)
    {
      my $dsn = GetString ("$i.) $drv",  $drivers{$drv}{dsn}) ;
      if ($dsn eq '.')
        { delete $drivers{$drv} ; }
      else
        {
	  $drivers{$drv}{dsn} = $dsn ;
	  $user = GetString ("\tUsername", "undef") ;
	  if ($user ne 'undef') 
            {
	      $drivers{$drv}{user} = $user ;        
	      $pass = GetString ("\tPassword", "undef");
	      $drivers{$drv}{pass} = $pass if ($pass ne 'undef') ;        
            }
        }
      $i++ ;
    }

  print "\n" ;
  print "These databases will populated using the following parameters\n" ;

  @drivers = sort keys %drivers ;
  for my $D (@drivers)
    {
      print "$D \t-> $drivers{$D}{dsn}\t" ;
      print "user: $drivers{$D}{user}\t" if (defined ($drivers{$D}{user})) ;
      print "password: $drivers{$D}{pass}"  if (defined ($drivers{$D}{pass})) ;
      print "\n" ;
      
      print "Access this database and populate? ";
      next unless GetYesNo (" > ", "");

      my $app_handle = app_handle($drivers{$D});  

      use Data::Dumper;
      warn Dumper($app_handle);

      my $sql = $app_handle->sql;

      for (@$sql) {
	warn $_;
	$app_handle->get_dbh->do($_); 
      }
    }

}

sub app_handle {

  my $c = shift;

  use Data::Dumper;
  warn Dumper($c);

  my $attr = { RaiseError => 1, PrintError => 1 } ;
  my $class = __PACKAGE__;


  DBIx::AnyDBD->connect
	(
	 $c->{dsn},
	 $c->{user},
	 $c->{pass},
	 $attr,
	 $class # The one difference between DBI and DBIx::AnyDBD
	);

}


__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

DBSchema::Sample - build and populate a realistic sample schema.

=head1 SYNOPSIS

This program builds and populates a small but realistic database.

=head1 USAGE / INSTALLATION

=over 4

=item * Install whatever database you want

Postgres 7.4, MySQL 4.0.14 and SQLite 2.8.6 have been tested

=item * Create a database

 CREATE DATABASE test

For SQLite, this step is not necessary. 

=item * Install DBI

=item * Install appropriate DBD

DBD::SQLite and DBD::mysql have been tested

=item * Install DBSchema::Sample

When it follows the prereqs, it installs L<DBIx::AnyDBD|DBIx::AnyDBD>.

=item * Load the Database

 perl -MDBSchema::Sample -e load

Follow the prompts for DBI connection information
and the tables will be built and populated.

SQLite users: (1) when this command is run, be sure to run it in a directory where
there is no directory named the same as your database and if there is a file
with the name of your database, that file is in fact your database. (2) the default username (undef) is just fine.




=back



=head1 DESCRIPTION

This creates the database schema discussed in "The Practical SQL Handbook 
by Bowman, Emerson and Darnovsky" (Addison-Wesley). 
It is useful to have something like this when you want to
play around with a DBI wrapper (or 12) but don't feel like 
creating a realistic schema and populating it with sensible data.

=head2 EXPORT

 load()

=head1 SCHEMA DESCRIPTON

You can get a PDF of the schema to view here:

L<http://github.com/metaperl/dbschema-sample/blob/e94b148318147f835f27a6a17587f7d87c956fbb/etc/dbschema.pdf>

=head2 authors =1:n=> titleauthors

C<au_id> is a surrogate primary key for the authors table
C<< (au_id, title_id) >> is the primary key for the titleauthors table

=head2 titles  =1:n=> titleauthors

C<title_id> is a surrogate primary key for the titles table.


=head3 Therefore authors =n:n=> titles


=head2 titles  =1:n=> titleditors

=head2 editors =1:n=> titleditors

C<ed_id> is a surrogate primary key for the authors table

=head3 Therefore editors =n:n=> titles

=head2 titles  =1:n=> roysched

At first, I didn't understand how a title could have more
than one royalty, then I realized that a title has
varying royalties based on the total volume sold.

roysched has C<title_id> as a foreign key. And C<title_id> is the primary key in C<titles>.

=head2 publishers =1:n=> titles

C<pub_id> is the surrogate primary key.

=head2 titles     =1:n=> salesdetails

=head2 sales      =1:n=> salesdetails

sales has C<sonum> as a primary key. C<sonum> is a foreign key in salesdetails.

=head3 Therefore titles =n:n=> sales

=head1 AUTHOR

T. M. Brannon, tbone@cpan.org

=head2 SOURCE

L<http://github.com/metaperl/dbschema-sample/tree/master>

=head1 SEE ALSO

L<DBIx::AnyDBD> 
L<DBD::mysql>
L<DBD::SQLite>
L<DBIx::Recordset::Playground>
L<Class::DBI>
L<DBI>

=head2 Other sample databases

=head3 GMAX's


L<https://launchpad.net/test-db/> and L<http://datacharmer.blogspot.com/2008/07/dont-guess-test-sample-database-with.html>


=cut
