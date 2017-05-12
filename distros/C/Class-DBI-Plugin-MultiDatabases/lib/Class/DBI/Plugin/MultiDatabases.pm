package Class::DBI::Plugin::MultiDatabases;

use strict;
use Carp;
use base qw(Class::Data::Inheritable);
use vars qw($VERSION);

$VERSION = 0.1;

##############################################################################

sub import {
	my $me    = shift;
	my $class = (caller)[0];

	unless( UNIVERSAL::isa($class, 'Class::DBI') ){
		croak __PACKAGE__, " can be used only by Class::DBI and its subclass.";
	}

	no strict 'refs';
	for my $sym (qw/change_db change_db set_connections db_Main
	        save_db_Main clear_db_Main is_imported_class effected_classes/){
		*{"$class\::$sym"} = \&{ $sym };
	}

	$me->is_imported_class($class);

	$class->mk_classdata('current_dbh');
	$class->mk_classdata('_dbnames');
	$class->mk_classdata('_clear_object');
	$class->mk_classdata('_DSNs');
	$class->mk_classdata('_targetClasses');

	$class->_dbnames( {} );
	$class->_DSNs( {} ); # Data Source Name
	$class->_targetClasses( {} );

	if( $class->can('clear_object_index') ){
		$class->_clear_object(1);
	}

}

##############################################################################

{ # sub is_imported_class
	my $class;
	sub is_imported_class {
		my $self = shift;

		if($class){ return $class eq $self; }

		$class = shift; # only once
	}
}

##############################################################################

# See Also http://wiki.class-dbi.com/index.cgi?UsingMultipleDatabases

sub set_connections {
	my $class = shift;
	my %keys  = @_;
	$class->_DSNs(\%keys);
}


sub change_db {
	my ($class, $dsn_key) = @_;

	unless( $class->is_imported_class ){
		croak "change_db() must be called by the imported class.";
	}

	if($class->_dbnames->{$dsn_key}){

		# $class may not be contained in _targetClasses
		$class->current_dbh($dsn_key); 

		for my $subclass ( $class->effected_classes ){
			$subclass->current_dbh($dsn_key);
		}

	}
	else{
		$class->_dbnames->{$dsn_key} = 1;
		$class->current_dbh($dsn_key);

		unless( $class->_DSNs->{$dsn_key} ){
			return undef;
		}

		my @args = @{ $class->_DSNs->{$dsn_key} };
		Ima::DBI->set_db($dsn_key, @args);
	}

	for my $subclass ( $class->effected_classes ){
		$subclass->clear_object_index() if($class->_clear_object());
	}

	return $dsn_key;
}


sub db_Main {
	my $proto  = shift;
	my $method = 'db_' . $proto->current_dbh();

	if(ref($proto) and $proto->{__db_Main}){
		return $proto->{__db_Main};
	}

	if(!ref($proto)){
		$proto->_targetClasses->{$proto} = 1;
	}

	$proto->$method;
}


sub save_db_Main {
	my $proto  = shift;

	unless(ref($proto)){
		die "save_db_Main() can't be used as a clsas method.";
	}

	my $method = "db_" . $proto->current_dbh();

	$proto->{__db_Main} = $proto->$method;
}


sub clear_db_Main {
	my $proto  = shift;

	unless(ref($proto)){
		die "save_db_Main() can't be used as a clsas method.";
	}

	my $saved = $proto->{__db_Main};

	$proto->{__db_Main} = undef;

	return $saved;
}


sub effected_classes {
	my $class = shift;
	my @classes;

	for my $target ( keys %{ $class->_targetClasses } ){
		push @classes, $target;
	}

	return @classes;
}


##############################################################################
1;
__END__

=pod

=head1 NAME

Class::DBI::Plugin::MultiDatabases - use multiple databases from a snigle class


=head1 SYNOPSIS

 package Your::App::DBI;
 
 use base qw(Class::DBI);
 use Class::DBI::Plugin::MultiDatabases;
 
 Your::App::DBI->set_connections({
 	databaseA => ["dbi:SQLite:dbname=databaseA", '', ''],
 	databaseB => ["dbi:SQLite:dbname=databaseB", '', ''],
 });
 
 
 package Your::App::CD;
 
 Your::App::CD->table('cds');
 Your::App::CD->column(All => qw/cdid title artist/);
 
 
 package main_script;
 
 my $cd;

 Your::App::DBI->change_db('databaseA');
 
 $cd = Your::App::CD->retrieve(123);
 print $cd->title, "\n"; # from databaseA
 
 # ....
 
 Your::App::DBI->change_db('databaseB');
 
 $cd = Your::App::CD->retrieve(123);
 print $cd->title, "\n"; # from databaseB
 
 
 $cd->save_db_Main(); # this object saves 'databaseB'
 
 Your::App::DBI->change_db('databaseA');
 
 my @cds = Your::App::CD->retrieve_all();

 print $cd->title, "\n"; # from databaseB still

 for(@cds){
   #  objects are from databaseA
 }

=head1 DESCRIPTION

"There are cases when you have the same schema in multiple databases
and would like to access two or more databases from the same script
without reconnecting every time."

from http://wiki.class-dbi.com/index.cgi?UsingMultipleDatabases

This module helps you for it automatically.

All that you must do is C<use Class::DBI::Plugin::MultiDatabases>
in your base CDBI application class.

=head1 METHODS

=over 4

=item set_connections($key => $arrayref [,$other_key => $other_arrayref])

takes key/arrayref pair. $arrayref is a DSN, username, password and options.

 set_connections(
   db1 => ["dbi:Pg:dbname=pgdb", $user, $pass, $opts],
   db2 => ["dbi:SQLite:dbname=sqlitedb", '', ''],
 )


=item change_db($key)

You give a database key which you have set with C<set_connections>.

=item save_db_Main()

This method is object method. When C<change_db> is called, all existing objects
return new database handle from C<db_Main()>. If you called C<save_db_Main>
before calling C<change_db>, the object return unchanged dbh.

=item clear_db_Main()

This method is object method which erases C<save_db_Main>'s effect.

=back

=head1 BUGS

Maybe, there are a lot of bugs.

=head1 SEE ALSO

L<http://wiki.class-dbi.com/index.cgi?UsingMultipleDatabases>

L<Class::DBI>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
