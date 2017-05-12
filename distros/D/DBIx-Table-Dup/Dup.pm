package DBIx::Table::Dup;

use 5.006;
use strict;
use warnings;

use DBIx::DBSchema;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Table::Dup ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.03';


# Preloaded methods go here.

sub date_string {

    my $d = lc `date +%b_%d_%H_%M_%S`;
    chomp $d;
    $d;

}

sub this {

    my (undef, $dbh, $tbl_name, $dup_name, $create, $append) = @_;

    $tbl_name or die 'must supply table to dup';

    $dup_name or die 'must supply table dup table name';

 #   warn $dbh;

    my $schema = new_native DBIx::DBSchema $dbh;

#    warn $schema;

    my @table_names = $schema->tables;

#    warn "@table_names";

    grep { $tbl_name eq $_ } @table_names or die
      "$tbl_name not found in @table_names";

    my $table = $schema->table($tbl_name);

#    warn $table;

    my ($table_create) = $table->sql_create_table($dbh);

    $table_create =~ s!CREATE TABLE \w+!CREATE TABLE $dup_name!;

    $table_create .= $append;

    return $table_create unless $create;

#    warn $table_create;

    $dbh->do($table_create);

    return $table_create;

}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

DBIx::Table::Dup - Perl module to (return SQL to) create duplicate copy of table

=head1 SYNOPSIS

 use DBIx::Table::Dup;

sub mktmptbl {

    my $src_table = shift;


    "${src_table}_" . DBIx::Table::Dup::date_string;
}


 $dup_tbl_name = mktmptbl($src_tbl_name);

 my $append = "Type=InnoDB"; 


 # just return the SQL for the table to create. Do not create table
 my $create_sql = DBIx::Table::Dup->this ($dbh, $src_tbl_name, $dup_tbl_name, 0);

 # create the table
 my $create_sql = DBIx::Table::Dup->this ($dbh, $src_tbl_name, $dup_tbl_name, 1);

 # append this to the create string
                  DBIx::Table::Dup->this ($dbh, $src_tbl_name, $dup_tbl_name, 1, $append);

 

=head1 DESCRIPTION

This module duplicates a table in any database that DBIx::DBSchema can read.
DBIx::DBSchema is smart enough to know which database you are dealing with 
simply by looking at the valid C<$dbh>.

=head1 METHODS

=head2 this ($dbh, $src, $dup, $create, $append)

C<this> takes the following arguments: C<$dbh> is a database handle to the
database with the table you want to duplicate. C<$src> is the name of the 
table to be duplicated. C<$dup> is the name of the duplicate table.
C<$create> is a flag which, if set, will actually create the table. Otherwise
the SQL for the table duplication is returned. C<$append> is a string which
will be appended to the SQL creation string. This is useful if you have 
something Mysql-specific (like the InnoDB table type in the SYNOPSIS).


=head1 AUTHOR

T. M. Brannon <tbone@cpan.org>

=head1 SEE ALSO

L<perl>. L<DBIx::DBSchema>, L<DBIx::Connect>

=cut
