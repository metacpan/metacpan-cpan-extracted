
=head1 NAME

XBase::Base - Base input output module for XBase suite

=cut

package XBase::Base;

use strict;
use IO::File;
use Fcntl qw( O_RDWR O_RDONLY );

### I _Realy_ hate to have this code here!
BEGIN { local $^W = 0;
	if ($^O =~ /mswin/i) { eval 'use Fcntl qw( O_BINARY )' }
	else { eval ' sub O_BINARY { 0 } ' }
	}

$XBase::Base::VERSION = '0.129';

# Sets the debug level
$XBase::Base::DEBUG = 0;
sub DEBUG () { $XBase::Base::DEBUG };

my $SEEK_VIA_READ = 0;

# Holds the text of the global error, if there was one
$XBase::Base::errstr = '';
# Fetch the error message
sub errstr ()	{ ( ref $_[0] ? $_[0]->{'errstr'} : $XBase::Base::errstr ); }

# Set errstr and print error on STDERR if there is debug level
sub Error (@)
	{
	my $self = shift;
	( ref $self ? $self->{'errstr'} : $XBase::Base::errstr ) = join '', @_;
	}
# Null the errstr
sub NullError
	{ shift->Error(''); }


# Build the object in the memory, open the file
sub new
	{
	__PACKAGE__->NullError();
	my $class = shift;
	my $new = bless {}, $class;
	if (@_ and not $new->open(@_)) { return; }
	return $new;
	}
# Open the specified file. Use the read_header to load the header data
sub open
	{
	__PACKAGE__->NullError();
	my $self = shift;
	my %options;
	if (scalar(@_) % 2) { $options{'name'} = shift; }
		$self->{'openoptions'} = { %options, @_ };
	%options = (%options, @_);
	if (defined $self->{'fh'}) { $self->close(); }

	my $fh = new IO::File;
	my $rw;
	
	if ($options{'name'} eq '-')
		{
		$fh->fdopen(fileno(STDIN), 'r');
		$self->{'stream'} = 1;
		SEEK_VIA_READ(1);
		$rw = 0;
		}
	else
		{
		my $ok = 1;
		if (not $options{'readonly'}) {
			if ($fh->open($options{'name'}, O_RDWR|O_BINARY))
				{ $rw = 1; }
			else	{ $ok = 0; }
			}
		if (not $ok) {
			if ($fh->open($options{'name'}, O_RDONLY|O_BINARY))
				{ $rw = 0; $ok = 1; }
			else    { $ok = 0; }
			}
		if (not $ok) {
			__PACKAGE__->Error("Error opening file $options{'name'}: $!\n"); return; }
		}

	$self->{'tell'} = 0 if $SEEK_VIA_READ;
	$fh->autoflush();

	binmode($fh);
	@{$self}{ qw( fh filename rw ) } = ($fh, $options{'name'}, $rw);
	## $self->locksh();

		# read_header should be defined in the derived class
	$self->read_header(@_);
	}
# Close the file
sub close
	{
	my $self = shift;
	$self->NullError();
	if (not defined $self->{'fh'})
		{ $self->Error("Can't close file that is not opened\n"); return; }
	$self->{'fh'}->close();
	delete $self->{'fh'};
	1;
	}
# Read from the filehandle
sub read
	{
	my $self = shift;
	my $fh = $self->{'fh'} or return;
	my $result = $fh->read(@_);
	if (defined $result and defined $self->{'tell'})
		{ $self->{'tell'} += $result; }
	$result;
	}
# Tell the position
sub tell
	{
	my $self = shift;
	if (defined $self->{'tell'})
		{ return $self->{'tell'}; }
	return $self->{'fh'}->tell();
	}
# Drop (unlink) the file
sub drop
	{
	my $self = shift;
	$self->NullError();
	if (defined $self->{'filename'})
		{
		my $filename = $self->{'filename'};
		$self->close() if defined $self->{'fh'};
		if (not unlink $filename)
			{ $self->Error("Error unlinking file $filename: $!\n"); return; };
		}
	1;	
	}

# Create new file
sub create_file
	{
	my $self = shift;
	my ($filename, $perms) = @_;
	if (not defined $filename)
		{ __PACKAGE__->Error("Name has to be specified when creating new file\n"); return; }
	if (-f $filename)
		{ __PACKAGE__->Error("File $filename already exists\n"); return; }

	$perms = 0644 unless defined $perms;
	my $fh = new IO::File;
	$fh->open($filename, 'w+', $perms) or return;
	binmode($fh);
	@{$self}{ qw( fh filename rw ) } = ($fh, $filename, 1);
	return $self;
	}


# Compute the offset of the record
sub get_record_offset
	{
	my ($self, $num) = @_;
	my ($header_len, $record_len) = ($self->{'header_len'},
						$self->{'record_len'});
	unless (defined $header_len and defined $record_len)
		{ $self->Error("Header and record lengths not known in get_record_offset\n"); return; }
	unless (defined $num)
		{ $self->Error("Number of the record must be specified in get_record_offset\n"); return; }
	return $header_len + $num * $record_len;
	}


# Seek to start of the record
sub seek_to_record
	{
	my ($self, $num) = @_;
	defined (my $offset = $self->get_record_offset($num)) or return;
	$self->seek_to($offset);
	}
