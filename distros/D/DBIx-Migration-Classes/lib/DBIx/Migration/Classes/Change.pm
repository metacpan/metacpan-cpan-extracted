package DBIx::Migration::Classes::Change;

use 5.008009;
use strict;
use warnings;

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->_init(@args);
}

sub _init
{
	my ($self, %opts) = @_;
	$self->{'changes'} = [];
	$self->{'undo-changes'} = [];
	return $self;
}

sub after
{
	# to be overwritten
	return "";
}

sub perform
{
	# to be overwritten
	return 1;
}

sub get_changes
{
	my ($self, $undo) = @_;
	return ($undo ? reverse @{$self->{'undo-changes'}} : @{$self->{'changes'}});
}

sub create_table
{
	my ($self, $tablename) = @_;
	push @{$self->{'changes'}},      ['create_table', name => $tablename];
	push @{$self->{'undo-changes'}}, ['drop_table',   name => $tablename];
	return 1;
}

sub alter_table_add_column
{
	my ($self, $tablename, $colname, $type, %opts) = @_;
	push @{$self->{'changes'}},
		['alter_table_add_column', tablename => $tablename, name => $colname, type => $type, %opts];
	push @{$self->{'undo-changes'}},
		['alter_table_drop_column', tablename => $tablename, name => $colname];
	return 1;
}

1;
__END__

=head1 NAME

DBIx::Migration::Classes::Change - Base class for database changes

=head1 SYNOPSIS

To create a new migration, just create a new child class:

I<libpath>/MyApp/Changes/MyChangeTwo.pm:

  package MyApp::Changes::MyChangeTwo;
  use base qw(DBIx::Migration::Classes::Change);

  sub after { "MyApp::Changes::MyChangeOne" }
  sub perform {
    my ($self) = @_;
    $self->add_column('tablename', 'new_column', 'varchar(42)', -null => 1, -primary_key => 1);
    $self->create_table('new_table');
    return 1;
  }
  1;

=head1 DESCRIPTION

This module is the base class all migration changes inherit from.

=head2 Methods to overwrite

These methods should be overwritten in order to define the specific
change that the class represents.

=head3 after()

The after method returns the name of change class which is the
direct predecessor of the current change class.

If an empty string is returned, it means, this change does not
depend on any other change. There is usually only one change class
in an application with no predecessor, the first change. Though it
is possible to have many root change classes, this is very unlikely
and seldom what you want/need.

=head3 perform()

The perform method registers actual changes (e.g. "drop this table", 
"remove that column" etc.) to be part of the change class.
How you can register changes in the change class, is described below.

=head2 Manipulating the database (registering changes for a change class)

These methods should NOT be overwritten and allow to register actual
changes (manipulations) to be registered for this change class.

=head3 create_table( I<name> )

=head3 alter_table_rename( I<old-tablename>, I<new-tablename> )

=head3 alter_table_add_column( I<tablename>, I<columnname> )

=head3 alter_table_drop_column( I<tablename>, I<columnname> )

=head3 alter_table_modify_column( I<tablename>, I<columnname> )

=head3 alter_table_rename_column( I<tablename>, I<old-columnname>, I<new-columnname> )

=head3 drop_table( I<tablename> )

=head2 EXPORT

None by default.

=head1 SEE ALSO

None.

=head1 AUTHOR

Tom Kirchner, E<lt>tom@tomkirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
