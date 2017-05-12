=pod

=head1 NAME

DB_File::DB_Database - Perl module for reading and writing the DB_File data as a mutifield table 
with index file supported.

=cut

# ############
package DB_File::DB_Database;

use 5.004;
use strict;
use DB_File;
use Fcntl qw( O_RDWR O_RDONLY LOCK_SH LOCK_EX LOCK_UN);
# ##############
# General things

use vars qw( $VERSION $errstr @ISA );
$VERSION = 0.031;
# Sets the debug level
$DB_File::DB_Database::DEBUG = 0;
BEGIN {
	if ($^O =~ /mswin/i) { $DB_File::DB_Database::LOCKING = 0; }
	else { $DB_File::DB_Database::LOCKING = 1; }
	require IO::File if( $DB_File::DB_Database::LOCKING );
}

# print "true_close\n" if ($DB_File::DB_Database::DEBUG);

# ###############################################################################
# Build the object in the memory, open the file
sub new	{
	__PACKAGE__->NullError();
	my $class = shift;
	my $new = bless {}, $class;
	if (@_ and not $new->open(@_)) { return; }
	return $new;
}

# ###############################################################################
# Open the specified file.
sub open {
	my ($self) = shift;
	my %options;
	if (scalar(@_) % 2) { $options{'name'} = shift; }	
	$self->{'DataBase'}->{'OpenOptions'} = { %options, @_ };

	my %locoptions;
	@locoptions{ qw( name readonly ) } = @{$self->{'DataBase'}->{'OpenOptions'}}{ qw( name readonly ) };
	my $FileName = $locoptions{'name'};
	for my $ext ('', '.db') {
		if (-f $FileName.$ext) {
			$locoptions{'name'} = $FileName.$ext;
			$self->NullError();
			return $self->real_open(%locoptions);
		}
	}
	$locoptions{'name'} = $FileName;
	return $self->real_open(%locoptions);	# for nice error message
}
# ###############################################################################
# Close the file (and memo)
sub close {
	my $self = shift;
	$self->real_close;
	$self->real_close_index( keys %{$self->{'Index'}} );
}

# ###############################################################################
# Creating new file
sub create {
	__PACKAGE__->NullError();
	my $class = shift;
	my %options = @_;
	if (ref $class) {
		%options = ( %$class, %options ); $class = ref $class;
	}
	
	$options{'permits'}=0640 unless ( $options{'permits'} );
	my $key;
	for $key ( qw( name field_names ) ) {
		if (not defined $options{$key}) {
			__PACKAGE__->Error("Create Failed: Tag $key must be specified when creating new table\n");
			return;
		}
	}
	if (-f $options{'name'}) {
		__PACKAGE__->Error("Taget File already exists\n");
		return;
	}
	$options{'field_names'} = $class->check_field_names($options{'field_names'});
	$options{'field_types'} = $class->check_field_types($options{'field_types'}, scalar(@{$options{'field_names'}}));

	my $tmp = $class->new();
	$tmp->real_create(%options) or return;
	$tmp->close();

	return $class->new($options{'name'});
}
# ###############################################################################
# check_field_names
sub check_field_names {
	my ($self, $fields_name)  = ( shift, shift );
	my @fields_name = ref $fields_name ? @$fields_name : ();
	my @return_fields_name;
	my $i = 0;
	my %fields_name;
	while ( $i < scalar(@fields_name) ) {
		$fields_name[$i] = uc $fields_name[$i];
		# if the same field names appears
		if (not $fields_name{ $fields_name[$i] } ) {
			push ( @return_fields_name, $fields_name[$i] );
		}
		$fields_name{ $fields_name[$i] } = 1;
		$i++;
	}
	return \@return_fields_name;
}
# ###############################################################################
# check_field_types
sub check_field_types {
	my ($self, $fields_type)  = ( shift, shift );
	my @fields_type = ref $fields_type ? @$fields_type : ();
	my $num = shift;
	$num = scalar(@fields_type) if not defined $num;
	my $i = 0;
	while ( $i < $num ) {
		$fields_type[$i] = uc substr($fields_type[$i],0,1);
		# set default type
		if ( $fields_type[$i] ne 'C' and $fields_type[$i] ne 'N') {
			$fields_type[$i] = 'C';
		}
		$i++;
	}
	return \@fields_type;
}
# ###############################################################################
# check_field_names_hash
sub check_field_names_hash {
	my $self = shift;
	my @fields_name_hash = @_;
	my $i = 0;
	while ( $i < scalar(@fields_name_hash) ) {
		$fields_name_hash[$i] = uc $fields_name_hash[$i];
		$i+=2;
	}
	return @fields_name_hash;
}
# ###############################################################################
# Drop the table
sub drop {
	my $self = shift;
	$self->drop_index(keys %{$self->{'Index'}});
	return $self->real_drop();
}
# ###############################################################################
# List of field names, types, lengths and decimals
sub field_names	{ @{shift->{'DataBase'}->{'data_field_names'}}; }
sub field_types	{ @{shift->{'DataBase'}->{'data_field_types'}}; }
sub field_name_to_num { my ($self, $name) = @_; $self->{'DataBase'}->{'data_field_names_hash'}->{uc $name}; }
sub rows	{ shift->{'DataBase'}->{'rows'}; }
sub select_hits	{ shift->{'Select'}->{'Result_Num'}; }



