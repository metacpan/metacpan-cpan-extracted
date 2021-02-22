package Data::Session::ID::AutoIncrement;

use parent 'Data::Session::ID';
no autovivification;
use strict;
use warnings;

use Fcntl qw/:DEFAULT :flock/;

use Hash::FieldHash ':all';

our $VERSION = '1.18';

# -----------------------------------------------

sub generate
{
	my($self)    = @_;
	my($id_file) = $self -> id_file;

	(! $id_file) && die __PACKAGE__ . '. id_file not specifed in new(...)';

	my($message) = __PACKAGE__ . ". Can't %s id_file '$id_file'. %s";

	my($fh);

	sysopen($fh, $id_file, O_RDWR | O_CREAT, $self -> umask) || die sprintf($message, 'open', $self -> debug ? $! : '');

	if (! $self -> no_flock)
	{
		flock($fh, LOCK_EX) || die sprintf($message, 'lock', $self -> debug ? $! : '');
	}

	my($id) = <$fh>;

	if (! $id || ($id !~ /^\d+$/) )
	{
		$id = $self -> id_base;
	}

	$id += $self -> id_step;

	seek($fh, 0, 0)  || die sprintf($message, 'seek', $self -> debug ? $! : '');
	truncate($fh, 0) || die sprintf($message, 'truncate', $self -> debug ? $! : '');
	print $fh $id;
	close $fh || die sprintf($message, 'close', $self -> debug ? $! : '');

	return $id;

} # End of generate.

# -----------------------------------------------

sub id_length
{
	my($self) = @_;

	return 32;

} # End of id_length.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;

	$class -> init(\%arg);

	return from_hash(bless({}, $class), \%arg);

} # End of new.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::ID::AutoIncrement> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::ID::AutoIncrement> allows L<Data::Session> to generate session ids.

To use this module do this:

=over 4

=item o Specify an id generator of type AutoIncrement, as
Data::Session -> new(type => '... id:AutoIncrement ...')

=back

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::ID::AutoIncrement>.

C<new()> takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

The keys are listed here in alphabetical order.

They are lower-case because they are (also) method names, meaning they can be called to set or get
the value at any time.

=over 4

=item o id_base => $integer

Specifies the base value for the auto-incrementing sessions ids.

This key is normally passed in as Data::Session -> new(id_base => $integer).

Note: The first id returned by generate() is id_base + id_step.

Default: 0.

This key is optional.

=item o id_file => $file_name

Specifies the file name in which to save the 'current' id.

This key is normally passed in as Data::Session -> new(id_file => $file_name).

Note: The next id returned by generate() is 'current' id + id_step.

Default: File::Spec -> catdir(File::Spec -> tmpdir, 'data.session.id').

The reason Data::Session -> new(directory => ...) is not used as the default directory is because
this latter option is for where the session files are stored if the driver is File and the id
generator is not AutoIncrement.

This key is optional.

=item o id_step => $integer

Specifies the amount to be added to the previous id to get the next id.

This key is normally passed in as Data::Session -> new(id_step => $integer).

Default: 1.

This key is optional.

=item o no_flock => $boolean

Specifies (no_flock => 1) to not use flock() to obtain a lock on $file_name (which holds the
'current' id) before processing it, or (no_flock => 0) to use flock().

This key is normally passed in as Data::Session -> new(no_flock => $boolean).

Default: 0.

This key is optional.

=item o umask => $octal_value

Specifies the mode to use when calling sysopen() on $file_name.

This key is normally passed in as Data::Session -> new(umask => $octal_value).

Default: 0660.

This key is optional.

=item o verbose => $integer

Print to STDERR more or less information.

Typical values are 0, 1 and 2.

This key is normally passed in as Data::Session -> new(verbose => $integer).

This key is optional.

=back

=head1 Method: generate()

Generates the next session id, or dies if it can't.

Returns the new id.

=head1 Method: id_length()

Returns 32 because that's the classic value of the size of the id field in the sessions table.

This can be used to generate the SQL to create the sessions table.

=head1 Support

Log a bug on RT: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Session>.

=head1 Author

L<Data::Session> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
