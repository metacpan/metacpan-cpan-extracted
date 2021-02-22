package Data::Session::SHA;

use parent 'Data::Session::Base';
no autovivification;
use strict;
use warnings;

use Digest::SHA;

use Hash::FieldHash ':all';

our $errstr  = '';
our $VERSION = '1.18';

# -----------------------------------------------

sub generate
{
	my($self, $bits) = @_;

	return Digest::SHA -> new($bits) -> add($$, time, rand(time) ) -> hexdigest;

} # End of generate.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	$arg{verbose}    ||= 0;

	return from_hash(bless({}, $class), \%arg);

} # End of new.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::SHA> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::SHA> is the parent of all L<Data::Session::SHA::*> modules.

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

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
