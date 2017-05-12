package Alzabo;

use Alzabo::Exceptions;

use Alzabo::Column;
use Alzabo::ColumnDefinition;
use Alzabo::ForeignKey;
use Alzabo::Index;
use Alzabo::Schema;
use Alzabo::Table;

use Alzabo::Config;
use Alzabo::Debug;

use vars qw($VERSION);

use 5.006;

$VERSION = '0.92';
$VERSION = eval $VERSION;


1;

__END__

=head1 NAME

Alzabo - A data modelling tool and RDBMS-OO mapper

=head1 SYNOPSIS

  Cannot be summarized here.

=head1 DESCRIPTION

=head2 What is Alzabo?

Alzabo is a suite of modules with two core functions.  Its first use
is as a data modelling tool.  Through either a schema creation GUI, a
perl program, or reverse engineering, you can create a set objects to
represent a schema.

Its second function is as an RDBMS to object mapping system.  Once you
have created a schema, you can use the
L<C<Alzabo::Runtime::Table>|Alzabo::Runtime::Table> and
L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row> classes to access its
data.  These classes offer a high level interface to common operations
such as SQL C<SELECT>, C<INSERT>, C<DELETE>, and C<UPDATE> commands.

Because you can manipulate construct queries through object-oriented
Perl, creating complex queries on the fly is much easier than it would
be if you had to dynamically construct strings of SQL.

A higher level interface can be created through the use of the
L<C<Alzabo::MethodMaker>|Alzabo::MethodMaker> module.  This module
takes a schema object and auto-generates useful methods based on the
tables, columns, and relationships it finds in the module.  The code
is generates can be integrated with your own code quite easily.

To take it a step further, you could then aggregate a set of rows from
different tables into a larger container object which could understand
the logical relationship between these tables.

=head2 What to Read?

Alzabo has a lot of documentation.  If you are primarily interested in
using Alzabo as an RDBMS-OO wrapper, much of the documentation can be
skipped.  This assumes that you will create your schema via a schema
creation GUI or via L<reverse
engineering|Alzabo::Create::Schema/reverse_engineer>.

Here is the suggested reading order:

L<Introduction to Alzabo|Alzabo::Intro>

The RDBMS-specific documentation:

=over 4

L<Alzabo and MySQL|Alzabo::MySQL>

L<Alzabo and PostgreSQL|Alzabo::PostgreSQL>

=back

L<The Alzabo::Runtime::Schema docs|Alzabo::Runtime::Schema> - The most
important parts here are those related to loading a schema and
connecting to a database.  Also be sure to read about the
L<C<join()>|Alzabo::Runtime::Schema/join> method.

L<The Alzabo::Runtime::Table docs|Alzabo::Runtime::Table> - This
contains most of the methods used to fetch rows from the database, as
well as the L<C<insert()>|Alzabo::Runtime::Table/insert> method.

L<The Alzabo::Runtime::Row docs|Alzabo::Runtime::Row> - The row
objects contain the methods used to update, delete, and retrieve data
from the database.

L<The Alzabo::Runtime::RowCursor docs|Alzabo::Runtime::RowCursor> - A
cursor object that returns only a single row.

L<The Alzabo::Runtime::JoinCursor docs|Alzabo::Runtime::JoinCursor> -
A cursor object that returns multiple rows at once.

L<The Alzabo::MethodMaker docs|Alzabo::MethodMaker> - One of the most
useful parts of Alzabo.  This module can be used to auto-generate
methods based on the structure of your schema.

L<The Alzabo::Runtime::UniqueRowCache
docs|Alzabo::Runtime::UniqueRowCache> - This describes the simple
caching system included with Alzabo.

L<The Alzabo::Debug docs|Alzabo::Debug> - How to turn on various kinds
of debugging output.

L<The Alzabo::Exceptions docs|Alzabo::Exceptions> - Describes the
nature of all the exceptions used in Alzabo.

L<The FAQ|Alzabo::FAQ>.

L<The quick reference|Alzabo::QuickRef> - A quick reference for the
various methods of the Alzabo objects.

=head1 SCRIPTS

Alzabo comes with a few handy scripts in the F<eg/> directory of the
distribution.  These are:

=over 4

=item * alzabo_grep

Given a regex and a schema name, this script will print out the table
and column name for all columns which match the regex.

=item * alzabo_to_ascii

Given a schema name, this script will generate a set of simple ASCII
tables for the schema.

=back

=head1 SUPPORT

The Alzabo docs are conveniently located online at
http://www.alzabo.org/docs/.

There is also a mailing list.  You can sign up at
http://lists.sourceforge.net/lists/listinfo/alzabo-general.

Please don't email me directly.  Use the list instead so others can
see your questions.

=head1 COPYRIGHT

Copyright (c) 2000-2003 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
