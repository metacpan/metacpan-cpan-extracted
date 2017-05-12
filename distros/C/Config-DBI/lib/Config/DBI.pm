package Config::DBI;

use Config::ApacheFormat;
use Data::Dumper;
use DBI;
use Term::ReadKey;

use diagnostics;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Config::DBI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = sprintf '%s', q$Revision: 1.8 $ =~ /Revision:\s+(\S+)\s+/ ;


my $stdin = '<STDIN>';

our @attr = qw
  (  
   dbi_connect_method
   Warn

   _Active
   _Executed
   _Kids
   _ActiveKids
   _CachedKids
   _CompatMode

   InactiveDestroy
   PrintWarn
   PrintError
   RaiseError
   HandleError
   HandleSetErr

   _ErrCount

   ShowErrorStatement
   TraceLevel
   FetchHashKeyName
   ChopBlanks
   LongReadLen
   LongTruncOk
   TaintIn
   TaintOut
   Taint
   Profile
   _should-add-support-for-private_your_module_name_*


   AutoCommit

   _Driver
   _Name
   _Statement

   RowCacheSize

   _Username
  );

our @valid_directives = ( qw(User Pass DSN), @attr ) ;


# Preloaded methods go here.

sub new {

  my $envar = 'DBI_CONF';
  $ENV{$envar} or die "$envar not set";

  my $c = Config::ApacheFormat->new
    (
     valid_directives => \@valid_directives
    );
  $c->autoload_support(1);
  $c->read($ENV{DBI_CONF});
  $c;

}

sub error_handler {

  my ($errstring, $dbh, $retval) = @_;

  warn "e: $errstring d: $dbh r: $retval";

}

sub dummy_error_handler {

  my ($errstring, $dbh, $retval) = @_;

  warn "d_e_h -> e: $errstring d: $dbh r: $retval";

}

sub hash {
  my $self  = shift;
  my $label = shift;
  my $c = __PACKAGE__->new;

  my $block = $c->block(DBI => $label);

  my %A = map {
    defined($block->get($_)) ? ( $_ => $block->get($_) ) : ()
  } @attr;
  
  if (my $handler = $block->HandleError)
    {
      my $hardref = eval "\\&$handler" ;
      $A{HandleError} = $hardref;
    }


  my @req = qw( DSN);
  for my $req (@req) 
    {
      unless ($block->$req()) {
	die "$req must be defined" 
      }
    }


  my $Pass;

  if ($block->Pass eq $stdin) 
      {

	# Prevents input from being echoed to screen
	ReadMode 2; 
	print "Enter Password for $label (will not be echoed to screen): ";
	$Pass = <STDIN>;
	if ($Pass) {
	  chomp($Pass) 
	}# else {
	 # undef $Pass
	 #}

	print "\n";
	# Allows input to be directed to the screen again
	ReadMode 0;
      }
    else
      {
	$Pass = $block->Pass
      }

  my %R = 
    (
     User => $block->User,
     Pass => $Pass,
     DSN  => $block->DSN,
     Attr => \%A
    );

}

use vars qw($AUTOLOAD);