# ###############################################################################
# Reading the records
# Returns fields of the specified record; optionally names of the required
# fields. If no names are specified, all fields are returned. Returns
# empty list on error.
sub get_record {
	my ($self, $id) = (shift, shift);
	return unless ( $id = $self->check_for_select($id) );
	$self->get_record_nf( $id, map { $self->field_name_to_num($_); } @_ );
}
# ###############################################################################
sub get_record_hash {
	my ($self, $id) = @_;
	return unless ( $id = $self->check_for_select($id) );
	my @data = $self->get_record_nf($id) or return;
	my $hash = {};
	@{$hash}{ ('__ID', $self->field_names) } = @data;
	return %$hash if wantarray;
	$hash;
}
# ###############################################################################
sub get_record_nf {
	my ($self, $id, @fieldnums) = @_;
	return unless ( $id = $self->check_for_select($id) );
	my $data = $self->real_read_record($id) or return;
	return ($id, @$data) if (not @fieldnums);

	my @return_data = ($id);
	foreach ( @fieldnums ) {
		push (@return_data, @$data[$_] );
	}
	return @return_data;
}
# ###############################################################################
# Actually read the data 
sub real_read_record {
	my ($self, $id) = (shift, shift);
	return if (not $self->{'DataBase'}->{'db'}->{$id} );
	$self->csv_prase( $self->{'DataBase'}->{'db'}->{$id} );
}
# ###############################################################################
sub check_for_select {
	my ($self, $id) = @_;
	if ( not defined $id ) {
		$id = shift ( @{$self->{'Select'}->{'Result'}} );
		return undef if not defined $id;
	}
	$id;
}





# ###############################################################################
# Write record, values of the fields are in the argument list.
sub set_record {
	my ($self, $id, @data) = @_;
	$self->real_write_record($id, @data);
}
# ###############################################################################
# Write record, fields are specified as hash, unspecified are set to undef/empty
sub set_record_hash {
	my ($self, $id) = (shift,shift);
	my %data = $self->check_field_names_hash(@_);
	$self->set_record($id, map { $data{$_} } $self->field_names );
}
# ###############################################################################
# Write record, fields specified as hash, unspecified will be unchanged
sub update_record_hash {
	my ($self, $id) = ( shift, shift );
	my %olddata = $self->get_record_hash($id);
	return unless %olddata;
	$self->set_record_hash($id, %olddata, @_);
}
# ###############################################################################
# Write record, values of the fields are in the argument list.
sub append_record {
	my ($self, @data) = @_;
	$self->real_write_record(undef, @data);
}
# ###############################################################################
# Write record, fields are specified as hash, unspecified are set to undef/empty
sub append_record_hash {
	my $self = shift;
	my %data = $self->check_field_names_hash(@_);
	$self->append_record( map { $data{$_} } $self->field_names );
}
# ###############################################################################
# Actually write the data (@newdata = undef means delete record)
sub real_write_record {
	my ($self, $id) = (shift, shift);
	$id = $self->{'DataBase'}->{'LastRecord'}+1 if (not defined $id);
	my @newdata = @_;
	my $olddata;
	if ( $self->{'DataBase'}->{'rw'} ) {
		$olddata = $self->real_read_record($id) if (defined $self->{'DataBase'}->{'db'}->{$id});
		my ($tagname, $key);
		my ($oldindex,$newindex);
		while ( ($tagname,$key) = each (%{$self->{'Index'}}) ) {
#print "\nOldIndex: ";
			$oldindex = $self->get_index_string($tagname, $olddata);
#print "\nNewIndex: ";
			$newindex = $self->get_index_string($tagname, \@newdata);
#			$DB_BTREE->{'compare'} = $self->get_compare_sub('index' => $tagname);
			if ( not @newdata or $oldindex ne $newindex ) {
				$self->real_delete_index_record( $tagname, $oldindex, $id ) if (defined $self->{'DataBase'}->{'db'}->{$id});
				$self->real_insert_index_record( $tagname, $newindex, $id ) if ( @newdata );
			}
		}
		if ( scalar(@newdata) ) {
			$self->{'DataBase'}->{'db'}->{$id} = $self->csv_combine(@newdata);
			$self->{'DataBase'}->{'db'}->{'__Total_Records'} ++;
			if( int($id) > $self->{'DataBase'}->{'LastRecord'} ) {
				$self->{'DataBase'}->{'db'}->{'__Last_Record'} = int($id);
				$self->{'DataBase'}->{'LastRecord'} = int($id);
			}
		}else {
			return if (not defined $self->{'DataBase'}->{'db'}->{$id});
			delete $self->{'DataBase'}->{'db'}->{$id};
			$self->{'DataBase'}->{'db'}->{'__Total_Records'} --;
		}
	}else {
		$self->Error("Writing Record Failed: File is opened only for reading.\n");
		return;
	}
	$id;
}

# ###############################################################################
# Delete record
sub delete_record {
	my ($self, @id) = @_;
	my $id;
	my $num = 0;
	foreach $id (@id) {
		$num++ if ( $self->real_write_record( $id ) );
	}
	$num;
}




sub get_hashref	{ shift->{'db'} }








# ###############################################################################
# Open the specified file.
sub real_create {
	print "true_create\n" if ($DB_File::DB_Database::DEBUG);
	my $self = shift;
	my %options = @_;
	if (defined $self->{'DataBase'}->{'db'}) { $self->close(); }

	my %db;
	if( tie %db, "DB_File", $options{'name'}, O_CREAT|O_RDWR, $options{'permits'}, $DB_HASH) {
		$db{'__Version'} = $VERSION;
		$db{'__Last_Record'} = 0;
		$db{'__Total_Records'} = 0;
		$db{'__Field_names'} = $self->csv_combine(@{$options{'field_names'}});
		$db{'__Field_types'} = $self->csv_combine(@{$options{'field_types'}});
	}else{
		$self->Error("Error opening file $options{'name'}: $!\n");
		return;
	}
	1;	# success
}
# ###############################################################################
# Drop (unlink) the file
sub real_drop {
	my $self = shift;
	$self->NullError();
	if (defined $self->{'DataBase'}->{'FileName'}) {
		my $FileName = $self->{'DataBase'}->{'FileName'};
		$self->close() if defined $self->{'DataBase'}->{'db'};
		if (not unlink $FileName)
			{ $self->Error("Error unlinking file $FileName: $!\n"); return; };
		}
	1;	
}