# Seek to absolute position
sub seek_to_seek
	{
	my ($self, $offset) = @_;
	unless (defined $self->{'fh'})
		{ $self->Error("Cannot seek on unopened file\n"); return; }
	unless ($self->{'fh'}->seek($offset, 0))
		{ $self->Error("Seek error (file $self->{'filename'}, offset $offset): $!\n"); return; };
	1;
	}
sub seek_to_read
	{
	my ($self, $offset) = @_;
	unless (defined $self->{'fh'})
		{ $self->Error("Cannot seek on unopened file\n"); return; }
	my $tell = $self->tell();
	if ($offset < $tell)
		{ $self->Error("Cannot seek backwards without using seek ($offset < $tell)\n"); return; };
	if ($offset > $tell)
		{
		my $undef;
		$self->read($undef, $offset - $tell);
		$tell = $self->tell();
		}
	if ($tell != $offset)
		{ $self->Error("Some error occured during read-seek: $!\n"); return; };
	1;
	}
sub SEEK_VIA_READ
	{
	local $^W = 0;
	if ($_[0])
		{ *seek_to = \&seek_to_read; $SEEK_VIA_READ = 1; }
	else
		{ *seek_to = \&seek_to_seek; $SEEK_VIA_READ = 0; }
	}
SEEK_VIA_READ(0);

# Read the record of given number. The second parameter is the length of
# the record to read. It can be undefined, meaning read the whole record,
# and it can be negative, meaning at most the length
sub read_record
	{
	my ($self, $num, $in_length) = @_;
	if (not defined $num)
		{ $self->Error("Number of the record must be defined when reading it\n"); return; }
	if ($self->last_record > 0 and $num > $self->last_record)
		{ $self->Error("Can't read record $num, there is not so many of them\n"); return; }
	if (not defined $in_length)
		{ $in_length = $self->{'record_len'}; }
	if ($in_length < 0)
		{ $in_length = -$self->{'record_len'}; }

	defined (my $offset = $self->get_record_offset($num)) or return;
	$self->read_from($offset, $in_length);
	}
sub read_from
	{
	my ($self, $offset, $in_length) = @_;
	unless (defined $offset)
		{ $self->Error("Offset to read from must be specified\n"); return; }
	$self->seek_to($offset) or return;
	my $length = $in_length;
	$length = -$length if $length < 0;
	my $buffer;
	my $read = $self->read($buffer, $length);
	if (not defined $read or ($in_length > 0 and $read != $in_length))
		{ $self->Error("Error reading $in_length bytes from $self->{'filename'}\n"); return; }
	$buffer;
	}


# Write the given record
sub write_record
	{
	my ($self, $num) = (shift, shift);
	defined (my $offset = $self->get_record_offset($num)) or return;
	defined $self->write_to($offset, @_) or return;
	$num == 0 ? '0E0' : $num;
	}
# Write data directly to offset
sub write_to
	{
	my ($self, $offset) = (shift, shift);
	if (not $self->{'rw'})
		{ $self->Error("The file $self->{'filename'} is not writable\n"); return; }
	$self->seek_to($offset) or return;
	local ($,, $\) = ('', '');
	$self->{'fh'}->print(@_) or
		do { $self->Error("Error writing to offset $offset in file $self->{'filename'}: $!\n"); return; } ;
	$offset == 0 ? '0E0' : $offset;
	}


sub locksh	{ _locksh(shift->{'fh'}) }
sub lockex	{ _lockex(shift->{'fh'}) }
sub unlock	{ _unlock(shift->{'fh'}) }

sub _locksh	{ flock(shift, 1); }
sub _lockex	{ flock(shift, 2); }
sub _unlock	{ flock(shift, 8); }


1;

__END__

=head1 SYNOPSIS

Used indirectly, via XBase or XBase::Memo.

=head1 DESCRIPTION

This module provides catch-all I/O methods for other XBase classes,
should be used by people creating additional XBase classes/methods.
There is nothing interesting in here for users of the XBase(3) module.
Methods in XBase::Base return nothing (undef) on error and the error
message can be retrieved using the B<errstr> method.

Methods are:

=over 4

=item new

Constructor. Creates the object and if the file name is specified,
opens the file.

=item open

Opens the file and using method read_header reads the header and sets
the object's data structure. The read_header should be defined in the
derived class, there is no default.

=item close

Closes the file, doesn't destroy the object.

=item drop

Unlinks the file.

=item create_file

Creates file of given name. Second (optional) paramater is the
permission specification for the file.

=back

The reading/writing methods assume that the file has got header of
length header_len bytes (possibly 0) and then records of length
record_len. These two values should be set by the read_header method.

=over 4

=item seek_to, seek_to_record

Seeks to absolute position or to the start of the record.

=item read_record, read_from

Reads data from specified position (offset) or from the given record.
The second parameter (optional for B<read_record>) is the length to
read. It can be negative, and at that case the read will not complain
if the file is shorter than requested.

=item write_to, write_record

Writes data to the absolute position or to specified record position.
The data is not padded to record_len, just written out.

=back

General locking methods are B<locksh>, B<lockex> and B<unlock>, they
call B<_locksh>, B<_lockex> and B<_unlock> which can be redefined to
allow any way for locking (not only the default flock). The user is
responsible for calling the lock if he needs it.

No more description -- check the source code if you need to know more.

=head1 VERSION

0.129

=head1 AUTHOR

(c) 1997--1999 Jan Pazdziora, adelton@fi.muni.cz

=head1 SEE ALSO

perl(1), XBase(3)

