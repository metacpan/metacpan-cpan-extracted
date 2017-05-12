package SomeDB;

use lib qw(lib ../lib);
use strict;
use DBIx::LazyMethod;
use vars qw(@ISA);
@ISA = qw(DBIx::LazyMethod);

sub new {
	my $class = shift;
        my %methods = (
               create_people_table => {
                       sql => "CREATE TABLE people (id int NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255), alias INT, unique uix_alias (alias))",
                       args => [ qw() ],
                       ret => WANT_RETURN_VALUE,
               },
               drop_people_table => {
                       sql => "DROP TABLE IF EXISTS people",
                       args => [ qw() ],
                       ret => WANT_RETURN_VALUE,
               },
               create_people_entry => {
                       sql => "INSERT INTO people (name,alias) VALUES (?,?)",
                       args => [ qw(name alias) ],
                       ret => WANT_RETURN_VALUE,
               },
               create_people_entry_autoincrement => {
                       sql => "INSERT INTO people (name,alias) VALUES (?,?)",
                       args => [ qw(name alias) ],
                       ret => WANT_AUTO_INCREMENT,
               },
               set_people_name_by_alias => {
                       sql => "UPDATE people SET name = ? WHERE alias = ?",
                       args => [ qw(name alias) ],
                       ret => WANT_RETURN_VALUE,
               },
               get_people_alias_by_name => {
                       sql => "SELECT alias FROM people WHERE name = ?",
                       args => [ qw(name) ],
                       ret => WANT_ARRAY,
               },
               get_people_entry_by_alias => {
                       sql => "SELECT * FROM people WHERE alias = ?",
                       args => [ qw(alias) ],
                       ret => WANT_HASHREF,
               },
               get_all_people_entries => {
                       sql => "SELECT * FROM people",
                       args => [ qw() ],
                       ret => WANT_ARRAY_HASHREF,
               },
               get_people_count => {
                       sql => "SELECT COUNT(*) FROM people",
                       args => [ qw() ],
                       ret => WANT_ARRAY,
               },
               delete_people_entry_by_alias => {
                       sql => "DELETE FROM people WHERE alias = ?",
                       args => [ qw(alias) ],
                       ret => WANT_RETURN_VALUE,
               },
        );

        my $db = DBIx::LazyMethod->new(
		data_source => "DBI:mysql:test:localhost",
		user => 'root',
		pass => '',
		attr => { 'RaiseError' => 0, 'AutoCommit' => 1 },
		methods => \%methods,
		);

 		if ($db->is_error) { die $db->{errormessage}; }
	return $db;
}

1;

__END__                                 
        
=head1 NAME
                
SomeDB.pm - DBIx::LazyMethod inheritance example
                
=head1 SYNOPSIS
       
	You are looking at it. 

	Please look at the DBIx::LazyMethod documentation for an in-depth explanation.
=cut 

=head1 CLASS METHODS

=over 2

=item C<new()>

The C<new()> constructor creates and returns a DBIx::LazyMethod object.
Methods defined in this constructor will now be available via the SomeDB object.

=cut

=back
