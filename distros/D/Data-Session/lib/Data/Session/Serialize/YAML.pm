package Data::Session::Serialize::YAML;

use parent 'Data::Session::Base';
no autovivification;
use strict;
use warnings;

use YAML::Tiny ();

our $VERSION = '1.17';

# -----------------------------------------------

sub freeze
{
	my($self, $data) = @_;

	return YAML::Tiny::freeze($data);

} # End of freeze.

# -----------------------------------------------

sub new
{
	my($class) = @_;

	return bless({}, $class);

} # End of new.

# -----------------------------------------------

sub thaw
{
	my($self, $data) = @_;

	return YAML::Tiny::thaw($data);

} # End of thaw.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::Serialize::YAML> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::Serialize::YAML> allows L<Data::Session> to manipulate sessions with L<YAML::Tiny>.

To use this module do this:

=over 4

=item o Specify a driver of type YAML as Data::Session -> new(type => '... serialize:YAML')

=back

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::Serialize::YAML>.

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

=head1 Method: freeze($data)

Returns $data frozen by L<YAML::Tiny>.

=head1 Method: thaw($data)

Returns $data thawed by L<YAML::Tiny>.

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
