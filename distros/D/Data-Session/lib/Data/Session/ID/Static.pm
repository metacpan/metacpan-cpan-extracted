package Data::Session::ID::Static;

use parent 'Data::Session::ID';
no autovivification;
use strict;
use warnings;

use Hash::FieldHash ':all';

our $VERSION = '1.18';

# -----------------------------------------------

sub generate
{
	my($self) = @_;
	my($id)   = $self -> id;

	(! $id) && die __PACKAGE__ . '. Static id (supplied to new) is not a true value';

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

L<Data::Session::ID::Static> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::ID::Static> allows L<Data::Session> to generate a static (constant) session id.

To use this module do this:

=over 4

=item o Specify an id generator of type Static, as Data::Session -> new(type => '... id:Static ...')

=back

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::ID::Static>.

C<new()> takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

The keys are listed here in alphabetical order.

They are lower-case because they are (also) method names, meaning they can be called to set or get
the value at any time.

=over 4

=item o id => $string

Specifies the static (constant) id to 'generate'.

This key is normally passed in as Data::Session -> new(id => $string).

Default: 0.

This key is mandatory, and can't be 0.

=item o verbose => $integer

Print to STDERR more or less information.

Typical values are 0, 1 and 2.

This key is normally passed in as Data::Session -> new(verbose => $integer).

This key is optional.

=back

=head1 Method: generate()

Generates the next session id (which is always what was passed in to new(id => ...) ), or dies if it
can't.

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
