package Class::DBI::AutoLoader;

use strict;
use warnings;
use DBI;

our $VERSION = '0.12';

sub import {
	my $self = shift;
	my $args = { @_ };
	
	# Fetch the driver
	my ($driver) = $args->{dsn} =~ m|^dbi:(.*?):.*$|;

	# Get the tables
	my @tables = ();
	if(defined $args->{tables}) {
		@tables = @{ $args->{tables} };
	}
	else {
		my $dbh = DBI->connect($args->{dsn},$args->{username},$args->{password})
			or die "Couldn't establish connection to database via $args->{dsn}: $DBI::errstr";
		@tables = $dbh->tables();
		$dbh->disconnect;
	}
	
	# Generate the classes
	foreach my $table (@tables) {
		generateClass($table,$driver,$args);
	}
}

sub table2class {
	my ($table) = @_;
	
	$table = ucfirst($table);
	$table = join('', map { ucfirst($_) } split(/[^a-zA-Z0-9]/, $table));
	
	return $table;
}

sub generateClass {
	my($table,$driver,$args) = @_;
	my $package = $args->{namespace} . '::' . table2class($table);
	
	my $class = "package $package;"
	          . "use strict;"
	          . "use vars '\@ISA';";

	# Determine the base class
	if(defined $args->{use_base}) {
		$class .= "use base '$args->{use_base}';";
	}
	else {
		$class .= "use base 'Class::DBI::BaseDSN';";
	}

	# Add any additional requested packages
	foreach my $add_pkg (@{ $args->{additional_packages} }) {
		$class .= "use $add_pkg;";
	}

	# Finish it off
	$class .= '1;';
	eval($class);
	if(my $error = $@) {
		warn "An error occurred generating $package: $error";
	}

	# Setup the rest of the good stuff
	$package->set_db('Main' => $args->{dsn}, $args->{username}, $args->{password}, $args->{options});
	$package->set_up_table($table);
}

1;

=head1 NAME

Class::DBI::AutoLoader - Generates Class::DBI subclasses dynamically.

=head1 SYNOPSIS

  use Class::DBI::AutoLoader (
  	dsn       => 'dbi:mysql:database',
  	username  => 'username',
  	password  => 'passw0rd',
  	options   => { RaiseError => 1 },
	tables    => ['favorite_films','directors']
  	namespace => 'Films'
  );
  
  my $film = Films::FavoriteFilms->retrieve(1);
  my $dir  = Films::Directors( film => $film->id() );

=head1 DESCRIPTION

Class::DBI::AutoLoader scans the tables in a given database,
and auto-generates the Class::DBI classes. These are loaded into
your package when you import Class::DBI::AutoLoader, as though
you had created the Data::FavoriteFilms class and "use"d that
directly.

=head1 NOTE

Class::DBI::AutoLoader messes with your table names to make them
look more like regular class names. Specifically it turns table_name
into TableName. The actual function is just:

 $table = join('', map { ucfirst($_) } split(/[^a-zA-Z0-9]/, $table));

=head1 WARNING

I haven't tested this with any database but MySQL. Let me know if you 
use it with PostgreSQL or SQLite. Success or failure.

=head1 OPTIONS

Options that can be used in the import:

=over 4

=item * dsn

The standard DBI style DSN that you always pass.

=item * username

The username for the database.

=item * password

The password for the database.

=item * options

A hashref of options such as you'd pass to the DBI->connect() method.
This can contain any option that is valid for your database.

=item * tables

An array reference of table names to load. If you leave this option
out, all tables in the database will be loaded.

=item * namespace

The master namespace you would like your packages declared in. See the
example above.

=item * use_base

If you don't specify a base class, then L<Class::DBI::BaseDSN> will be used.
This module does explicitly use the method 'set_up_table' from the 
L<Class::DBI::mysql>, L<Class::DBI::Pg>, and L<Class::DBI::SQLite>
series of modules. Unless you have a module that supports, or subclasses, these
than you won't want to use this.

=item * additional_packages

An array reference of additional packages you would like each class to "use".
For example:

 use Class::DBI::AutoLoader (
 	...
 	additional_packages => ['Class::DBI::AbstractSearch']
 );

This allows you to use Class::DBI plugins or other assorted goodies in the
generated class.

=back

=head1 SUPPORTED DATABASES

Currently this module supports MySQL, PostgreSQL, and SQLite via
L<Class::DBI::mysql>, L<Class::DBI::Pg>, and L<Class::DBI::SQLite>.

=head1 TIPS AND TRICKS

=head2 USE ADDITIONAL_PACKAGES

Class::DBI::AbstractSearch is extremely useful for doing any kind of complex
query. Use it like this:

 use Class::DBI::AutoLoader (
 	...
 	additional_packages => ['Class::DBI::AbstractSearch']
 );
 
 my @records = MyDBI::Table->search_where( fname => ['me','you','another'] );

Please see L<Class::DBI::AbstractSearch> for full details

=head2 USE IN MOD_PERL

Put your use Class::DBI::AutoLoader(...) call in your startup.pl file. Then
all your mod_perl packages can use the generated classes directly.

=head2 USE IN CGIs

If you don't use the C<tables> option and you don't need all of the tables
in the database, you're going to take an unneccessary penalty.

=head2 WRAP IT IN A SUBCLASS

You probably want to wrap this in a subclass so you don't have to go through
all of the dsn, user, blah blah everytime you use it. Additionally, you can
put any __PACKAGE__->set_sql(...) type stuff in your subclass. That's helpful
since you can't edit the generated classes.

=head2 USING A SUBCLASS FOR CGIs

 package My::DBI::ForCGI;
 
 sub import {
     my ($self,@tables) = @_;
     require Class::DBI::AutoLoader;
     Class::DBI::AutoLoader->import(
         dsn => 'dbi:mysql:application',
		 username => 'joe',
		 password => 'friday',
		 options => { RaiseError => 1 },
		 tables => \@tables,
		 namespace => 'My::DBI::ForCGI'
     );
 }
 1;

Then in your CGI:

 use strict;
 use CGI;
 use My::DBI::ForCGI ( tables => 'users' );

 my $cgi = CGI->new();
 my $user = My::DBI::ForCGI::Users->retrieve( $cgi->param('user_id') );
 ...

Since your classes are scanned and generated, you will always take some
performance hit, especially when used in non-persistant environments like
a CGI application. Use C<tables> liberally.
 
=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::mysql>, L<Class::DBI::Pg>, L<Class::DBI::SQLite>

=head1 AUTHOR

Ryan Parr, E<lt>ryanparr@thejamescompany.comE<gt>

This software is based off the original work performed by
Ikebe Tomohiro on the Class::DBI::Loader module.

=head1 THANKS

To Casey West for helping to hash-out what makes this module useful.
To Mike Castle for submitting the first patch :)

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