sub AUTOLOAD {

  my $self = shift;

  my ($label) = ($AUTOLOAD =~ /([^:]+)$/) ;

  my %c = Config::DBI->hash($label);
  
  DBI->connect($c{DSN}, $c{User}, $c{Pass}, $c{Attr})
    or die $DBI::errstr;

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

  Config::DBI - database connection support via Config::ApacheFormat files

=head1 SYNOPSIS

In .cshrc:

  setenv DBI_CONF dbi.conf

In dbi.conf:

 # Pass may be a password, or <STDIN> in which case, the password is 
 # is prompted for:

 Pass	     <STDIN>

 # Connect attribute

 # dbi_connect_method is a standard part of DBI. Its casing does differ from
 # all other attributes, but I did not create the DBI spec, I am simply
 # following it:
 # http://search.cpan.org/~timb/DBI-1.38/DBI.pm#DBI_Class_Methods

 # Other options for this value are: connect_cached, Apache::DBI::connect

 dbi_connect_method connect

 # Attributes common to all handles and settable
 # Listed in the order given in the DBI docs.
 # http://search.cpan.org/~timb/DBI/DBI.pm#METHODS_COMMON_TO_ALL_HANDLES

 Warn 1 
 InactiveDestroy
 PrintError 0 
 PrintWarn 1
 RaiseError 0 
 HandleError  Exception::Class::DBI->handler
 HandleSetErr sub { my ($handle, $err, $errstr, $state, $method) = @_; }
 ShowErrorStatement 1
 TraceLevel 0
 FetchHashKeyName NAME_lc
 ChopBlanks 0
 LongReadLen 0
 LongTruncOk 0
 TaintIn 1 
 TaintOut 0
 # omit Taint (shortcut to set both TaintIn and TaintOut)
 Profile 0
 
 # Attributes for database handles
 # http://search.cpan.org/~timb/DBI/DBI.pm#Database_Handle_Attributes 
 
 AutoCommit 0
 RowCacheSize 0
 
 # Connection info

 # Description of a database we would like to connect to

 <DBI basic>
  DSN              dbi:Pg:dbname=mydb
  User             postgres
  AutoCommit  1
 </DBI>

 # Description of another database

 <DBI basic_test>
  DSN   dbi:Pg:dbname=mydb_test
  User  test
  Pass  test
 </DBI>

In Ye Olde Pure Perl Programme:

  use Config::DBI;

  my $dbh = Config::DBI->basic_test;

Or:

  my %connect = Config::DBI->hash('basic_test');

=head1 DESCRIPTION

Config::DBI is a module based on 2 years of developing and using
DBIx::Connect. For most usage, DBIx::Connect was fine. However two principal
issues began to loom with continued usage. First, AppConfig is very hard
to use and understand. So maintenance of the code was a real headache. Second,
it was difficult to arrange an AppConfig file to create over-writable
defaults. The concerns led to the following post:

    http://perlmonks.org/index.pl?node_id=299749

A reply by Perrin led me to develop a completely new module based on
Config::ApacheFormat.

This module's main purpose is to provide a way to get DBI database handles
with very few lines of code. It does also have an API call to get the
connection data so that you can do what you want with it. This is useful
when one is using DBIx::AnyDBD, Alzabo or some other package which has 
different conventions for creating DBI C<dbh>s.


=head1 INSTALLATION and USAGE

=head2 Create a DBI configuration file

A documented sample one, C<dbi.conf>, comes with the distribution.

No directives are allowed in this file other than 
C<User>, C<Pass>, C<DSN>, C<DBI> and the names of the DBI attributes.

=head2 Create the DBI_CONF environmental variable in your .bashrc

Set this to the name of the configuration file that Config::DBI will be using.

  export DBI_CONF=$HOME/dbi.conf

=head2 Source .bashrc

  shell> source ~/.bashrc

=head2 Run scripts/try-connect.pl try it out:

    ~/hacks/config-dbi/scripts $ perl -I../lib try-connect.pl
 Connection successful.
    ~/hacks/config-dbi/scripts $ 

=head2 Install it

 perl Makefile.PL
 make
 make test
 make install



=head1 METHODS

=head2 my $dbh = Config::DBI->$DBI_block

This method looks for a DBI block labeled C<$DBI_block> and loads in the 
configuration information from that block as well as its parents. It then
creates and returns a DBI database handle.

Should an error occur and C<HandleError> is unbound, then
C<$DBI::errstr> is printed with a die. If C<HandleError> is defined, then
its called per the DBI spec.

=head2 my %hash = Config::DBI->hash($DBI_block);

This method returns a hash of DBI connection data. Here is a sample of
what such data would look like from the config file in the L</SYNOPSIS>.

  $VAR1 = {
          'DSN' => 'dbi:Pg:dbname=mydb',
          'User' => 'postgres',
          'Pass' => undef,
          'Attr' => {
                      'Profile' => '0',
                      'FetchHashKeyName' => '0',
                      'TraceLevel' => '0',
                      'HandleError' => sub { "DUMMY" },
                      'InactiveDestroy' => 1,
                      'AutoCommit' => '1',
                      'TaintOut' => '0',
                      'RaiseError' => '0',
                      'LongTruncOk' => '0',
                      'ChopBlanks' => '0',
                      'PrintError' => '0',
                      'dbi_connect_method' => 'connect',
                      'LongReadLen' => '0',
                      'Warn' => '1',
                      'ShowErrorStatement' => '1',
                      'TaintIn' => '1'
                    }
        };


=head2 EXPORT

None by default.

=head1 SEE ALSO

Most of the information for this section is a regurgitation of:

    http://perlmonks.org/index.pl?node_id=292455

=head2 DBIx::Password

The very first module to abstract the process of DBI database connections.
Repeated rejection of my patches to this module to support methods such as
the C<hash()> method of this package led to the creation of DBIx::Connect.

=head2 XML::Object::DBI

This module does connection and SQL warehousing via XML.

=head2 Ima::DBI

Ima:DBI is part of the tech stack Perl's most popular Perl database wrapper,
Class::DBI. It does connection and SQL warehousing via Perl.

=head2 DBIx::Connect

The first module I wrote to address what I could not address under the
auspices of DBIx::Password. 


=head1 AUTHOR

Terrence Brannon, E<lt>tbone@cpan.orgE<gt>

Thanks for Perrin Harkins for mentioning Config::ApacheFormat

Thanks for Sam Tregar for writing Config::ApacheFormat.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Terrence Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

Many thanks for Dan Kubb for his input on this module and also for
alerting me to new attributes as of DBI 1.45.

=cut
