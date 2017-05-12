package App::Office::Contacts::Util::Config;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Config::Tiny;

use File::ShareDir;

use Moo;

has config_name =>
(
	default  => '.htapp.office.contacts.conf',
	is       => 'rw',
	#isa     => 'Str',
	required => 0,
);

has config_path =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'Str',
	required => 0,
);

has module_config =>
(
	default  => sub{return {} },
	is       => 'rw',
	#isa     => 'HashRef',
	required => 1,
);

our $VERSION = '2.04';

# -----------------------------------------------

sub BUILD
{
	my($self)       = @_;
	my($module_dir) = 'App::Office::Contacts' =~ s/::/-/gr;
	my($path)       = File::ShareDir::dist_file($module_dir, $self -> config_name);

	$self -> module_config($self -> _init_config($path) );

} # End of BUILD.

# -----------------------------------------------

sub _init_config
{
	my($self, $path) = @_;

	$self -> config_path($path);

	# Check [global].

	my($config) = Config::Tiny -> read($path);

	die 'Error: ' . Config::Tiny -> errstr . "\n" if (Config::Tiny -> errstr);

	my($section);

	for my $i (1 .. 2)
	{
		$section = $i == 1 ? 'global' : $$config{$section}{host};

		die "Error: Config file '$path' does not contain the section [$section]\n" if (! $$config{$section});
	}

	return $$config{$section};

}	# End of _init_config.

# --------------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Util::Config - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

See also scripts/copy.config.pl.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Each instance of this class is a L<Moo>-based object, with these attributes:

=over 4

=item o config_name

Is a string with the value '.htapp.office.contacts.conf'.

=item o config_path

Is a string holding the path to the config file.

=item o module_config

Is a hashref of options read from C<share/.htapp.office.contacts.conf>.

=back

Further, each attribute name is also a method name.

=head1 Methods

=head2 config_name()

Returns a string with the value '.htapp.office.contacts.conf'.

=head2 config_path()

Returns a string holding the path to the config file.

=head2 module_config()

Returns a hashref of options read from C<share/.htapp.office.contacts.conf>.

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
