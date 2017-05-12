package Database::Format::Text;

# Use tab width 8 to view at its best :).

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;
use File::Spec;
use File::Copy;

=head1 NAME

Database::Format::Text - Local database in text format.

=head1 VERSION

Version 1.03

=cut

our $VERSION = '1.03';


=head1 SYNOPSIS

C<Database::Format::Text> module is handy tool to create a text based database
on local machine. This module will create database in text format, so user 
can any time open the text file and look at the data. User will be able to do 
following manipulation on the data base using this module.

=over 4

=item * Add data

=item * Delete data

=item * Append data

=item * Get titles

=item * Get data

=item * Get whole data base

=item * Count entries

=back

To modify the existing entry, delete the existing entry and re-enter the modified 
entry. Following is the example to use C<Database::Format::Text>

	use Database::Format::Text;
	my @titles = qw(Number Title Status Comments);

	# Create database
	my $foo_data_table = Database::Format::Text->new('file_name' => "foo_data", 
							 'fields' => \@titles);
	# Add entry
	my $status = $foo_data_table->add_entry("1", "Test1", "Pass", "Applicable");

	# Delete entry
	$status = $foo_data_table->delete_entry("Status", "Pass");

	# Get entry
	my @data = foo_data_table->get_entry("Number", 7);
	# or
	$status = foo_data_table->get_entry("Number", 7, "Status");

	# Get database
	my @database = $foo_data_table->get_table();

	# Count entries
	$status = $foo_data_table->count_entry("Status", "Pass");

	# Get titles
	@database = $foo_data_table->get_titles();

You can use this module at many places. Example : If you are a test engineer and
 you need to perform some test cases on your product this data base will help to
 store your records. It is in text based format so you can copy this data base 
in your archive for future reference.

=head1 SUBROUTINES

=head2 new

Creates and returns a new Database::Format::Text object.

	my @titles = qw(Number Title Status Comments [ . . .]);
						# User can add N number of columns here.
	my $foo_data_table = Database::Format::Text->new('file_name' => "foo_data", 
							 'fields' => \@titles);

Constructor needs 2 parameters. Without above 2 parameters program will die. 2 
parameters are file name and titles for database. File name is required to store 
the database. Fields are titles of the column of your database.
In above example user will create a database in text format in file "foo_data". 
Which will have 4 columns. Columns would be Number, Title, Status and Comments.

Here are the parameters that Database::Format::Text recognizes. These are optional.

=over 4

=item * C<< 'location' => '/your/folder/to/store/database' >>

This variable will store the folder location. Database::Format::Text module will
create a database in text format in above mentioned location or if above 
parameter is not defined then it will store database in current working directory.

=item * C<< 'delimiter' => '|' >>

Database will have many fields. Each field is divided by delimiter. Use this 
variable to specify the delimiter of your database. If this is not supplied,
Database::Format::Text will use ':' as the delimiter.


=item * C<< 'append' => [0|1] >>

If you want to create a single database and run your perl program multiple times
on the same database then use this variable. If it is enabled the database will
append the new records. If this is disabled Database::Format::Text will
delete old database and and create a new database.

=item * C<< 'column_width' => 20 >>

Based on your data select this variable. Above example will create 20 width column
for each of the entry.

=item * C<< 'die' => [0|1] >>

During many sanity tests Database::Format::Text will die your program if  
any failure. If you want to continue without dyeing, enable this variable.

=back

=cut

