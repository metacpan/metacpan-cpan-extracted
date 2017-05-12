package Data::Session::ID::UUID34;

use parent 'Data::Session::ID';
no autovivification;
use strict;
use warnings;

use Data::UUID;

use Hash::FieldHash ':all';

our $VERSION = '1.17';

# -----------------------------------------------

sub generate
{
	my($self) = @_;

	return Data::UUID -> new -> create_hex;

} # End of generate.

# -----------------------------------------------

sub id_length
{
	my($self) = @_;

	return 34;

} # End of id_length.

# -----------------------------------------------

sub init
{
	my($self, $arg)  = @_;
	$$arg{id_length} = 34; # Bytes.
	$$arg{verbose}   ||= 0;

} # End of init.

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

L<Data::Session::ID::UUID34> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::ID::UUID34> allows L<Data::Session> to generate session ids using L<Data::UUID>.

To use this module do this:

=over 4

=item o Specify an id generator of type UUID34, as Data::Session -> new(type => '... id:UUID34 ...')

=back

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::ID::UUID34>.

C<new()> takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

The keys are listed here in alphabetical order.

They are lower-case because they are (also) method names, meaning they can be called to set or get
the value at any time.

=over 4

=item o verbose => $integer

Print to STDERR more or less information.

Typical values are 0, 1 and 2.

This key is normally passed in as Data::Session -> new(verbose => $integer).

This key is optional.

=back

=head1 Method: generate()

Generates the next session id, or dies if it can't.

The algorithm is Data::UUID -> new -> create_hex.

Returns the new id.

Note: L<Data::UUID> returns '0x' as the prefix of the 34-byte hex digest. You have been warned.

=head1 Method: id_length()

Returns 34 because that's the number of bytes in a UUID34 digest.

This can be used to generate the SQL to create the sessions table.

See scripts/digest.pl.

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
