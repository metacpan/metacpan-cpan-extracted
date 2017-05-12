package App::Office::Contacts::Database::Base;

use Moo;

has db =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'App::Office::Contacts::Database',
	required => 0,
);

our $VERSION = '2.04';

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Database::Base - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Each instance of this class is a L<Moo>-based object with these attributes:

=over 4

=item o db

Is an object of type L<App::Office::Contacts::Database>.

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 db()

Returns an object of type L<App::Office::Contacts::Database>.

=head1 FAQ

See L<App::Office::Contacts/FAQ>.

=head1 Support

See L<App::Office::Contacts/Support>.

=head1 Author

C<App::Office::Contacts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