sub new {
	my $class = shift;
	my %user_args = @_;

	#
	# process user arguments.
	#
	if (! defined $user_args{'file_name'} || ! defined $user_args{'fields'}[0]) {
		die "Define file_name and fields variables";
						# Just die if mandatory variables are not provided.
	}
	_test_unique_fields(@{$user_args{'fields'}});
						# Make sure all the titles are unique.
	my $location = ((defined $user_args{'location'}) ? ($user_args{'location'}) : ('.'));
						# This is the location to create user data table.
	my $delimiter = ((defined $user_args{'delimiter'}) ? ($user_args{'delimiter'}) : (':'));
						# This will separate each records in data table.
	my $append = ((defined $user_args{'append'}) ? ($user_args{'append'}) : (0));
						# If enable do not delete all data table.
	my $column_width = ((defined $user_args{'column_width'}) ? ($user_args{'column_width'}) : (10));
						# This will produce uniform output in the data table.
	my $l_o_f = $location . "/" . $user_args{'file_name'};
						# The complete location to file.
	$l_o_f = File::Spec->canonpath($l_o_f);
						# User can use this on Linux as well as on Windows.
	my $die = ((defined $user_args{'die'}) ? ($user_args{'die'}) : 1);
						# Script will die out if enable
	my $f_c = @{$user_args{'fields'}};
						# Variable to provide sanity.

	#
	# The hash reference is created.
	#
	my $data_table_ref = {
				'file_name' => $user_args{'file_name'},
				'fields' => \@{$user_args{'fields'}},
				'location' => $location,
				'delimiter' => $delimiter,
				'append' => $append,
				'column_width' => $column_width,
				'die' => $die,
				'l_o_f' => $l_o_f,
				'f_c' => $f_c,
				};

	#
	# Create data file. Do not create a new file if append is enabled.
	#
	unless (defined $data_table_ref->{'append'} && $data_table_ref->{'append'} == 1 && -f $data_table_ref->{'l_o_f'}) {
		my ($pattern, @entry);

		#
		# Open the new file in write mode.
		#
		open(DT, ">" , $data_table_ref->{'l_o_f'}) or _die($data_table_ref, "Failed to create a data table file $!");
		@entry = @{$data_table_ref->{'fields'}};
		
		#
		# Create and print the pattern.
		#
		foreach (0 .. $#entry) {
			if ($_ == $#entry) {
				$pattern = $pattern . sprintf ( "%-$data_table_ref->{column_width}s \n", $entry[$_]);
			} else {
				$pattern = $pattern . sprintf ( "%-$data_table_ref->{column_width}s $data_table_ref->{delimiter} ", $entry[$_]);
			}
		}
		print DT $pattern;

		#
		# Close the opened file.
		#
		close(DT);
	}

	#
	# blessing the class.
	#
	bless($data_table_ref);
	return $data_table_ref;
}

=head2 $foo_data_table->add_entry(@data_records)

This method will create an actual data entry into your database. This method takes
list of data. In our example we have 4 columns; Number, Title, Status and Comments.
Therefore our data to be entered is 4. For example it is 1, Test1, Pass and 
Applicable.

	my @data_records = ("1", "Test1", "Pass", "Applicable");
	$foo_data_table->add_entry(@data_records);

This database will have an entry with above data. If this method
creates the entry, it will return 0.

=cut

sub add_entry {
	my $this = shift;
	my @entry = @_;
	my $pattern;

	#
	# Sanity test on users provided data.
	#
	(warn ("Failed to add mismatch in number of titles and records!\nNumber of record has to be $this->{f_c}\nNumber of elements are not equal to $this->{f_c}.\nThe elements are @entry\n") && (return -1)) if (@entry != $this->{'f_c'});

	#
	# Open the data base table and add the entry.
	#
	open(DT, ">>" , $this->{l_o_f}) or _die($this, "Failed to create a data table file $!");

	#
	# Create the pattern.
	#
	foreach (0 .. $#entry) {
		if ($_ == $#entry) {
			$pattern = $pattern . sprintf ( "%-$this->{column_width}s \n", $entry[$_]);
		} else {
			$pattern = $pattern . sprintf ( "%-$this->{column_width}s $this->{delimiter} ", $entry[$_]);
		}
	}

	#
	# Print the pattern.
	#
	print DT $pattern;

	#
	# Close the opened file.
	#
	close(DT);
	return 0;
}

