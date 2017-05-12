package DBIx::Class::ResultSet::AuditLog;
$DBIx::Class::ResultSet::AuditLog::VERSION = '0.6.4';
use strict;
use warnings;

use base "DBIx::Class::ResultSet";


sub delete {
	shift->delete_all;
};


sub update {
	shift->update_all(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::ResultSet::AuditLog

=head1 VERSION

version 0.6.4

=head1 SYNOPSIS

Either create your own resultset-classes for each audited result-class, and load 
AuditLogs resultset-component:

	package MySchema::ResultSet::MyAuditedSource;
	
	use base "DBIx::Class::ResultSet"; # or use Moose and MooseX::NonMoose;

	__PACKAGE__->load_components("ResultSet::AuditLog");

Or set the default resultset-class in your Schema:

	package MySchema;

	use base "DBIx::Class::Schema";

	...

	__PACKAGE__->load_namespaces(
		default_resultset_class => "AuditLog"
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

=head1 NAME

DBIx::Class::ResultSet::AuditLog - ResultSet base class for DBIx::Class::AuditLog

=head1 VERSION

version 0.1

=head1 L<DBIx::Class::ResultSet> OVERRIDDEN METHODS

=head2 delete

Calls L<DBIx::Class::ResultSet/delete_all> to ensure that triggers defined by
L<DBIx::Class::AuditLog> are run.

=head2 update

Calls L<DBIx::Class::ResultSet/update_all> to ensure that triggers defined by
L<DBIx::Class::AuditLog> are run.

=head1 AUTHORS

See L<DBIx::Class::AuditLog/AUTHOR> and L<DBIx::Class::AuditLog/CONTRIBUTORS>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Mark Jubenville <ioncache@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
