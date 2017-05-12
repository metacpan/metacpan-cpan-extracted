package CGI::CRUD;

=head1 NAME

CGI::CRUD - Instant CRUD web front-end, featuring auto-discovery of the data dictionary for an RDBMS source

=head1 DESCRIPTION

This module provide a framework to create web forms for a front-end CRUD interface to a variety of data sources. It features auto-discovery of the data dictionary for an RDBMS source.

With this framework, you can get a basic CRUD web interface up and running in minutes without coding. At the same, it allows a great deal of flexibility
for customization by engineers (application functionality/business logic) and non-engineers (presentation and style) alike.

CRUD now, code later.


CRUD (Create, Read/Report, Update, Delete) are the four basic data manipulation commands of a data source; e.g. enabling management of configuration data in an administrative interface
to your application.

A unique and powerful advantage with this CRUD abstraction is that it can be tied closely with a database schema. Each group of fields in the form can represent a database table (or view) and the table/column properties and constraints are automagically discovered so your DBA can make DDL changes that will be immediately reflected in the HTML forms  - no duplication of the data dictionary in your code.

All user/operator input is checked tightly against database constraints and there is built-in magic to provide convenient select lists, etc, and to enforce a discreet set of valid values against unique/primary keys in lookup tables. This means referential integrity even for MySQL. Metadata in MySQL's C<SET> and C<ENUM> types are also supported.  This also gives the operator a chance to correct mistakes with helpful hints instead of just getting a meaningless db error code.

Another advantage this abstraction provides is the separation of presentation and style using style sheets and having human-friendly presentation attributes stored in a database table that can be managed by non-engineers.

=head1 SEE ALSO

For a quick start, see Cruddy!

L<http://www.thesmbexchange.com/cruddy/index.html>

For internals, start with L<CGI::CRUD::TableIO> and L<CGI::AutoForm>.

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut

*CGI::CRUD::VERSION = \'1.06';

1;
