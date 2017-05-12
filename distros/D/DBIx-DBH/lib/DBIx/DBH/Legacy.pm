package DBIx::DBH::Legacy;

use strict;
use warnings;



use DBI;
use Params::Validate qw( :all );

our $VERSION = '0.2';

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

# Preloaded methods go here.

Params::Validate::validation_options(allow_extra => 1);

sub connect {

  my @connect_data = connect_data(@_);

  my $dbh;
  eval
    {
      $dbh = DBI->connect( @connect_data );
    };

  die $@ if $@;
  die 'Unable to connect to database' unless $dbh;

  return $dbh;

}

sub dbi_attr {
  my ($h, %p) = @_;

  $h = {} unless defined $h;

  for my $attr (@attr) {
    if (exists $p{$attr}) {
#      warn "$attr = $p{$attr};";
      $h->{$attr} = $p{$attr};
    }
  }

  $h;
}

sub connect_data {

  my $class = shift;
  my %p = @_;

  my $subclass = "DBIx::DBH::$p{driver}";
  eval "require $subclass";
  die "unable to require $subclass to support the $p{driver} driver.\n" if $@;

  my ($dsn, $user, $pass, $attr) = $subclass->connect_data(@_);
  $attr = dbi_attr($attr, %p);

  ($dsn, $user, $pass, $attr)

}

sub form_dsn {

  (connect_data(@_))[0];

}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

 DBIx::DBH::Legacy - legacy helper for DBI connection data (form dsn, etc)

=head1 SYNOPSIS

 use DBIx::DBH::Legacy;

 my %opt = (tty => 1) ;
 my %dat = ( 
     driver => 'Pg',
     dbname => 'db_terry',
     user => 'terry',
     password => 'markso'
 );

 my $dbh = DBIx::DBH::Legacy->connect(%dat, %opt) ; # yes, two hashes, not hrefs!

=head1 ABSTRACT

L<DBIx::DBH::Legacy> is designed to facilitate and validate the process of creating 
L<DBI> database connections.
It's chief and unique contribution to this set of modules on CPAN is that
it forms the DSN string for you, regardless of database driver. Another thing 
about this module is that
it takes a flat Perl hash 
as input, making it ideal for converting HTTP form data 
and or config file information into DBI database handles. It also can form
DSN strings for both major free databases and is subclassed to support
extension for other databases.

DBIx::DBH::Legacy provides rigorous validation on the input parameters via
L<Params::Validate>. It does not
allow parameters which are not defined by the DBI or the database driver
driver into the hash.

It provides support for MySQL, Postgres and Sybase (thanks to Rachel Richard
for the Sybase support).

=head1 Motivation

This module does not appear to be very useful at first. But it has it's place.
Let's see why.

=head2 Simple, robust DSN formation

=head3 Simple

Let's take a look at a L<DBI> connection string:

  DBI->connect("dbi:mysql:database=sakila;host=localhost;post=3306",
       $username, $password);

Now, notice: how the C<dsn> contains a lot of subelements:

=over 4

=item   1. dbi

=item   2. mysql

=item   3. database

=item   4. host

=item   5. port 

=cut

With this module, you simply specify those sub-elements in a hash:

  my %dat = ( 
     driver => 'mysql',
     dbname => 'sakila',
     user => 'username',
     password => 'pass'
  );

This is much more high-level.

So, the first win is that you get to be DWIM instead of DWIS.


=head3 Robust

This module is robust. It uses L<Params::Validate> to make sure that
what you supply is valid.

=head2 Easier interaction with APIs

=head3 Rose::DB::register_db() expects sub-components of a DSN

If you take a look at a call to C<register_db>:

L<http://search.cpan.org/~jsiracusa/Rose-DB-0.758/lib/Rose/DB/Tutorial.pod#Just_one_data_source>

you will notice that it requires the sub-components of the DSN. So, 
ideally you would be able to keep your connection data as a set of
sub-components and supply it to L<Rose::DB> but when you want to connect
directly to L<DBI>, you could do that also.

