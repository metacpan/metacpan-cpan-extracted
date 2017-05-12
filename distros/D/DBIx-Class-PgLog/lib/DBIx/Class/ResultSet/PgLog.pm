package DBIx::Class::ResultSet::PgLog;

use strict;
use warnings;

use base "DBIx::Class::ResultSet";

=head1 NAME

DBIx::Class::ResultSet::PgLog - ResultSet base class for DBIx::Class::PgLog

=head1 VERSION

version 0.1

=head1 SYNOPSIS

Either create your own resultset-classes for each audited result-class, and load 
PgLogs resultset-component:

	package MySchema::ResultSet::MyAuditedSource;
	
	use base "DBIx::Class::ResultSet"; # or use Moose and MooseX::NonMoose;

	__PACKAGE__->load_components("ResultSet::PgLog");

Or set the default resultset-class in your Schema:

	package MySchema;

	use base "DBIx::Class::Schema";

	...

	__PACKAGE__->load_namespaces(
		default_resultset_class => "PgLog"
	);

=head1 DESCRIPTION

This resultset class enables logging for database updates made by calling
L<DBIx::Class::ResultSet/delete> and L<DBIx::Class::ResultSet/update>.
This includes any updates made by methods which rely on the above, like
L<DBIx::Class::Relationship::Base/set_\$rel>.

If you want full logging in a relational database, you most likely want to use this 
component.

=head2 NOTE:

The current implementation enables logging in the resultset by simply delegating
'delete' and 'update' to 'delete_all' and 'update_all', which call the required triggers.
As a result, a database query like 

 "DELETE FROM table WHERE id IN '1', '2', '3'"

will result in 3 atomic queries:

 "DELETE FROM table WHERE id = '1'";
 "DELETE FROM table WHERE id = '2'";
 "DELETE FROM table WHERE id = '3'";

which is much slower. It is therefore recommended to use this module only for resultset classes where it is needed.
Specifying this module as default resultset class is only recommended if logging is needed for all tables.


=head1 L<DBIx::Class::ResultSet> OVERRIDDEN METHODS

=head2 delete

Calls L<DBIx::Class::ResultSet/delete_all> to ensure that triggers defined by
L<DBIx::Class::PgLog> are run.

=cut

sub delete {
	shift->delete_all;
};

=head2 update

Calls L<DBIx::Class::ResultSet/update_all> to ensure that triggers defined by
L<DBIx::Class::PgLog> are run.

=cut

sub update {
	shift->update_all(@_);
}

=head1 AUTHORS

See L<DBIx::Class::PgLog/AUTHOR> and L<DBIx::Class::PgLog/CONTRIBUTORS>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
1;