# ###############################################################################
# Open the specified file.
sub real_open {
	my $self = shift;
	my %options = @_;
	if (defined $self->{'DataBase'}->{'db'} 
		and ( $self->{'DataBase'}->{'FileName'} ne $options{'name'}
			or $self->{'DataBase'}->{'rw'} eq $options{'readonly'} )) { $self->close(); }

	my %db;
	my $fh;
	my $rw = 0;
	my $ok = 0;
	my $lock = 0;
	if (not $options{'readonly'}) {
		if( $fh = tie %db, "DB_File", $options{'name'}, O_RDWR, 0640, $DB_HASH) {
			$rw = 1; $ok = 1;
		}
	}else {
		if( $fh = tie %db, "DB_File", $options{'name'}, O_RDONLY, 0640, $DB_HASH) {
			$rw = 0; $ok = 1;
		}
	}
	if (not $ok) {
		$self->Error("Error opening file $options{'name'}: $!\n");
		return;
	}
	@{$self->{'DataBase'}}{ qw( fh db FileName rw ) } = ($fh, \%db, $options{'name'}, $rw);
	$self->{'DataBase'}->{'lockfh'} = $self->database_lock ( 'FileName'	=> $self->{'DataBase'}->{'FileName'} ,
						   'rw'		=> $self->{'DataBase'}->{'rw'} ,
						   'permits'	=> 0640 );
	$self->read_head;
	$self->real_open_index;
}
# ###############################################################################
# Open the specified file.
sub real_open_index {
	print "open_index\n" if ($DB_File::DB_Database::DEBUG);
	my $self = shift;
	my ($tag_name,$tag_info);
	
	while ( ($tag_name,$tag_info) = each( %{$self->{'Index'}}) ) {
		my $recreate = 0;
		if (not -f $tag_info->{'FileName'}) {
			$self->Error("Warning: Can't find Index file ".$tag_info->{'FileName'}." , ReCreated it.\n");
			$recreate = 1;
			$self->real_create_index('tag'		=> $tag_name ,
						 'FileName' 	=> $tag_info->{'FileName'} ,
						 'key'		=> $tag_info->{'key'} ,
						 'compare'	=> $self->get_compare_sub('index' => $tag_name),
				 		 'permits'	=> 0640 );
		}
		my %db;
		my $fh;
		my $rw = 0;
		my $ok = 0;
		my $lock = 0;
		$DB_BTREE->{'flags'} = R_DUP;
		$DB_BTREE->{'compare'} = $self->get_compare_sub('index' => $tag_name);
		if ( $self->{'DataBase'}->{'rw'} ) {
			if( $fh = tie %db, "DB_File", $tag_info->{'FileName'}, O_RDWR, 0640, $DB_BTREE) {
				$rw = 1; $ok = 1;
			}
		}else {
			if( $fh = tie %db, "DB_File", $tag_info->{'FileName'}, O_RDONLY, 0640, $DB_BTREE) {
				$rw = 0; $ok = 1;
			}
		}
		if (not $ok) {
			$self->Error("Error opening Index file ".$tag_info->{'FileName'}.": $!\n");
			return;
		}
		@{$tag_info}{ qw( fh db rw ) } = ($fh, \%db, $rw);
		$tag_info->{'lockfh'} = $self->database_lock (  'FileName'	=> $tag_info->{'FileName'} ,
								'rw'		=> $self->{'DataBase'}->{'rw'} ,
								'permits'	=> 0640 );
		$self->recreate_index( $tag_name ) if $recreate;
	}
	1;
}
# ###############################################################################
# Open the specified file.
sub read_head {
	my $self = shift;
	if (not defined $self->{'DataBase'}->{'db'}) { $self->close();return; }
	
	my $db = $self->{'DataBase'}->{'db'};
	my ( $data_version, $rows, $data_structure_raw, $data_fieldtype_raw, $index_raw, $index_keyfield_raw)
			= ($db->{'__Version'}, $db->{'__Total_Records'}, $db->{'__Field_names'}, $db->{'__Field_types'}, $db->{'__Index'}, $db->{'__IndexKeyField'});
	if (not ($data_version and $data_structure_raw) ) {
		$self->close();
		$self->Error("DATA Version Error: This file is not normally created by DB_File::DB_Database.\n"); return;
		return;
	}
	my $data_structure = $self->csv_prase($data_structure_raw);
	my $data_fieldtype = $self->csv_prase($data_fieldtype_raw);
	# set fields no to hash
	my %data_structure_hash;
	foreach (0 .. scalar(@$data_structure)-1) {
		$data_structure_hash{ @$data_structure[$_] } = $_;
	}
	@{$self->{'DataBase'}}{ qw( data_version rows data_field_names data_field_types data_field_names_hash LastRecord ) }
			 = ($data_version, $rows, $data_structure, $data_fieldtype, \%data_structure_hash, $db->{'__Last_Record'} );
	# set index tags
	my $index_tag = $self->csv_prase($index_raw);
	my $index_keyfield = $self->csv_prase($index_keyfield_raw);
	foreach (0 .. scalar(@$index_tag)-1) {
		$self->{'Index'}->{ @$index_tag[$_] } = { 'FileName' => $self->{'DataBase'}->{'FileName'}.'_'.@$index_tag[$_] ,
							  'KeyField' => @$index_keyfield[$_] ,
							  'KeyField_type'=> ($self->field_types)[ $self->field_name_to_num(@$index_keyfield[$_]) ] };
	}
	1;
}
# ###############################################################################
# Close the file 
sub real_close {
	print "real_close\n" if ($DB_File::DB_Database::DEBUG);
	my $self = shift;
	$self->database_unlock( 'lockfh' => $self->{'DataBase'}->{'lockfh'} );
	undef $self->{'DataBase'}->{'fh'};
	untie %{$self->{'DataBase'}->{'db'}};
	delete $self->{'DataBase'};
}

