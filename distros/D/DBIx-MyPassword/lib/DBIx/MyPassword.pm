package DBIx::MyPassword;

use warnings;
use strict;
use Carp;
use DBI();
use IO::File;
use Text::CSV;
use File::Spec;

@DBIx::MyPassword::ISA     = qw ( DBI::db );
$DBIx::MyPassword::VERSION = '1.02';

#--> Name of the password file that we are looking for
my $PASSFILE = '.mypassword';   

#--> Name of environment variable that can point to override file 
my $ENV_VAR = 'MYPASSWORD' ;    

#--> Order of data within password file
my @FIELDS = qw(alias user password datasource options) ;    

my %virtual_users;
my $EMPTY = q{};

#-------------------------------------------------------------------------------
#--  import([password file])
#-------------------------------------------------------------------------------
#--  Try to find a file in which to grab password information.  After a file is 
#--  found, parse out the DBI connection information and store it in a hash.
#-------------------------------------------------------------------------------
#--> Pick a file to use to get passwords from.  The order that we are going to 
#--> look for a password file is: 
#-->                   1) import argument
#-->                   2) an environment variable
#-->                   3) the current directory
#-->                   4) the users home directory
sub import {
    my $file = $EMPTY;
    for (
        ( $_[-1] || $EMPTY ),    #--> 'use' override
        $ENV{$ENV_VAR},          #--> environmental override
        $PASSFILE,               #--> current directory
        File::Spec->catpath(
            File::Spec->rootdir(), ( $ENV{HOME} || $EMPTY ), $PASSFILE
        ),                       #--> home directory
      )
    {
        if ( $_ && -e $_ ) {
            $file = $_;
            last;
        }
    }
    croak("Unable to find $PASSFILE file") unless ($file);

    #--> If we are here, we have found a password file.  Assume that it is a CSV
    #--> file and start to parse
    my $csv = Text::CSV->new();
    my $fh  = IO::File->new();
    croak("Unable to open file ($file): $!") unless ( $fh->open("<$file") );
    while (<$fh>) {
        chomp;
        unless ( $csv->parse($_) ) {  #--> Parse the line, just warn if problems
            carp 'Unable to parse: ' . $csv->error_input();
            next;
        }
        next unless ( my @fields = $csv->fields() );

        #--> Add all password elements indexed by the first CSV field
        if ( $fields[0] ) {
            $virtual_users{ $fields[0] }{ $FIELDS[$_] } = $fields[$_] || $EMPTY
              for ( 0 .. $#FIELDS );
        }
    }
    $fh->close();
    return;
}

#-------------------------------------------------------------------------------
#--  connect(virtual user)
#-------------------------------------------------------------------------------
#--  An override of the of the DBI::connect subroutine.  Lookup the virtual user
#-- specified and return a standard DBI connection
#-------------------------------------------------------------------------------
sub connect {    ##no critic
    my ( $class, $user ) = @_;
    return unless ( $virtual_users{$user} );

    my $self = DBI->connect(
        $virtual_users{$user}{datasource}, $virtual_users{$user}{user}
        , $virtual_users{$user}{password}

          #, eval("{$virtual_users{$user}{options}}")
          #, eval {{$virtual_users{$user}{options}}}
        , { $virtual_users{$user}{options} }
    );

    bless $self, $class;
    return $self;
}

#-------------------------------------------------------------------------------
#--  getVirtualUsers()
#-------------------------------------------------------------------------------
#--  Return a list of virtual users.  Presort them to be nice.
#-------------------------------------------------------------------------------
sub getVirtualUsers {
    return sort keys %virtual_users;
}

#-------------------------------------------------------------------------------
#--  checkVirtualUser(virtual user)
#-------------------------------------------------------------------------------
#--  Returns true if the specified virtual user exists, false if not.
#-------------------------------------------------------------------------------
sub checkVirtualUser {
    return defined $virtual_users{ $_[-1] || $EMPTY };
}

#-------------------------------------------------------------------------------
#--  getDataSource(virtual user)
#-------------------------------------------------------------------------------
#--  Return data source information for the specified virtual user.
#-------------------------------------------------------------------------------
sub getDataSource {
    return $virtual_users{ $_[-1] || $EMPTY }{datasource};
}

#-------------------------------------------------------------------------------
#--  getUser(virtual user)
#-------------------------------------------------------------------------------
#--  Return database user for the specified virtual user.
#-------------------------------------------------------------------------------
sub getUser {
    return $virtual_users{ $_[-1] || $EMPTY }{user};
}

#-------------------------------------------------------------------------------
#--  getPassword(virtual user)
#-------------------------------------------------------------------------------
#--  Return password for the specified virtual user.
#-------------------------------------------------------------------------------
sub getPassword {
    return $virtual_users{ $_[-1] || $EMPTY }{password};
}

#-------------------------------------------------------------------------------
#--  getOptions(virtual_user)
#-------------------------------------------------------------------------------
#--  Return options for the specified virtual user.
#-------------------------------------------------------------------------------
sub getOptions {
    return $virtual_users{ $_[-1] || $EMPTY }{options};
}

#-------------------------------------------------------------------------------
#--  DESTROY
#-------------------------------------------------------------------------------
#--  Clean up.
#-------------------------------------------------------------------------------
sub DESTROY {    ##no critic
    my ($self) = @_;
    $self->SUPER::DESTROY;
    return;
}

1;

__END__

=head1 NAME

DBIx::MyPassword - Store database authentication infoin a CSV file

=head1 VERSION

1.02

=head1 SYNOPSIS

  #--> Include the module, letting it search for a password file
  use DBIx::MyPassword;

  #--> Include the module, giving it an explicit file
  use DBIx::MyPassword qw(/password/file.csv);

  #--> Connect to database returning DBI database handle
  my $dbh = DBIx::Password->connect($user);

  #--> Get a list of all available virtual users
  DBIx::MyPassword->getVirtualUsers();

  #--> Check to see if a virtual user exits
  DBIx::MyPassword->checkVirtualUser($user);

  #--> Get the real database user for a virtual user
  DBIx::MyPassword->getUser($user);

  #--> Get the database password for a virtual user
  DBIx::MyPassword->getPassword($user);

  #--> Get the data source information for a virtual user
  DBIx::MyPassword->getDataSource($user);

  #--> Get any database options for a virtual user
  DBIx::MyPassword->getOptions($user);

=head1 DESCRIPTION

This module was largely motivated by DBIx::Password.  It is a different 
take that gives you the ability to keep many different password files.  
This helps on multi-user machines, where each user can have their own 
protected password file and still get the benefits of using aliases.

Keeping all of your password information in one place has many benefits.  
For one, if you have a security policy that forces you to periodically 
change your database password, you only have to make the change in one 
place to change it for all of your scripts.  Also, with all of your 
passwords in one spot, you can make sure that the security on your 
password file is tight.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 Password File Contents

This module assumes that all of your database connection information 
is stored in a standard CSV file.  This file (or files) can have as 
many records as you would like.  The fields found in each record include:

=over

=item 1 Alias 

The only non-connection field, this is the alias that you will use to 
reference the connection information

=item 2 User 

The database user

=item 3 Password

The password for the database user

=item 5 Data Source

A DBI data source, for instance "dbi:mysql:test"

=item 6 Options

DBI options that will be eval'ed into a hash, for instance 
"RaiseError=>1,PrintError=>1"

=back

=head2 Specifying The Password File Location

Currently, there are four places that this module searches for your password 
file.  The order of the search is:

=over

=item 1 Explicit File Via use

File specified in when 'use'ing the module

=item 2 Explicit File Via Environment 

File specified by the MYPASSWORD environment variable 

=item 3 Current Working Directory

A file named '.mypassword' in the current working directory

=item 4 Home Directory

A file named '.mypassword' in the users home directory, as specified 
by the HOME environment variable

=back

=head2 Securing The Password File

One of the primary reasons that this module was developed was so that I 
could secure my password information in a shared environment.  Here is 
how I do it.  If you see holes in this, please let me know.  Also, I do 
most of my development on some flavor of UNIX, Linux, AIX, etc.  These 
systems are what I know best.  If there is a better (or just plain 
different) way to do security on another system, let me know and I'll 
include it here.

For *X, all that you have to do is change the permissions on your 
password file so that you are the only person who can read it.  A simple:

	chmod 400 .mypassword

is all that it takes.  Each user can have their own password file that 
only they can read.  The caveat of this is that only scripts executed 
by you can read the file too... not sure how that fairs for web 
development.

=head1 SUBROUTINES/METHODS

=head2 connect(virtual_user)

An override of the of the DBI::connect subroutine.  This method looks up 
the specified virtual user and returns a standard DBI connection.

=head2 getVirtualUsers()

Return a sorted list of virtual users.

=head2 checkVirtualUser(virtual_user)

Returns true if the specified virtual user exists, false if not.

=head2 getUser(virtual_user)

Return database user for the specified virtual user.

=head2 getPassword(virtual_user)

Return password for the specified virtual user.

=head2 getDataSource(virtual_user)

Return data source information for the specified virtual user.

=head2 getOptions(virtual_user)

Return options for the specified virtual user.

=head1 INSTALL

Just a standard module install will get the job done.  If you would like, 
you can set the environment variables MP_DBUSER, MP_DBPASS, MP_DBDS, and 
MP_DBOPTS to allow the test scripts to connect to a real database.

	MP_DBUSER -> A real database user name
	MP_DBPASS -> The database user's password
	MP_DBDS   -> A DBI data source, for instance "dbi:mysql:test"
	MP_DBOPTS -> Any DBI connection options, for instance 
                   "RaiseError => 1, PrintError => 1"

Environment variables are not, these are the commands to install:

	perl Makefile.PL
	make
	make test
	make install

=head1 DEPENDENCIES

L<warnings>, L<strict>, L<Carp>, L<DBI>, L<IO::File>, L<Text::CSV>, 
L<File::Spec>

=head1 DIAGNOSTICS

=head1 INCOMPATIBILITIES

Let me know

=head1 BUGS AND LIMITATIONS

Let me know

=head1 LICENSE AND COPYRIGHT

This software is licensed under the Artistic or GPL v2 license... a.k.a. 
the same license as Perl itself.

=head1 AUTHOR

Josh McAdams, joshua.mcadams at gmail dot com

=head1 SEE ALSO

perl(1); DBI(3); DBIx::Password(3);

=cut
