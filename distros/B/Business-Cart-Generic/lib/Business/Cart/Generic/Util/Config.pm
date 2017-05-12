package Business::Cart::Generic::Util::Config;

use strict;
use warnings;

use Config::Tiny;

use File::HomeDir;

use Moose;

use Path::Class;

has config           => (is => 'rw', isa => 'Any', required => 0);
has config_file_path => (is => 'rw', isa => 'Path::Class::File', required => 0);
has section          => (is => 'rw', isa => 'Str', required => 0);

use namespace::autoclean;

our $VERSION = '0.85';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($path) = Path::Class::file(File::HomeDir -> my_dist_config('Business-Cart-Generic'), '.htbusiness.cart.generic.conf');

	$self -> init($path);

} # End of BUILD.

# -----------------------------------------------

sub init
{
	my($self, $path) = @_;

	$self -> config_file_path($path);

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );

	if (Config::Tiny -> errstr)
	{
		die Config::Tiny -> errstr;
	}

	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{'host'});

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of init.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

=head1 NAME

L<Business::Cart::Generic::Util::Config> - Basic shopping cart

=head1 Synopsis

See L<Business::Cart::Generic>.

=head1 Description

L<Business::Cart::Generic> implements parts of osCommerce and PrestaShop in Perl.

=head1 Installation

See L<Business::Cart::Generic>.

=head1 Constructor and Initialization

=head2 Parentage

This class has no parents.

=head2 Using new()

C<new()> is called as C<< my($obj) = Business::Cart::Generic::Util::Config -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Business::Cart::Generic::Util::Config>.

Key-value pairs accepted in the parameter list: None.

=head1 Methods

=head2 config()

Returns a hashref as read from the config file by L<Config::Tiny>.

The default config file is shipped as config/.htbusiness.cart.generic.conf, and the installation
should be installed that somewhere convenient. See L<Business::Cart::Generic/The Configuration File>.

=head2 config_file_path()

Returns the path where the config file was found.

=head2 section()

Returns the section, either 'localhost' or 'webhost', corresponding to the value of the 'host' key
in the config file.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Many thanks are due to the people who chose to make osCommerce and PrestaShop, Zen Cart, etc, Open Source.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business::Cart::Generic>.

=head1 Author

L<Business::Cart::Generic> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