=head2 $foo_data_table->delete_entry($title, $record)

After creating database, if you need to remove one entry from your database, use 
this method to remove entry. It takes 2 arguments. One is title. You can remove
entry using any title. In our example I will remove entry using title "Status".
2nd argument is actual record itself. In our example I would like remove entries
with record as Pass. I will use below code as my example.

	my $status = $foo_data_table->delete_entry("Status", "Pass");

This code will search pattern "Pass" under "Status" in your database and remove 
all matched entries. This method will return number of removed entries. If it did
not find above pattern in your database, it will return 0. If it finds multiple
entries, this method will erase all matched entries. In above example if this method
finds 5 data as "Passing" under column "Status", method will delete all 5 entries
and return 5.

=cut

sub delete_entry {
	my $this = shift;
	my $field_name = shift;			# Title.
	my $record = shift;			# Record needs manipulation.
	my @all_fields;				# Holds all the titles.
	my @database_line;			# Holds data table lines.
	my $given_field_index;			# Index of the titles to the @all_fields.
	my $count = 0;				# Counts the number of entries deleted.

	#
	# Open database file to read titles.
	#
	open(DT, "<" , $this->{'l_o_f'}) or _die($this, "Failed to open up data table file $!");
	while(<DT>) {
		@all_fields = split(/$this->{'delimiter'}/, $_);
		last;
	}

	#
	# Close the opened database table file.
	#
	close(DT);

	#
	# Remove head and trail white spaces.
	#
	map {s#^\s*(\w*.*\w)\s*$#$1#} @all_fields;
	map {s#^\s+$# #} @all_fields;

	#
	# Give sanity on users data.
	#
	_die($this, "The field \"${field_name}\" does not exist in list \"@{all_fields}\"") unless (grep(/^$field_name$/,@all_fields));

	#
	# Copy the original data table to tmp file.
	#
	copy($this->{'l_o_f'}, ".tmp") or _die($this, "Copy failed: $!");

	#
	# Check for the tmp existence.
	#
	unless (-f ".tmp") {
		warn "Fatal Error: Failed to create a back up file, unable to  delete entry";
		return;
	}

	#
	# Re-open the data table file with write mode.
	#
	open(DT, ">" , $this->{'l_o_f'}) or _die($this, "Failed to open up data table file $!");
	
	#
	# Search for index of field_name.
	#
	foreach (0 .. $#all_fields) {
		($given_field_index = $_) if ( $all_fields[$_] eq $field_name );
	}

	#
	# Open new temporary file.
	#
	open(TMP, "<", ".tmp") or _die($this, "Failed to open up data table file ('') $!");
	while(<TMP>) {
		if ($_ =~ m/$record/) {
			@database_line = split(/$this->{'delimiter'}/, $_);
			map { s/^\s*(\w*.*\w)\s*$/$1/ } @database_line;
						# Remove trailing and heading white spaces.
			map { s/^\s+$/ / } @database_line;
						# Remove multiple spaces.
			if ($database_line[$given_field_index] eq $record) {
				++$count; 
				next;
			}
		}
		print DT $_;
	}

	#
	# Close both the files.
	#
	close(TMP);
	close(DT);

	#
	# Delete the temporary file.
	#
	unlink(".tmp");
	return $count;				# $return will hold count for deletion happened.
}

=head2 $foo_data_table->count_entry($title, $record)

After creating database, if you need to count number of entries for specific record,
use this method. In above example if you want to count how many test
are passed use this method. It takes 2 arguments. One is title. You can find
entry using any title. In our example I will count entry using title "Status".
2ns argument is actual record. In our example I would like count entries with 
record as Pass. I will use below code as my example.

	my $status = $foo_data_table->count_entry("Status", "Pass");

This code will search pattern "Pass" under "Status" in your database and count 
all matched entries. This method will return number of matched entries. If it did
not find above pattern in your database, it will return 0.

=cut

sub count_entry {
	my $this = shift;
	my $count = 0;
	my $field_name = shift;			# Title.
	my $record = shift;			# Record needs manipulation.
	my @all_fields;				# Holds all the titles.
	my @database_line;			# Holds data table lines.
	my $given_field_index;			# Index of the titles to the @all_fields.

	#
	# Open database file
	#
	open(DT, "<" , $this->{'l_o_f'}) or _die($this, "Failed to open up data table file $!");
	
	while(<DT>) {
		@all_fields = split(/$this->{'delimiter'}/, $_);
		last;
	}

	#
	# Remove head and trail white spaces
	#
	map { s/^\s*(\w*.*\w)\s*$/$1/ } @all_fields;
	map { s/^\s+$/ / } @all_fields;

	#
	# Give sanity on users data
	#
	_die($this, "The field \"${field_name}\" does not exist in list \"@{all_fields}\"") unless (grep(/^$field_name$/,@all_fields));

	#
	# Search for index of field_name
	#
	foreach (0 .. $#all_fields) {
		($given_field_index = $_) if ( $all_fields[$_] eq $field_name );
	}

	#
	# Search for the record
	#
	while (<DT>) {
		if ($_ =~ m/$record/) {
			@database_line = split(/$this->{'delimiter'}/, $_);
			map { s/^\s*(\w*.*\w)\s*$/$1/ } @database_line;
						# Remove trailing and heading white spaces.
			map { s/^\s+$/ / } @database_line;
						# Remove multiple spaces.
			if ($database_line[$given_field_index] eq $record) {
				++$count;
			}
		}
	}
	close(DT);
	return $count;
}

=head2 $foo_data_table->get_entry($title, $record, [$title_of_needed_data])

After creating database, if you need to get a particular entry from the database
use this method. This method will take 3 arguments. 1st argument is title. For 
example you want to get entry for column "Number". Use "Number as your 1st arguement.
2nd arguement will be record. For example you want to get entry for Column "Number"
with "7". Use "7" as your 2nd arguement.  In our example this method will go to 
database and get complete entry for the column "Number" == "7". This will return 
as a list. List will contain all the record of column "Number" with 7. If it finds
multiple entries, this method will fetch all and return to you as a list.

	my @data = foo_data_table->get_entry("Number", 7);


If we need only specific data then also specify 3rd arguement, which is title to
be needed. For example If you want "Status" of "Number" == "7". Use title "Status
as your 3rd arguement. This will retun a scalar value. This will be 1st matched 
pattern. If you have multiple entries pass only 2 arguments as above.

	my $status = foo_data_table->get_entry("Number", 7, "Status");

This will return value stored under "Status" whose "Number" is 7.

=cut

sub get_entry {
	my $this = shift;
	my $field_name = shift;			# Title.
	my $record = shift;			# Record needs manipulation.
	my $specific_field = shift if @_;	# Query title.
	my @all_fields;				# Holds all the titles.
	my @database_line;			# Holds data table lines.
	my $given_field_index;			# Index of the titles to the @all_fields.
	my $searching_field_index;		# Index of the titles to the @all_fields.
	my @record_found;			# Holds matched pattern.

	#
	# Open database file.
	#
	open(DT, "<" , $this->{'l_o_f'}) or _die($this, "Failed to open up data table file $!");
	while(<DT>) {
		@all_fields = split(/$this->{'delimiter'}/, $_);
		last;
	}

	#
	# Remove head and trail white spaces.
	#
	map { s/^\s*(\w*.*\w)\s*$/$1/ } @all_fields;
	map { s/^\s+$/ / } @all_fields;

	#
	# Give sanity on users data.
	#
	_die($this, "The field \"${field_name}\" does not exist in list \"@{all_fields}\"") unless (grep(/^$field_name$/,@all_fields));
	_die($this, "The field \"${specific_field}\" does not exist in list \"@{all_fields}\"") if (defined $specific_field  && ! grep(/^$specific_field$/,@all_fields));
	_die($this, "The given field name \"${field_name}\" can not be same as searching field name\"${specific_field}\"") if (defined $specific_field && ($specific_field eq $field_name));

	#
	# Search for index of field_name.
	#
	foreach (0 .. $#all_fields) {
		($given_field_index = $_) if ( $all_fields[$_] eq $field_name );
	}

	#
	# Search for index of specific_field.
	#
	if(defined $specific_field) {
		foreach (0 .. $#all_fields) {
			$searching_field_index = $_ if ( $all_fields[$_] eq $specific_field );
		}
	}

	#
	# Search for the record.
	#
	while (<DT>) {
		if ($_ =~ m/$record/) {
			@database_line = split(/$this->{'delimiter'}/, $_);
			map { s/^\s*(\w*.*\w)\s*$/$1/ } @database_line;
						# Remove trailing and heading white spaces.
			map { s/^\s+$/ / } @database_line;
						# Remove multiple spaces.
			push (@record_found, @database_line) if ($database_line[$given_field_index] eq $record);
			return ($database_line[$searching_field_index]) if (defined $specific_field && $database_line[$given_field_index] eq $record);
		}
	}
	close(DT);
	return @record_found;
}

=head2 $foo_data_table->get_table()

This method does not take any arguments. This method will return complete database
in list. 

	my @database = $foo_data_table->get_table();
=cut

sub get_table {
	my $this = shift;
	my @database_lines;			# This will hold all the records.

	#
	# Open database file in read mode and read the entire file.
	#
	open(DT, "<" , $this->{'l_o_f'}) or _die($this, "Failed to open up data table file $!");
	while(<DT>) {
		last;
	}

	#
	# Search for the record.
	#
	@database_lines = <DT>;
	close(DT);
	return @database_lines;
}

=head2 $foo_data_table->get_titles()

This method does not take any arguments. This method will return all the titles
of the database.

	my @database = $foo_data_table->get_titles();
=cut

sub get_titles {
	my $this = shift;
	my @all_fields;				# Holds all the titles.

	#
	# Open database file.
	#
	open(DT, "<" , $this->{'l_o_f'}) or _die($this, "Failed to open up data table file $!");
	while(<DT>) {
		@all_fields = split(/$this->{'delimiter'}/, $_);
		last;
	}

	#
	# Remove head and trail white spaces.
	#
	map { s/^\s*(\w*.*\w)\s*$/$1/ } @all_fields;
	map { s/^\s+$/ / } @all_fields;

	#
	# Close the opened file.
	close(DT);
	return @all_fields;			# return all the titles.
}

#
# Internal method:
# _test_unique_fields()
#	All fields must be unique.
#
sub _test_unique_fields {
	my @fields = @_;
	my $count = 0;
	my $pattern;

	#
	# Die if the fields are not unique.
	#
	while ($pattern = pop @fields) {
		foreach my $field (@fields) {
			die "Field name has to be unique. \"${pattern}\" is not unique in list: \"@{_}\"" if ($field eq $pattern);
		}
	}
}

#
# _die()
#	die if it is enable.
#
sub _die {
	my $this = shift;
	my $msg = shift;
	
	#
	# Die if it is enable through user else warn user and return negative value.
	#
	if($this->{'die'} == 1) {
		die "Fatal error: $msg\n";
	} else {
		warn "Error: $msg\n";
		return -1;
	}
}

#
# Internal method:
# DESTROY()
#	Destructor of the class.
#
sub DESTROY {
	my $this = shift;
}

=head1 AUTHOR

Devang Doshi, C<< <devdos at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-database-format-text at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Format-Text>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Database::Format::Text


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Database-Format-Text>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Database-Format-Text>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Database-Format-Text>

=item * Search CPAN

L<http://search.cpan.org/dist/Database-Format-Text/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Devang Doshi.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Database::Format::Text
