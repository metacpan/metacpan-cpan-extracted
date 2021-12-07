package DBIx::DBFlow;
  our $VERSION = '0.03';

  # This package is just a placeholder for the version

### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

DBIx::DBFlow - Database development helpers

=head1 SYNOPSIS

in your cpanfile add the following

  requires 'DBIx::DBFlow::Runtime';

  on develop => sub {
    requires 'DBIx::DBFlow';
  }

=head1 USAGE

=head2 Using the DBFlow on a new project:

Create the database in MySQL (tables, fks, etc)

  dbflow_refresh_model --schema MySchema --dbh "DBD:mysql..."

This will create lib/MySchema.pm. Add this code to it:

  our $VERSION = 1;
  
  sub admin_connection {
    my $schema = __PACKAGE__->connect(
      "DBI:mysql:mysql_read_default_file=pathtoadmincreds.cnf;mysql_read_default_group=schema_group",
      undef,
      undef,
      {
        AutoCommit => 1,
        RaiseError => 1,
        mysql_enable_utf8 => 1,
        quote_char => '`',
        name_sep   => '.',
      },
    );
  }

Now install the DBFlow with

  dbflow_create --schema MySchema

Creates a "database" directory with the deploy info for the database. Creates a handler table in your schema

=head2 Using the DBFlow

Before modifying the database, bump up it's version (you're about to produce what will be the next version 
of the database, so we have to signal that)

Modify the database with your favorite tool (HeidiSQL, mysql CLI, etc). Add columns, indexes, etc.

  dbflow_refresh_model --schema MySchema

This will regenerate lib/MySchema

You can still tweak the database more times (add more columns, change types, etc). You have to execute 
C<dbflow_refresh_model> each time, in order to refresh the DBIx::Class model

When you're happy with your changes, and want to produce an upgrade:

  dbflow_make_upgrade_scripts --schema MySchema

This creates a C<database/MySQL/upgrade/X-Y/___.sql> file that contains the SQL instructions to migrate
from version X to version Y.

You can create your own (new) SQL files in the same directory that will be executed on upgrade, for operations 
that cannot be automatically derived (suppose you have to UPDATE some values on a table), although it's better
to create Perl files that do the updating with the model (so you don't have to implement complex logic in SQL).

Create a C<database/_common/upgrade/X-Y/01-upgrade_step.pl> file (where Y corresponds the version you are producing,
and X to the previous one). Put this code in it:

  sub {
    my $model = shift;
  
    my $things = $model->resultset('Things')->search({ ... });
  }

Do whatever perlish things you want in the update script, and please use the model to do it.

you can test the updating all the times you want with C<make obliviatedb> and C<dbflow_upgrade_schema --schema MySchema>
until you are sure that the update will work in production.

=head2 Updating the production database

  dbflow_upgrade_schema --schema MySchema

In production all you have to do is execute C<dbflow_upgrade_schema>.

=head1 Interesting utilities

=head2 Visualizing your schema

You can visualize your schema with

  dbflow_schema_diagram --schema MySchema

It will generate a PNG image called MySchema_schema.png

You can control the dimensions of the image with C<--height> and C<--width> parameters.

You can also specify the name of the file to write to with C<--file>.

=head1 FAQ

=head2 MySchema.pm cannot be found

The 'lib' directory in the current directory is automatically included (your schema should be there).
You can use the C<-I> option to specify an alternate, or try executing with a PERL5LIB that points to the 
appropiate directory with your schema.

=head2 I have more than one schema to manage in my project

All utils let you specify the schema name you're acting upon with C<--schema> and the directory
to create the upgrade/deploy scripts C<--dir>

=head1 CONTRIBUTE

The source code and issues are on https://github.com/pplu/dbix-dbflow

=head1 AUTHOR
    Jose Luis Martinez
    CPAN ID: JLMARTIN
    pplusdomain@gmail.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2016 by Jose Luis Martinez Torres

This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut

1;
