package DBIx::Report::Excel;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.4';

=head1 NAME

DBIx::Report::Excel - creating Excel reports from SQL statements

=head1 SYNOPSIS

  use DBIx::Report::Excel;
  my $report = DBIx::Report::Excel->new (
	"SQLite.xls",
     	sql => 'SELECT first_n, last_n FROM people',
     	dbh => DBI->connect("dbi:SQLite:dbname=testdb","","")
  );
  $report->write();
  $report->close();


=head1 DESCRIPTION

DBIx::Report::Excel's goal is to make creating reports in Excel from
databases easy. It's aimed at SQL developers and/or DBA's who don't
know much about Perl programming. I.e. most of the information needed
to create Excel file is provided directly in SQL statement (script)
itself.

If SQL script contains multiple statements, resulting Excel file is
formatted as multi-page spreadsheet with each result set on it's own
worksheet.

=head2 FORMATTING EXCEL WORKSHEETS

=head3 COLUMNS

B<Column names> on each worksheet are defined from table column names
or aliases provided by 'AS' directive in SQL statement.

Excel column names are defined from parsing of SQL statement, not from
actual name of columns in table(s). If SQL staements does not
explicitly have column names or aliases listed (as for example, in
case of SELECT * query), Excel columns will have generic names
'Column+<number>'. See L<EXAMPLES> below


=head3 EMBEDDING YAML IN SQL COMMENT BLOCK

All additional directives for formatting Excel output are provided as
YAML structure, embedded in SQL comment blocks. Supported comment style
is C-style 'slash and asterisk' (C</* ... */>) comments.  ANSI 'double
hyphen' (C<-- ...>) comment style is not supported in this version.

Slash and asterisk C-style (C</* ... */>) includes multi-line
comment blocks conforming to YAML specifications.

YAML statements embedded in multiline comment block must start from
the beginning of each new line. All spaces are significant during YAML
processing. Statement indentation must correspond to YAML
specifications.


YAML directives must have separators C<---> at start and at the
end. Seaparator can be written either on the same line with commetn
start/end or on its own line. Extra spaces between comment start/end
and separator are ignored if separator is written on the same
line. (See EXAMPLES 3 and 4 below).


=head3 COMMENTS INSIDE YAML BLOCK

To isolate actual comments from YAML processing, use YAML comments
(lines starting with hash symbol C<#>) inside SQL comment blocks:-

  /*
  # This comment is not processed by YAML parser.
  ---
  title: My Worksheet Name
  ---
  */

=head3 YAML KEYWORDS

=head4 title:

Only one keyword is suported in this version: 'title'. It defines
Excel worksheet name. If no workshet name is provided, then worksheet
is created with generic name 'Sheet+<number>'.

=cut

=head1 DEPENDENCIES

This module uses following Perl modules:

 Data::Tabular::Dumper
 Data::Tabular::Dumper::Excel
 SQL::Parser
 SQL::Script
 YAML

=cut

# --------------------------------------------------------------------------------
use Data::Tabular::Dumper;
use Data::Tabular::Dumper::Excel;
use SQL::Parser;
use SQL::Script;
use YAML;
# --------------------------------------------------------------------------------

require Exporter;

our @ISA = qw(Exporter);

=head2 EXPORT

None.

=cut

our @EXPORT = qw( &write );

=head1 METHODS

=head2 new()

  use DBIx::Report::Excel;

  my $report = DBIx::Report::Excel->new( "Excel.xls" );

Method new() creates new instance of Excel report object.  It takes one
required parameter- output Excel file name, and two optitonal parameters:
database connection handler (dbh) and SQL query text (sql):

  my $report = DBIx::Report::Excel->new(
    "Excel.xls",
     dbh => DBI->connect("dbi:SQLite:dbname=testdb","",""),
     sql => 'SELECT * FROM names',
    );

=cut

sub new {
  my $type = shift;
  my $self = {};
  my ($filename, %params) = @_;
  $self->{'filename'} = $filename;
  $self->{'excel'} = Data::Tabular::Dumper->open  (Excel => [ $self->{'filename'} ] );
  $self->{'dbh'} = $params{'dbh'} || undef;	# DB handler
  $self->{'sql'} = $params{'sql'} || undef;	# SQL text
  $self->{'worksheet'} = 0;
  $self->{'worksheets'} = undef;		# List of all crated worksheets
  bless $self, $type;
}
# --------------------------------------------------------------------------------


=head2 dbh()

   $report->dbh(
       DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port;options=$options",
                     $username,
                     $password,
                     {AutoCommit => 0, RaiseError => 1, PrintError => 0}
                     )
                );

Sets database handler if it was not set by new() method. It also gives
ability to change Db connection on the fly to query different
databases in one report.

=cut

sub dbh {
  my $self = shift;
  if (@_) { $self->{dbh} = shift }
  return $self->{dbh};
}

=head2 sql()

Defines SQL query for the report. Can contain either single SQL
statement or multiple queris separated by semicolon followed by a new line
(C<;\s*\n>). Each separate query will produce its own workseet in multipage
Excel workbook.

An example:

  $report->sql(
      qq{
  /*---
  title: People Names
  ---*/

  SELECT first_name as "First Name",
         last_name as "Family name"
  FROM people

  });

=cut

