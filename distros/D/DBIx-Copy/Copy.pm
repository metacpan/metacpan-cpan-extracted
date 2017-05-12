# Copyright (c) 2000 Tobias Brox.  All rights reserved.  This program
# is released under the GNU Public License which states that you are
# free to do whatever you want with the code - just as long as it
# keeps the same licensing.  It might also be released under The
# Artistic License if you send me a mail why GPL is insufficient.

package DBIx::Copy;

use strict;
use Carp;
use vars qw( $VERSION );
use DBI;

# Remember to update the POD (yeah, even the version number)!
$VERSION=0.02;

# Initiate a new object:
sub new {
    my $object_or_class = shift; my $class = ref($object_or_class) || $object_or_class;
    my ($dbh_source, $dbh_target, $options)=@_;
    my $self={
	src=>$dbh_source, 
	dst=>$dbh_target, 
	opts=>$options
    };

    # The only check that is done about whether the input parameters
    # are OK:
    die "source and target needed" 
	unless (defined $dbh_source and defined $dbh_target);

    bless $self, $class;
    return $self;
} 

# Copy the data - without taking any parameters into consideration for
# the time beeing.  Returns number of rows copied.  It might be handy
# for convertion tools to inherit this class and override this sub for
# tables that needs special handling.

# This seems like a bad way to do it - I branch too much of the code
# dependent on whether column_translation_table is set or not.
sub copy_one_table {
    my $self=shift;
    my $table=shift;
    
    my $cnt=0;

    my $dest = $self->{opts}->{table_translation_table}->{$table} || $table;
    
    my $select;
    my $insert;
    my $row;

    if (exists $self->{opts}->{column_translation_table}->{$table}) {

	my $c=$self->{opts}->{column_translation_table}->{$table};

	# Selecting referenced columns
	my $cols=join(",", keys(%$c));
	$select=$self->{'src'}->prepare("select $cols from $table") || return undef;
	$select->execute() || return undef;
	
	# Deleting all the destination table
	$self->{dst}->do("delete from $dest") || return undef;
	
	# Finding the right insert statement
	# There must be a better way to do this ... suggestions?
	my @qmarks;
	for (keys %$c) {push (@qmarks, '?')};

	$cols=join(",", values(%$c));

	my $qmarks = join(',',@qmarks);
	$insert=$self->{dst}->prepare("insert into $dest ($cols) values ($qmarks)") || return undef;

	$row=$select->fetch(); 

    } else {

	# Selecting all the table
	$select=$self->{'src'}->prepare("select * from $table") || return undef;
	$select->execute() || return undef;
	
	# Deleting all the destination table
	$self->{dst}->do("delete from $dest") || return undef;
	$row=$select->fetch(); 
	
	# Finding the right insert statement
	# There must be a better way to do this ... suggestions?
	my @qmarks;
	for (@$row) {push (@qmarks, '?')};
	my $qmarks = join(',',@qmarks);
	$insert=$self->{dst}->prepare("insert into $dest values ($qmarks)") || return undef;
    }
	
    while (defined $row) {
	$cnt++;
	$insert->execute(@$row);
	$row=$select->fetch;
	$insert->finish;
    }
    $select->finish;
    return $cnt;
}

# Copy tables
sub copy {
    my $self=shift;
    my $tables=shift;

    my $cnt=0; # return the number of rows copied

    # Tables should be a array-ref.
    # Maybe we first should test that it's an array?
    for my $table (@$tables) {
	$cnt+=$self->copy_one_table($table);
    }
    return $cnt;
}

1;

__END__

=head1 NAME

DBIx::Copy 0.02 - For copying database content from one db to another

=head1 SYNOPSIS

use DBIx::Copy;
use DBI;

my $dbh_source=DBI->connect(...);
my $dbh_target=DBI->connect(...);

my %options=();

my $copy_handler=
    DBIx::Copy->new($dbh_source, $dbh_target, \%options);

$copy_handler->copy
    (['tabletobecopied', 'anothertabletobecopied', ...]);

=head1 DESCRIPTION

For copying a DB.  Future versions might handle mirroring as well, but
it's generally better if the source might send over a transaction log
somehow.

The current version takes a crude "select * from table" from the
source table, and crudely puts it all into the destination table, with
a "delete from table" and "insert into table values (?, ?, ?, ...)".
Eventually column names are specified (option
column_translation_table).  There might be problems with this approach
for all I know.  Anyway, I think I can promise that the synopsis above
will behave the same way also for future versions of DBIx::Copy.

Currently the module can only copy data content.  Data definitions
might be handled in a future version.

=head1 OPTIONS

=head2 table_translation_table

If a table called FOO in the source database should be called Bar in
the destination database, it's possible to specify it in the options:

    $options{'table_tanslation_table'}={'FOO' => 'Bar'};

=head2 column_translation_table

If the table FOO contains a column with the name
"LASTUPDATEDTIMESTAMP", and we want to call it "LastUpdated" in the
table Bar, it's possible to specify it:

    $options{'column_translation_table'}->{FOO}={
	'ID' => 'id',
	'TITLE' => 'Title',
	'LASTUPDATEDTIMESTAMP' => 'LastUpdated'
	# _All_ columns you want to copy must be mentionated here.  I
	# will eventually fix a sub for initializing such a hash
	# reference.
    }

=head1 ERROR HANDLING AND STABILITY

DBIx::Copy->new will die unless it's feeded with at least two
arguments.

copy will just return undef if it fails somewhere.

The exception will probably be raised within the DBI.  By adjusting
settings within the DBI object, the error handling might be improved.
Check the options AutoCommit, PrintError and RaiseError.

Currently the module is optimisticly lacking all kind of locking.
This will have to be done outside the module.

Be aware that the testing script following this package is NOT GOOD
ENOUGH, it should be tested by hand using the synopsis above.

=head1 TODO

=head2 data_definitions

The module should also be capable of copying data definitions

=head2 avoid_deletion

It should be possible to avoid deleting the old table before inserting
a new.  The module should (by first running a select call) avoid
inserting duplicates.  This option will only insert new rows, not
update old ones.

=head2 replace

Do not delete old data in the destination table unless it is to be
replaced by new data from the source table.

=head2 max_timestamp / mirror

Check the timestamps and only import rows that has been modified after
max_timestamp (typically the timestamp for the last import).

mirror will try to fetch the last timestamp from the database, and
store the new timestamp in the database.

=head2 merge

If the same row is edited in both databases, try to merge the result.

=head2 locking

Locking should be supported somehow.

=head1 KNOWN BUGS

Except for all the "buts" and "ifs" and missing features above - none
yet - but this module is very poorly tested!

=head1 LICENSE

Copyright (c) 2000 Tobias Brox.  All rights reserved.  This program is
released under the GNU Public License.  It might also be released
under The Artistic License if you send me a mail why GPL is
insufficient.

=head1 AUTHOR

Tobias Brox <tobix@irctos.org>. Comments, bug reports, patches and
flames are appreciated.

=cut