This module is the solution for this dilemma as well.

=head3 Alzabo and DBIx::AnyDBD have alternative connection syntaxes

Alternative connection syntaxes such as L<DBIx::AnyDBD> or 
L<Alzabo> can make use of the C<connect_data> API call


=head1 API

=head2 $dbh = connect(%params)

C<%params> requires the following as keys:

=over 4

=item * driver : the value matches /\a(mysql|Pg)\Z/ (case-sensitive).

=item * dbname : the value is the name of the database to connect to

=back

C<%params> can have the following optional parameters

=over 4

=item * user

=item * password

=item * host

=item * port

=back

C<%params> can also have parameters specific to a particular database
driver. See
L<DBIx::DBH::Legacy::Sybase>,
L<DBIx::DBH::Legacy::mysql> and L<DBIx::DBH::Legacy::Pg> for additional parameters
acceptable based on database driver.

=head2 ($dsn, $user, $pass, $attr) = connect_data(%params)

C<connect_data> takes the same arguments as C<connect()> but returns
a list of the 4 arguments required by the L<DBI> C<connect()>
function. This is useful for working with modules that have an
alternative connection syntax such as L<DBIx::AnyDBD> or 
L<Alzabo>.

=head2 $dsn = form_dsn(%params)

C<form_dsn> takes the same arguments as C<connect()> but returns
only the properly formatted DSN string. This is also 
useful for working with modules that have an
alternative connection syntax such as L<DBIx::AnyDBD> or 
L<Alzabo>.

=head1 ADDING A DRIVER

Simply add a new driver with a name of C<DBIx::DBH::Legacy::$Driver>, where
C<$Driver> is a valid DBI driver name.

=back

=head1 SEE ALSO

=over

=item * L<Config::DBI>

=item * L<DBIx::Connect>

=item * L<DBIx::Password>

=item * L<Ima::DBI>

=back

=head2 Links

=head3 "Avoiding compound data in software and system design"

L<http://perlmonks.org/?node_id=835894>


=head1 TODO

=over

=item * use a singleton object

The current API for DBIx::DBH::Legacy requires passing in the connection data 
hash to each API function. The data hash should be bound to a singleton
object and all methods should resource it.

A good set of L<Moose> roles inspired by L<MooseX::Role::DBIx::Connector>
or L<DBIx::Roles> might be in order.

=item * use DBIx::Connector

L<DBIx::Connector> is an excellent module for reusing DBI database connections.
This module should optionally connect to DBI via that instead of directly.

=item * expose parm validation info:

 > 
 > It would be nice if the parameter validation info was exposed in some 
 > way, so that an interactive piece of software can ask a user which 
 > driver they want, then query your module for a list of supported 
 > parameters, then ask the user to fill them in. (Perhaps move the hash 
 > of validation parameters to a new method named valid_params, and then 
 > have connect_data call that method and pass the return value to 
 > validate?)

=cut

=head1 AUTHOR

Terrence Brannon, E<lt>bauhaus@metaperl.comE<gt>

Sybase support contributed by Rachel Richard.

Mark Stosberg did all of the following:

=over

=item * contributed Sqlite support

=item * fixed a documentation bug

=item * made DBIx::DBH::Legacy more scaleable

Says Mark: "Just as DBI needs no modifications for a new driver to work,
neither should this module.

I've attached a patch which refactors the code to address this.

Rather than relying on a hardcoded list, it tries to 'require' the
driver, or dies with a related error message.

This could lower your own maintenance effort, as others can publish
additional drivers directly without requiring a new release of
DBIx::DBH::Legacy for it to work."

L<http://rt.cpan.org/Ticket/Display.html?id=18026>

=back



Substantial suggestions by M. Simon Ryan Cavaletto.

=head1 SOURCECODE

L<http://github.com/metaperl/dbix-dbh>

=head1 COPYRIGHT AND LICENSE

Copyright (C) by Terrence Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