sub sql {
  my $self = shift;
  if (@_) { $self->{sql} = shift }
  return $self->{sql};
}
# --------------------------------------------------------------------------------

=head2 write()

Creates and writes new Excel worksheet for each SQL query (or multiple
worksheets when several SQL queries, joined by C<;\n>).

Can accept one optional parameter: SQL statement string.

An example:

  $report->sql("SELECT first_name, last_name FROM people");
  $report->write();

  $report->write("SELECT f_name, color from fruits");

=cut

sub write {
  my $self = shift;

  carp::croak("Database handler is not defined. Can not run query.")
      unless $self->dbh();

  $self->{'sql'} = shift || $self->{'sql'};

  carp::croak("Can not run query: you doid not give me any SQL query text.")
      unless $self->sql();

  # Split SQL into separate statements
  my $statements = SQL::Script->new( split_by => qr/;\s*\n/ );

  for my $sql ( @{$statements->split_sql(\$self->{'sql'})} ) {
    $self->{'data'} = $self->__new_page($sql);
  }

  return $self->{'data'};
}

=head2 close()

Cleanly close Excel file.

=cut

sub close {
  my $self = shift;
  $self->{'excel'}->close();
}
# --------------------------------------------------------------------------------

=head1 PRIVATE METHODS

=head3 __new_page()

Adds new workseet to Excel workbook. This method is called for each
separate SQL SELECT statement by write(). If SQL script passed to
write(0 contains several SQL statements, then __new_page() is called
for each of them.

=cut

sub __new_page {
  my $self = shift;
  my ($sql) = shift;

  my $page_name = $self->__page_name(__parse_comments($sql));
  $self->{'excel'}->page_start( $page_name );

  $self->{'data'} = $self->{'dbh'}->selectall_arrayref($sql);

  return unless scalar @{ $self->{ data } };

  # ----------------------------------------
  # Define column names.
  my $parser = SQL::Parser->new();
  $parser->parse($sql);

  if ( scalar @{$parser->structure->{'column_defs'}} == scalar @{$self->{'data'}->[0]} ) {
				# i.e. column number in SQL statement
				# same as number of actually selected
				# columns (it's not  "SELECT *")
    $self->{'excel'}->fields($parser->structure->{'org_col_names'});
  } else {			#  i.e. SELECT *
    $self->{'excel'}->fields( [map {"Column" . $_} (1..scalar @{$self->{'data'}->[0]})])
  }

  $self->{'excel'}->dump( $self->{'data'} );
  return $self->{'data'};
}
# --------------------------------------------------------------------------------

=head3 __page_name()

Get a worksheet name from SQL. Parses YAML structure embedded in SQL
comment block. If no such thig provided worksheet will have name
'Sheet+<number>'.

=cut

sub __page_name {
  my $self = shift;
  my ($yaml) = @_;

  my $page_name = $yaml->{'title'} || "Sheet" . $self->{'worksheet'};

  if ( $self->{'worksheets'} ) { # if worksheet with this name exists
                                 # already, give new sheet generic
                                 # name
    $page_name = "Sheet" . $self->{'worksheet'}
      if scalar (grep {/^$page_name$/} @{$self->{'worksheets'}}) == 1;
  }

  $self->{'worksheet'}++;
  push @{$self->{'worksheets'}}, $page_name;

  return $page_name;
}
# --------------------------------------------------------------------------------

=head3 __parse_comments()

Extract all comments from SQL statement and parses them with YAML
parser. Returns parsed hash.

=cut

sub __parse_comments {
  my ($text) = @_;
  my @lines = split /\n+/, $text;
  my @comments;
  my $comment_block = undef;
 LINES:
  for (@lines) {
#    push @comments, $1, next LINES if /^\s*-- (.*)$/;	   # -- ... TODO
    push @comments, $1, next LINES if /^\s*\/\* (.*)\*\/\s*$/; # /* ...*/
    if (/\/\*/../\*\//) {
      s/(\/\*+\s*)//;
      s/(\s*\*+\/)//;
      push @comments, $_;
    }
  }
  push @comments, "\n\n";
  return YAML::Load(join "\n", @comments);
}
# --------------------------------------------------------------------------------

1;
__END__

=head1 EXAMPLES

=head2 COLUMN NAMES FROM SQL PARSING

=head3 EXAMPLE 1

Columns in Excel workseet have names C<FIRST_NAME> and C<LAST_NAME>:

   SELECT first_name,
          last_name
   FROM people

=head3 EXAMPLE 2

Excel columns have names C<First Name> and C<Family Name>:

   SELECT first_name as "First Name",
          last_name as "Family Name"
   FROM people

=head2

=head3 EXAMPLE 3

YAML block separateor placed on its own line. Excel worksheet name is
"My Worksheet Name".

  /*
  ---
  title: My Worksheet Name
  ---
  */

=head3 EXAMPLE 4

YAML separators on the same line with comment start and end. Same
worksheet name as above.

  /*---
  title: My Worksheet Name
  --- */

=head3 SEE ALSO

 As of 2010, November project repository moved to Github:
 https://github.com/dmytro/DBIx-Report-Excel
 

 Script example.pl provides full example of creating report from
 SQLite database. It uses "testdb" database in /tmp directory.


=head1 AUTHOR

Dmytro Kovalov, E<lt>dmytro.kovalov@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2010 by Dmytro Kovalov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
