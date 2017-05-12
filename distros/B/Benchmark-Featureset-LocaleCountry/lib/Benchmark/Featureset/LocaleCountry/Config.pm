package Benchmark::Featureset::LocaleCountry::Config;

use strict;
use warnings;

use Config::Tiny;

use File::HomeDir;

use Hash::FieldHash ':all';

use Path::Class;

fieldhash my %config           => 'config';
fieldhash my %config_file_path => 'config_file_path';
fieldhash my %section          => 'section';

our $VERSION = '1.03';

# -----------------------------------------------

sub init
{
	my($self, $arg) = @_;

	return from_hash($self, $arg);

} # End of init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
    my($self)        = bless {}, $class;

	$self -> init(\%arg);

	my($path) = Path::Class::file(File::HomeDir -> my_dist_config('Benchmark-Featureset-LocaleCountry'), '.htbenchmark.featureset.localecountry.conf');

	$self -> read($path);

    return $self;

} # End of new.

# -----------------------------------------------

sub read
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

}	# End of read.

# --------------------------------------------------

1;

=pod

=head1 NAME

Benchmark::Featureset::LocaleCountry::Config - Compare Locale::Codes, Locale::Country::Multilingual, WWW::Scraper::Wikipedia::ISO3166, etc

=head1 Synopsis

See L<Benchmark::Featureset::LocaleCountry>.

=head1 Description

L<Benchmark::Featureset::LocaleCountry> provides subcountry names in their native scripts.

=head1 Methods

=head2 init()

For use by subclasses.

Sets default values for object attributes.

=head2 new()

For use by subclasses.

=head2 read()

read() is called by new(). It does the actual reading of the config file.

If the file can't be read, die is called.

The path to the config file is determined by:

	Path::Class::file(File::HomeDir -> my_dist_config('Benchmark-Featureset-LocaleCountry'), '.htbenchmark.featureset.localecountry.conf');

During installation, you should have run scripts/copy.config.pl, which uses the same code, to move the config file
from the config/ directory in the disto into an OS-dependent directory.

The run-time code uses this module to look in the same directory as used by scripts/copy.config.pl.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Benchmark::Featureset::LocaleCountry>.

=head1 Author

L<Benchmark::Featureset::LocaleCountry> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