# ###############################################################################
sub errstr { 
	my $self = shift;
	return 	( ref $self ? $self->{'errstr'} : $DB_File::DB_Database::errstr );
}
# ###############################################################################
# Set errstr if there is debug level
sub Error {
	my $self = shift;
	( ref $self ? $self->{'errstr'} : $DB_File::DB_Database::errstr ) .= join '', @_;
#	print @_ if ($DB_File::DB_Database::DEBUG);
}
# ###############################################################################
# Null the errstr
sub NullError
	{ shift->Error(''); }



# ###############################################################################
# Dump
sub dump_all {
	my $self = shift;
	use Data::Dumper; $Data::Dumper::Indent=1;
	print &Data::Dumper::Dumper($self);
	1;	# return true since everything went fine
}
# ###############################################################################
# Dump
sub dump_data {
	my $self = shift;

	my $i = 0;
	my @field_names = $self->field_names;
	my @field_types = $self->field_types;
	print "\n";
	print "Data File Name: ".$self->{'DataBase'}->{'FileName'}." \n";
	print " DataVersion  : ".$self->{'DataBase'}->{'data_version'}."\n";
	print " Privility    : Read ".($self->{'DataBase'}->{'rw'} ? "and Write" : "Only")."\n";
	print " Locking      : ".($self->{'DataBase'}->{'lockfh'} ? "" : "Not ")."Locked\n";
	print "   ID    ->   "."@field_names "."\n";
	print "              "."@field_types "."\n";
	print " Table Data   :\n";
	my ($key, $content_raw, $content, $status);
	while ( ($key, $content_raw) = each( %{$self->{'DataBase'}->{'db'}} ) ) {
		if (not $key =~ /^__/ ) {
			$content = $self->csv_prase($content_raw);
			print "   $key    ->   "."@$content "."\n";
			$i++;
		}
	}
	print " Totally      : $i Recrods\n";

	my $x;
	foreach $_ ( keys %{$self->{'Index'}} ) {
		print "\n";
		print "Index $_\n";
		print " Index File Name: ".$self->{'Index'}->{$_}->{'FileName'}."\n";
		print " Privility      : Read ".($self->{'Index'}->{$_}->{'rw'} ? "and Write" : "Only")."\n";
		print " Locking        : ".($self->{'Index'}->{$_}->{'lockfh'} ? "" : "Not ")."Locked\n";
		print " KeyField       : ".$self->{'Index'}->{$_}->{'KeyField'}."\n";
		print " Index Content  :\n";
		$i = 0;
		$x = $self->{'Index'}->{ $_ }->{'fh'};
		$key = $content = 0;
		for ($status = $x->seq($key, $content, R_FIRST) ;	$status == 0 ; $status = $x->seq($key, $content, R_NEXT) ) {
			print "   $key -> $content\n";
			$i++;
		}
		print " Totally        : $i Recrods\n";
	}
	1;	# return true since everything went fine
}
# ###############################################################################
# Dump
sub dump {
	my $self = shift;
	use Data::Dumper; $Data::Dumper::Indent=1;
	print &Data::Dumper::Dumper(shift);
	1;	# return true since everything went fine
}
# ###############################################################################
# CSV string to columns
sub csv_prase {
	my $self = shift;
	my $string = shift;
	my $result = [];
	return $result unless ( $string );
	$string=','.$string.',';
	@$result =($string=~ /,("(?:[^"]|(?:[^"]*?""))*?"|[^"]*?)(?=,)/mg);
	foreach(0..scalar(@$result)-1) {
 		$result->[$_]=~ s/\A"|"\Z//g;
 		$result->[$_]=~ s/""/"/g;
	}
	return $result;
}
# ###############################################################################
# columns to CSV string
sub csv_combine {
	my $self = shift;
	my @content = @_;
	foreach (0..scalar(@content)-1) {
		$content[$_]=~ s/"/""/g;
		$content[$_]="\"$content[$_]\"" if($content[$_]);
	}
	return join(',',@content);
}
# ###############################################################################
# Lcok 
sub database_lock {
	my $self = shift;
	my %options = @_;
	my $lock = 0;
	my $lockfile = $options{'FileName'}.'.lock';
	if ( $DB_File::DB_Database::LOCKING ) {
		my $fh = new IO::File;
		if ( not $fh->open($lockfile, O_CREAT|O_RDWR, $options{'permits'}) ) {
			$self->Error("Error occur when making lock file $lockfile: $!.\n");
			return;
		}
		if ( $options{'rw'} ) {
			if ( $self->_lockex($fh) ) {
				print "lockex_success\n" if ($DB_File::DB_Database::DEBUG);
				$lock = 1;
			}else {
				$self->Error("Error occur when locking (for read & write) the lock file: $!.\n");
				return;
			}
		}else {
			if ( $self->_locksh($fh) ) {
				print "locksh_success\n" if ($DB_File::DB_Database::DEBUG);
				$lock = 1;
			}else {
				$self->Error("Error occur when locking (for read) the lock file: $!.\n");
				return;
			}
		}
		return $fh;
	}
	return;
}
# ###############################################################################
# Unlcok 
sub database_unlock {
	my $self = shift;
	my %options = @_;
	my $lockfh = $options{'lockfh'};
	if ( $lockfh ) {
		if ( $self->_unlock($lockfh) ) {
			print "unlock_success\n" if ($DB_File::DB_Database::DEBUG);
			$lockfh->close;
		}else {
			$self->Error("Error occur when unlocking the lock file: $!.\n");
			return;
		}
	}
	1;
}
#
#sub _locksh	{ flock(shift, LOCK_SH); }
#sub _lockex	{ flock(shift, LOCK_EX); }
#sub _unlock	{ flock(shift, LOCK_UN); }

sub _locksh	{ 1; }
sub _lockex	{ 1; }
sub _unlock	{ 1; }





# ###############################################################################
# Compare sub maker
sub get_compare_sub {
	my $self = shift;
	my %options = @_;
	
	my $compare_sub;
	if ( defined $options{'index'} ) {
		$options{'key'} = $self->{'Index'}->{ $options{'index'} }->{'KeyField'};
	}
	if( defined $options{'type'} ) {
		if ( $options{'type'} eq 'N' ) {
			$compare_sub = sub {
				$_[0] <=> $_[1];
			}
		}else {
			$compare_sub = sub {
				$_[0] cmp $_[1];
			}
		}
	}elsif( defined $options{'key'} ) {	# eg. key => 'ID(10)+-Age(2)'
		my @key = split(/\+/,$options{'key'});
		my ($key, $type, $length, $reverse);
		my $position = 0;
		my $code = "\$compare_sub = sub {\n";
		foreach $key (@key) {
			($key, $length) = split(/\(/,$key);
			$reverse = ($key =~ s/^-//g);
			($length) = split(/\)/,$length);
			if (defined $length) { $length = ",$length"; }
			$type = $self->{'DataBase'}->{'data_field_types'}->[ $self->field_name_to_num($key) ];
#			print ($key, $type, $length, $reverse);
			if ($reverse) { $code .= "substr(\$_[1],$position$length)"; }
				else  { $code .= "substr(\$_[0],$position$length)"; }
			if ($type eq 'N' ) { $code .= ' <=> '; }
				else	   { $code .= ' cmp '; }
			if ($reverse) { $code .= "substr(\$_[0],$position$length)"; }
				else  { $code .= "substr(\$_[1],$position$length)"; }
			$code .= "\n     or     \n";
			$position += $length;
		}
		$code .= "     0\;\n}\;";
		eval($code);
	}
	$compare_sub;
}

# ###############################################################################
# make index keywords
sub get_index_string {
	my $self = shift;
	my ($tag_name, $dataref) = @_;
	return if(not defined $self->{'Index'}->{ $tag_name } );
	
		my @key = split(/\+/,$self->{'Index'}->{ $tag_name }->{'KeyField'});
		my ($key, $length, $reverse);
		my $result;
		foreach $key (@key) {
			($key, $length) = split(/\(/,$key);
			$reverse = ($key =~ s/^-//g);
			($length) = split(/\)/,$length);
			$length = int $length;
			if ($length) {
				$result .= sprintf("%${length}s", $dataref->[ $self->field_name_to_num($key) ]);
			}else {
				$result .= $dataref->[ $self->field_name_to_num($key) ];
			}
		}
	return $result;
}

# ###############################################################################
# Creating new index
sub create_index {
	my $self = shift;
	my %options = @_;
	return unless (defined $self->{'DataBase'}->{'db'} and $self->{'DataBase'}->{'rw'});
	return unless (defined $options{'name'} and defined $options{'key'});

	my $tag_name = uc $options{'name'};
	$options{'permits'} = 0640 unless ( $options{'permits'} );

	my %createoptions = (	'tag'		=> $tag_name ,
				'FileName' 	=> $self->{'DataBase'}->{'FileName'}.'_'.$tag_name ,
				'key'		=> uc $options{'key'} ,
				'compare'	=> $self->get_compare_sub('key' => uc $options{'key'}), #	'type' => $self->{'DataBase'}->{'data_field_types'}->[ $self->field_name_to_num($options{'key'}) ]
				'permits'	=> $options{'permits'} );
	if (-f $createoptions{'FileName'} or defined $self->{'Index'}->{$tag_name}) {
		$self->Error("Taget Index File '$createoptions{'FileName'}' already exists.\n");
		return;
	}
	$self->real_create_index(%createoptions) or return;

	my @index_tags;
	my @index_keyfields;
	my ($other_tag_name,$key);
	while ( ($other_tag_name,$key) = each (%{$self->{'Index'}}) ) {
		push (@index_tags, $other_tag_name);
		push (@index_keyfields, $key->{'KeyField'});
	}
	push (@index_tags, $tag_name);
	push (@index_keyfields, $createoptions{'key'});
	$self->{'DataBase'}->{'db'}->{'__Index'} = $self->csv_combine(@index_tags);
	$self->{'DataBase'}->{'db'}->{'__IndexKeyField'} = $self->csv_combine(@index_keyfields);
	
	$self->close();
	$self->open( %{$self->{'DataBase'}->{'OpenOptions'}} );
	$self->recreate_index( $tag_name );
}
# ###############################################################################
# Open the specified file.
sub real_create_index {
	print "true_create_index\n" if ($DB_File::DB_Database::DEBUG);
	my $self = shift;
	my %options = @_;

	my %db;
	$DB_BTREE->{'flags'} = R_DUP;
	$DB_BTREE->{'compare'} = $options{'compare'};
	if( tie %db, "DB_File", $options{'FileName'}, O_CREAT, $options{'permits'}, $DB_BTREE ) {
		untie %db;
	}else{
		$self->Error("Error creating index file $options{'FileName'}: $!\n");
		return;
	}
	1;	# success
}
# ###############################################################################
# Close the file 
sub real_close_index {
	my $self = shift;
	my @tag_names = @_;
	my $tag_name;
	foreach $tag_name (@tag_names) {
		$self->database_unlock( 'lockfh' => $self->{'Index'}->{$tag_name}->{'lockfh'} );
		untie %{$self->{'Index'}->{$tag_name}->{'db'}};
	}
	delete $self->{'Index'};
}

# ###############################################################################
# Drop the table
sub drop_index {
	my $self = shift;
	my @tag_names = map(uc $_, @_);
	my $tag_name;

	foreach $tag_name (@tag_names) {
		next if( not defined $self->{'Index'}->{$tag_name} );
		$self->real_drop_index( $tag_name );
		delete $self->{'Index'}->{$tag_name};
		delete $self->{'DataBase'}->{'db'}->{'__Index_'.$tag_name};
	}
	my @index_tags;
	my @index_keyfields;
	my ($other_tag_name,$key);
	while ( ($other_tag_name,$key) = each (%{$self->{'Index'}}) ) {
		push (@index_tags, $other_tag_name);
		push (@index_keyfields, $key->{'KeyField'});
	}
	$self->{'DataBase'}->{'db'}->{'__Index'} = $self->csv_combine(@index_tags);
	$self->{'DataBase'}->{'db'}->{'__IndexKeyField'} = $self->csv_combine(@index_keyfields);
}
# ###############################################################################
# Drop (unlink) the file
sub real_drop_index {
	my $self = shift;
	my $tag_name = shift;
	my $FileName = $self->{'Index'}->{$tag_name}->{'FileName'};
	
	undef $self->{'Index'}->{$tag_name};
	
	if (not unlink $FileName)
		{ $self->Error("Error unlinking Index file $FileName: $!\n"); return; };
	1;	
}
# ###############################################################################
# Recreate Index file.
sub recreate_index {
	print "recreate_index\n" if ($DB_File::DB_Database::DEBUG);
	my $self = shift;
	my @tag_names = map(uc $_, @_);
	my $tag_name;
	foreach $tag_name (@tag_names) {
		if( not defined $self->{'Index'}->{$tag_name} ) {
			$self->Error("Index Tag name $tag_name not found.\n");
			next;
		}
		# it has sth wrong: after recreate, should close then open again
		# and i don't know why
		undef %{ $self->{'Index'}->{$tag_name}->{'db'} }; 
#		my @ids = keys %{$self->{'Index'}->{$tag_name}->{'db'}};
#		foreach (0..@ids-1 ) {
#			$self->{'Index'}->{$tag_name}->{'fh'}->del($_);
#			delete $self->{'Index'}->{$tag_name}->{'db'}->{@ids[$_]};
#		}
		my ($key, $content_raw);
		my $content;
		my $indexdata;
		while ( ($key, $content_raw) = each( %{$self->{'DataBase'}->{'db'}} ) ) {
			if (not $key =~ /^__/ ) {
				$content = $self->csv_prase($content_raw);
				$indexdata = $self->get_index_string($tag_name, $content);
				$self->real_insert_index_record( $tag_name, $indexdata, $key );
			}
		}
		$self->dump_all;
	}
	1;	# success
}
# ###############################################################################
# real_delete_index_record
sub real_delete_index_record {
	print "real_delete_index_record\n" if ($DB_File::DB_Database::DEBUG);
	my $self = shift;
	my ( $tag_name, $content, $id ) = @_;
	
	$self->{'Index'}->{$tag_name}->{'fh'}->del_dup($content, $id);
}
# ###############################################################################
# real_insert_index_record
sub real_insert_index_record {
	print "real_insert_index_record\n" if ($DB_File::DB_Database::DEBUG);
	my $self = shift;
	my ( $tag_name, $content, $id ) = @_;
	print "Index insert : $id -> $content\n" if ($DB_File::DB_Database::DEBUG);
#			$DB_BTREE->{'compare'} = $self->get_compare_sub('index' => $tag_name);
	$self->{'Index'}->{$tag_name}->{'db'}->{$content} = $id;
}


# ###############################################################################
# Select the records
# Returns fields of the specified record; optionally names of the required
# fields. If no names are specified, all fields are returned. Returns
# empty list on error.
sub prepare_select {
	my $self = shift;
	my %options = @_;
	if (not defined $self->{'DataBase'}->{'db'} ) {
		$self->Error("Data File Not Opened. $!\n");
		return;
	}
	$self->{'Select'}->{'Result'} = [];
	$self->{'Select'}->{'Result_Num'} = 0;
	my %search = $self->check_field_names_hash(%{$options{'where'}});
	my @search = map { $search{$_} } $self->field_names;
	my @cut;
	if (defined $options{'top'}) {
		@cut = (0, 0, $options{'top'});
	}elsif (defined $options{'cut'}) {
		@cut = (0, @{$options{'cut'}} );
	}else {
		@cut = (0, 0, -1);
	}

	my $id;
	my @content;
	my $i;
	my $ok;
	if (defined $options{'seek'} and defined $options{'seek'}->{'index'}) {
		my $tag = uc $options{'seek'}->{'index'};
		if (not defined $self->{'Index'}->{ $tag }) {
			$self->Error("Index '$tag' Not Exists. \n");
			return;
		}
		
		my ($status, $started);
		my ($from, $to) = ($options{'seek'}->{'from'}, $options{'seek'}->{'to'});
		my $x = $self->{'Index'}->{ $tag }->{'fh'};
		my $compare_sub = $self->get_compare_sub('index' => $tag);
		$id = undef;
		if (defined $from) {	# ?am i right?
			$status = $x->seq($from, $id, R_CURSOR);
			$started = 1;
		}else {
			$status = 0;
			$started = 0;
		}
		while ($status == 0) {
			last if ( defined $options{'seek'}->{'to'} and &$compare_sub($from, $to) == 1 );
			if ($started) {
				$ok = 1;
				if (defined $options{'where'}) {
					(undef, @content) = $self->get_record($id);
					foreach $i ( 0..scalar(@{$self->{'DataBase'}->{'data_field_names'}})-1 ) {
						next if not defined $search[$i];
						if ( $content[$i] !~ /$search[$i]/ ) {
							$ok = 0;
							last;
						}
					}
				}
				if ( $ok ) {
					$cut[0]++;
					last if ( $cut[2] > 0 and $cut[0] > $cut[2] );
					if ( $cut[0] >= $cut[1] ) {
						push ( @{$self->{'Select'}->{'Result'}} , $id );
						$self->{'Select'}->{'Result_Num'}++;
					}
				}
			}else {
				$started = 1;
			}
			$id = undef;
			$status = $x->seq($from, $id, R_NEXT);
		}
	}else {			# no index specified
		foreach $id ( keys %{$self->{'DataBase'}->{'db'}} ) {
			if (not $id =~ /^__/ ) {
				$ok = 1;
				if (defined $options{'where'}) {
					(undef, @content) = $self->get_record($id);
					foreach $i ( 0..scalar(@{$self->{'DataBase'}->{'data_field_names'}})-1 ) {
						next if not defined $search[$i];
						if ( $content[$i] !~ /$search[$i]/ ) {
							$ok = 0;
							last;
						}
					}
				}
				if ( $ok ) {
					$cut[0]++;
					last if ( $cut[2] > 0 and $cut[0] > $cut[2] );
					if ( $cut[0] >= $cut[1] ) {
						push ( @{$self->{'Select'}->{'Result'}} , $id );
						$self->{'Select'}->{'Result_Num'}++;
					}
				}
			}
		}
	}
	1;
}


1;
__END__

=pod

=head1 SYNOPSIS

  use DB_File::DB_Database;
  my $table   = new DB_File::DB_Database "dbexample" or die DB_File::DB_Database->errstr;

  my @data    = $table->get_record("Judy");
  my $hashref = $table->get_record_hash('James');

  $table->append_record("Caroline", "20", "sister");
  $table->append_record_hash('jimmy', "age" => 25,
  $table->set_record("Judy", "18", "a beauty");
  $table->set_record_hash('Roger', "age" => 25,"msg" => 'everything is easy!');
  $table->update_record_hash("Roger", "MSG" => "New message");
  $table->delete_record("Roger");

  $table->prepare_select( "seek"  => {'index'=> 'indexA',
                                      'from' => 10,
                                      'to'   => 25},
                          "where" => {'msg'=> 'hi'},
                          "top"   => 10);
  $table->dump_data;
  $table->close;

=head1 DESCRIPTION

This module can handle DB_File data(DB_HASH, key/value pairs) as a mutifield table. 
It also can create auto updated index files(DB_BTREE) to faster the searching speed. 
It is an Beta version, use it at your own risk.

The following methods are supported by DB_File::DB_Database module:

=head2 General methods

=over 4

=item new

Creates the DB_File::DB_Database object, loads the info about the table form the database file.
The first parameter could be the name of an existing file (table, in fact). 
(A suffix .db will be appended if needed.) This method creates and initializes new object, 
will also open the index files, if needed. 

The parameters can also be specified in the form of hash: value of B<name> is then the 
name of the table, other flags supported are:

B<readonly> open the database file and the index files only for reading

    my $table = new DB_File::DB_Database "dbexample" or die DB_File::DB_Database->errstr;
    my $table = new DB_File::DB_Database "name" => "dbexample","readonly" => 1;

=item open

Same as new method. 

    my $table = new DB_File::DB_Database;
    $table->open ("name" => "dbexample","readonly" => 1) or die DB_File::DB_Database->errstr;

=item close

Closes the object/file, no arguments. 

=item create

Creates new database file on disk and initializes it with 0 records. Parameters to create 
are passed as hash. Each being a reference to list: B<field_names>, B<field_types>. The field types 
are specified by one letter strings (C, N). If you set some value as undefined, create will make 
that field to C. Note that the field type does not actually take effect, it is only used when 
indexing the field. (To know index it as a string or a number.) Please do not use field names 
begin with "__", it is reserved by DB_File::DB_Database. Default permits of the file is 0640. 

    my $newtable = DB_File::DB_Database->create( "name"        => "dbexample",
                                        "field_names" => [ "Age", "MSG" ],
                                        "field_types" => [ "N", "C" ],
                                        'permits'     => 0640 );

The new file mustn't exist yet -- DB_File::DB_Database will not allow you to overwrite existing table. 
Use B<drop> (or unlink) to delete it first.

=item drop

This method closes the table and deletes it on disk (including associated index file, if there is any). 

=item field_names, field_types

Return list of field names and so on for the data file. 

=item rows

Return the sum number of records.

=back

=head2 Using it as key /values(list)

More than key/value pairs, DB_File::DB_Database can make key / values(list) pairs.

=over 4

=item get_record

Returns a list of data (field values) from the specified record (a unique ID of the line,
 not one of the field names). The first parameter in the call is the ID of the record. 
 If you do not specify any other parameters, all fields are returned in the same order 
 as they appear in the file. You can also put list of field names after the record number 
 and then only those will be returned. The first value of the returned list is always 
 the ID of the record. If ID not found, B<get_record> returns empty list. 

=item get_record_nf

Instead if the names of the fields, you can pass list of numbers of the fields to read. 

=item get_record_hash

Returns hash (in list context) or reference to hash (in scalar context) containing 
field values indexed by field names. The only parameter in the call is the ID. 
The field names are returned as uppercase. The unique ID is put in to field name "__ID". 

=back

=head2 Writing the data

On success they return true -- the record ID. Index file is automatical updated, if needed.

=over 4

=item set_record

As parameters, takes the ID of the record and the list of values of the fields. 
It writes the record to the file. Unspecified fields (if you pass less than you should) 
are set to undef/empty. 

=item set_record_hash

Takes number of the record and hash as parameters, sets the fields, unspecified are undefed/emptied. 

=item update_record_hash

Like set_record_hash but fields that do not have value specified in the hash retain their value. 

=item delete_record

Delete the record(s) by the ID(s). Return a number of how many records is deleted.

=back

Examples of reading and writing: 

    $table->set_record("Judy", "18", "a beauty");
    my @data = $table->get_record("Judy");
    my $hashref = $table->get_record_hash('James');
    $table->set_record_hash('Roger', "age" => 25,
                                        "msg" => 'everything is easy!');

This is a code to update field MSG in record where record ID is "Roger".

    use DB_File::DB_Database;
    my $table = new DB_File::DB_Database "dbexample" or die DB_File::DB_Database->errstr;
    my ($id, $age) = $table->get_record("Roger", "age")
    die $table->errstr unless defined $id;
    $table->update_record_hash("Roger", "MSG" => "New message");

=head2 Using it as Table

=over 4

=item get_record 

the same

=item get_record_nf 

the same

=item get_record_hash 

the same

=back 

=head2 Writing the data

=over 4

Basically like above, but do not specify the ID, leave it to DB_File::DB_Database. 
The ID will be sequent numbers.
On success they return true -- the record ID. Index file is automatical updated, if needed.

=item set_record

the same, recommand to use for updating data 

=item set_record_hash

the same, recommand to use for updating data 

=item update_record_hash

the same 

=item delete_record 

the same 

=item append_record 

As parameters, takes the list of values of the fields. It append the record to the file. 
Unspecified fields (if you pass less than you should) are set to undef/empty. 
ID will be returned. 

=item append_record_hash 

Unspecified fields (if you pass less than you should) are set to undef/empty. 
ID will be returned. 

=back 

Examples: 

    $table->append_record("Caroline", "20", "sister");
    $table->append_record_hash('jimmy', "age" => 25,
                                        "msg" => 'Nothing is easy!');

=head2 Using Index

=over 4

Index file is stored in DB_File BTREE. Once created, all index files will be automatically 
opened when open the database file, and updated automatically when writing the database file.

=item create_index 

Create index file for one field. Default permits of the index file is 0640. 'name' is the index 
tag name, 'key' is the formula for indexing. For example:

  'key' => 'Age'            # index by the age, from young to old
  'key' => '-Age'           # index by the age, from old to young
  'key' => '-Age(3)+Name'   # index by the age(up to 999),then name; from old to young,then from A to Z
  'key' => '-Age(3)+-Name'  # index by the age(up to 999),then name; from old to young,then from Z to A

'Age(3)' is similar to 'substr(Age,0,3)', only the length of the last field name appeared in 
the 'key' can be ommited. '+-' CAN'T be subsituded by '-'.

  # Index File name will be dbexample_indexA 
  print $table->create_index( 'name'   => 'indexA' ,
                              'key'    => 'Age' ,       # '-Age' means reverse sort,
                              'permits'=> 0640 );    

=item recreate_index

Recreate the index file. Parameter is the index name(s). 

=item drop_index

Delete the index file. Parameter is the index name(s). 

  # delete Index indexA 
  print $table->drop_index('indexA');  

=back

=head2 Select records

=over 4

Select matched records, using index will speed up the searching.

=item prepare_select

As parameters, pass a hash as parameters. Almost each value is a hash reference. Eg: 
  # find people aged form 10 to 25, select the first 10 people. their 'msg' must content 'hi'
  $table->prepare_select( "seek"  => {'index'=> 'indexA',
                                      'from' => 10,
                                      'to'   => 25},
                          "where" => {'msg'=> 'hi'},
                          "top"   => 10);

If no "seek" specified(do not use index), it will search from the first record to the last(or up to the record numbers you needed)."top" means select the first ? records. You may use "cut" instead, "cut" => [2,6] means select from the secord matched record till to the sixth. 

for "seek", "from" is needed, "to" can be omitted(till the last). 

To fetch the selected record. Use get_record, get_record_nf, get_record_hash, leave the ID undef. 

=back

Examples of selecting record:

    use DB_File::DB_Database;
    my $table = new DB_File::DB_Database "dbexample" or die DB_File::DB_Database->errstr;
    my $table = new XBase "names.dbf" or die XBase->errstr;
    # find people aged form 10 to 25, select the first 10 people. their 'msg' must content 'hi'
    $table->prepare_select( "seek"  => {'index'=> 'indexA',
                                        'from' => 10,
                                        'to'   => 25},
                            "where" => {'msg'=> 'hi'},
                            "top"   => 10);
    while ( @_ = $table->get_record(undef,'age','msg') ){
         ### do something here
         print ++$i,"\n";
         print "@_ ","\n";
    }

=head2 Dumping the content of the file

print the database file records and the index files contenting.

=over 4

=item dump_data 

Record separator, string, newline by default. 

Example of use is

    $table->dump_data;

=item dump_all 

dump the object (only for debuging) (Data::Dump is needed) 

=back

=head2 Error Message

if the method fails (returns false or null list), the error message can be retrieved 
via B<errstr> method. If the new or create method fails, you have no object so you get 
the error message using class syntax DB_File::DB_Database->errstr().

=head1 BUGS

After create_index or recreate_index, file should be closed then open again. 
or something strange will happed.

if you found any bugs or make any patches, I would be appriciate to hear from you.

=head1 INTERNAL DATA TYPES

Use DB_File(DB_HASH) to store data (key/value pairs). Value use a CSV (comma separated
 text) to store a list. No character limits. DB_File::DB_Database do NOT need TEXT::CSV or TEXT::CSV_XS. 
 but you can easily changed it to that modules.

Index files are stored as DB_File (DB_BTREE). Key is the text, value is the ID.

=head1 LOCKING

The locking function is a poor. Every opened file has a '_lock' file(non Windows), No 
locking is done in Windows. 
But to add a locking only need to modify database_lock and database_unlock.

=head1 VERSION

0.031

publish time: 2001.10.22

=head1 AUTHOR

(c) 2001 冉宁煜 / Ran Ningyu, <rny@yahoo.com.cn> http://perl.yesky.net/ or http://www.skybamboo.com/perl/ 
at SouthEast University, Nanjing, China.

All rights reserved. This package is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=head1 SEE ALSO

DB_File

=cut
