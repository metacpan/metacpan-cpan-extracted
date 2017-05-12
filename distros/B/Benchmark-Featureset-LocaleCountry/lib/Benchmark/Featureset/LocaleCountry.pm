package Benchmark::Featureset::LocaleCountry;

use strict;
use warnings;

use Benchmark::Featureset::LocaleCountry::Config;

use Date::Simple;

use Locale::Country ();
use Locale::Country::Multilingual {use_io_layer => 1};
use Locale::Geocode ();
use Locale::Geocode::Territory ();
use Locale::Object;
use Locale::Object::DB ();
use Locale::SubCountry ();
use WWW::Scraper::Wikipedia::ISO3166::Database;

use Set::Array;

use Text::Xslate 'mark_raw';

our $VERSION = '1.03';

# ------------------------------------------------

sub build_country_data
{
	my($self, $module_data)  = @_;

	my(@country_name_count);

	push @country_name_count, {left => 'Module', right => '# of countries'};

	for my $module_name (sort keys %$module_data)
	{
		push @country_name_count, {left => $module_name, right => $$module_data{$module_name}{country_count} };
	}

	return \@country_name_count;

} # End of build_country_data.

# ------------------------------------------------

sub build_environment
{
	my($self) = @_;

	my(@environment);

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => 'Debian V 6.0.1'},
	{left => 'Perl',   right => 'V 5.12.2'};

	return \@environment;

}
 # End of build_environment.

# ------------------------------------------------

sub build_mismatched_countries
{
	my($self, $module_data, $common_countries) = @_;

	# Get the country names by which each one differs from the common list.

	my(%mismatched_data);

	for my $module_name (sort keys %$module_data)
	{
		$mismatched_data{$module_name} =
		{
			country_names => Set::Array -> new(sort @{$$module_data{$module_name}{country_names} -> difference($common_countries)}),
			name_list     => {},
		};
	}

	# Transform the unique names, for convenience in latter processing.

	my(%mismatch_list);
	my(@name_list);

	for my $module_name (sort keys %$module_data)
	{
		@name_list                                                = $mismatched_data{$module_name}{country_names} -> print;
		@mismatch_list{@name_list}                                = (1) x @name_list;
		@{$mismatched_data{$module_name}{name_list} }{@name_list} = (1) x @name_list;
	}

	# Output the module names (across) as a heading for the results table.

	@name_list = ();

	for my $module_name (sort keys %$module_data)
	{
		next if ($$module_data{$module_name}{country_count} == 0);

		push @name_list, {td => $module_name};
	}

	# Output the mismatched names (down) cross-tabulated with the module names (across).

	my(@mismatched_data);

	push @mismatched_data, [@name_list];

	for my $name (sort keys %mismatch_list)
	{
		@name_list = ();

		for my $module_name (sort keys %$module_data)
		{
			next if ($$module_data{$module_name}{country_count} == 0);

			if ($mismatched_data{$module_name}{name_list}{$name})
			{
				push @name_list, {td => $name};
			}
			else
			{
				push @name_list, {td => '-'};
			}
		}

		push @mismatched_data, [@name_list];
	}

	return \@mismatched_data;

} # End of build_mismatched_countries.

# ------------------------------------------------
# This is called once per country.

sub build_mismatched_division_detail
{
	my($self, $module_data, $common_divisions, $country_name) = @_;

	# Get the division names per country by which each one differs from the common list.

	my(%mismatched_data);

	for my $module_name (sort keys %$module_data)
	{
		next if ($$module_data{$module_name}{division_count}{$country_name} == 0);

		$mismatched_data{$module_name} =
		{
			division_names => Set::Array -> new(sort @{$$module_data{$module_name}{division_names}{$country_name} -> difference($common_divisions)}),
			name_list      => {},
		};
	}

	# Transform the unique names, for convenience in latter processing.

	my(%mismatch_list);
	my(@name_list);

	for my $module_name (sort keys %$module_data)
	{
		next if ($$module_data{$module_name}{division_count}{$country_name} == 0);

		@name_list                                                = $mismatched_data{$module_name}{division_names} -> print;
		@mismatch_list{@name_list}                                = (1) x @name_list;
		@{$mismatched_data{$module_name}{name_list} }{@name_list} = (1) x @name_list;
	}

	# Output the module names (across) as a heading for the results table.

	@name_list = ({td => $country_name});

	for my $module_name (sort keys %$module_data)
	{
		next if ($$module_data{$module_name}{division_count}{$country_name} == 0);

		push @name_list, {td => $module_name};
	}

	my(@mismatched_data);

	push @mismatched_data, [@name_list];

	# Output the mismatched names (down) cross-tabulated with the module names (across).

	for my $name (sort keys %mismatch_list)
	{
		@name_list = ({td => $country_name});

		for my $module_name (sort keys %$module_data)
		{
			next if ($$module_data{$module_name}{division_count}{$country_name} == 0);

			if ($mismatched_data{$module_name}{name_list}{$name})
			{
				push @name_list, {td => $name};
			}
			else
			{
				push @name_list, {td => '-'};
			}
		}

		push @mismatched_data, [@name_list];
	}

	return @mismatched_data;

} # End of build_mismatched_division_detail.

# ------------------------------------------------

sub build_mismatched_divisions
{
	my($self, $module_data, $common_countries) = @_;

	my($common_divisions);
	my(@mismatched_data);

	for my $country_name ($common_countries -> print)
	{
		if ($$module_data{'Locale::Geocode'}{division_count}{$country_name} && $$module_data{'Locale::SubCountry'}{division_count}{$country_name})
		{
			$common_divisions = Set::Array -> new(sort @{$$module_data{'Locale::Geocode'}{division_names}{$country_name} -> intersection($$module_data{'Locale::SubCountry'}{division_names}{$country_name})});

			push @mismatched_data, $self -> build_mismatched_division_detail($module_data, $common_divisions, $country_name);
		}
	}

	return \@mismatched_data;

} # End of build_mismatched_divisions.

# ------------------------------------------------

sub build_module_data
{
	my($self)         = @_;
	my($iso3166)      = WWW::Scraper::Wikipedia::ISO3166::Database -> new -> read_countries_table;
	my($multilingual) = Locale::Country::Multilingual -> new;
	my($world)        = Locale::SubCountry::World -> new;
	my(%module_data)  =
		(
		 'Locale::Codes' =>
		 {
			 country_count  => 0,  # See below.
			 country_names  => Set::Array -> new(Locale::Country::all_country_names),
			 division_count => {}, # Per country. See below.
			 division_names => {}, # See below.
			 last_update    => '2011-03-01',
			 version        => $Locale::Codes::VERSION,
		 },
		 'Locale::Country::Multilingual' =>
		 {
			 country_count  => 0,
			 country_names  => Set::Array -> new($multilingual -> all_country_names),
			 division_count => {},
			 division_names => {},
			 last_update    => '2009-04-15',
			 version        => $Locale::Country::Multilingual::VERSION,
		 },
		 'Locale::Geocode' =>
		 {
			 country_count  => 0,
			 country_names  => Set::Array -> new,
			 division_count => {},
			 division_names => {},
			 last_update    => '2009-02-10',
			 version        => $Locale::Geocode::VERSION,
		 },
		 'Locale::Object' =>
		 {
			 country_count  => 0,
			 country_names  => Set::Array -> new,
			 division_count => {},
			 division_names => {},
			 last_update    => '2007-10-25',
			 version        => $Locale::Object::VERSION,
		 },
		 'Locale::SubCountry' =>
		 {
			 country_count  => 0,
			 country_names  => Set::Array -> new($world -> all_full_names),
			 division_count => {},
			 division_names => {},
			 last_update    => '2011-04-06',
			 version        => $Locale::SubCountry::VERSION,
		 },
		 'WWW::Scraper::Wikipedia::ISO3166' =>
		 {
			 country_count  => 0,
			 country_names  => Set::Array -> new(map{$$iso3166{$_}{name} } keys %$iso3166),
			 division_count => {},
			 division_names => {},
			 last_update    => '2012-05-16',
			 version        => $WWW::Scraper::Wikipedia::ISO3166::VERSION,
		 },
		);

	# Get the country names common to those modules which provide them.

	my($common_countries) = Set::Array -> new(sort @{$module_data{'Locale::Codes'}{country_names} -> intersection($module_data{'Locale::Country::Multilingual'}{country_names})});
	$common_countries     = Set::Array -> new(sort @{$common_countries -> intersection($module_data{'WWW::Scraper::Wikipedia::ISO3166'}{country_names})});
	$common_countries     = Set::Array -> new(sort @{$common_countries -> intersection($module_data{'Locale::SubCountry'}{country_names})});

	# Use the common names for Locale::Geocode, since we want its territory names.

	#Ignore#$module_data{'Locale::Geocode'}{country_names} = $common_countries -> print;

	# Get the country count per module, and get the divisions per country.

	for my $country_name ($common_countries -> print)
	{
		for my $module_name (sort keys %module_data)
		{
			$module_data{$module_name}{division_count}{$country_name} = 0;
		}
	}

	my($country_name);
	my($geocode);

	for my $module_name (sort keys %module_data)
	{
		$module_data{$module_name}{country_count} = $module_data{$module_name}{country_names} -> length;

		if ($module_data{$module_name}{country_count})
		{
			for $country_name ($module_data{$module_name}{country_names} -> print)
			{
				$geocode = Locale::Geocode::Territory -> new($country_name);

				if ($geocode)
				{
					$module_data{$module_name}{division_names}{$country_name} = Set::Array -> new(sort map{$_ -> name} $geocode -> divisions);
					$module_data{$module_name}{division_count}{$country_name} = $module_data{$module_name}{division_names}{$country_name} -> length;
				}
			}
		}
	}

	for my $country_name ($common_countries -> print)
	{
		for my $module_name (sort keys %module_data)
		{
			if ($module_data{$module_name}{division_count}{$country_name} > 0)
			{
				#print STDERR "$country_name. $module_name. $module_data{$module_name}{division_count}{$country_name}. \n";
			}
		}
	}

	my(@module_list);

	push @module_list, [{td => 'Module'}, {td => 'Version'}, {td => 'Last update'}];

	for my $module (sort keys %module_data)
	{
		push @module_list, [{td => mark_raw(qq|<a href="http://search.cpan.org/perldoc?$module">$module</a>|)}, {td => $module_data{$module}{version} }, {td => $module_data{$module}{last_update} }];
	}

	return ($common_countries, \%module_data, \@module_list);

} # End of build_module_data.

# ------------------------------------------------

sub build_purpose
{
	my($self) = @_;

	my(@purpose);

	push @purpose,
	{left => 'Country names',    right => '2 and 3 letter country codes'},
	{left => 'SubCountry names', right => '(Divisions, Provinces, States, Territories)'},
	{left => 'Currency details', right => 'Language details'};

	return \@purpose;

} # End of build_purpose;

# ------------------------------------------------

sub build_templater
{
	my($self, $config) = @_;

	return Text::Xslate -> new
		(
		 input_layer => '',
		 path        => $$config{template_path},
		);

} # End of build_templater.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;

    return bless {}, $class;

} # End of new.

# ------------------------------------------------

sub run
{
	my($self)                                         = @_;
	my($config)                                       = Benchmark::Featureset::LocaleCountry::Config -> new -> config;
	my($templater)                                    = $self -> build_templater($config);
	my($common_countries, $module_data, $module_list) = $self -> build_module_data;
	my($country_name_count)                           = $self -> build_country_data($module_data);

	print $templater -> render
		(
		 'locale.report.tx',
		 {
			 common_country_count   => $common_countries -> length,
			 country_name_count     => $country_name_count,
			 country_name_mismatch  => $self -> build_mismatched_countries($module_data, $common_countries),
			 default_css            => "$$config{css_url}/default.css",
			 #division_name_mismatch => $self -> build_mismatched_divisions($module_data, $common_countries),
			 environment            => $self -> build_environment,
			 fancy_table_css        => "$$config{css_url}/fancy.table.css",
			 module_data            => $module_list,
			 purpose                => $self -> build_purpose,
		 }
		);

} # End of run.

# ------------------------------------------------

1;

=pod

=head1 NAME

Benchmark::Featureset::LocaleCountry - Compare Locale::Codes, Locale::Country::Multilingual, WWW::Scraper::Wikipedia::ISO3166, etc

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Benchmark::Featureset::LocaleCountry;

	# ------------------------------

	Benchmark::Featureset::LocaleCountry -> new -> run;

See scripts/locale.report.pl.

Hint: Redirect the output of that script to your $doc_root/locale.report.html.

L<View the report on my website|http://savage.net.au/Perl-modules/html/locale.report.html>.

=head1 Description

L<Benchmark::Featureset::LocaleCountry> compares some features of various modules:

=over 4

=item o L<Locale::Codes>

=item o L<Locale::Country::Multilingual>

=item o L<Locale::Geocode>

=item o L<Locale::Object>

=item o L<Locale::SubCountry>

=item o L<WWW::Scraper::Wikipedia::ISO3166>

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

=head2 The Module Itself

Install L<Benchmark::Featureset::LocaleCountry> as you would for any C<Perl> module:

Run:

	cpanm Benchmark::Featureset::LocaleCountry

or run:

	sudo cpan Benchmark::Featureset::LocaleCountry

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head2 The Configuration File

All that remains is to tell L<Benchmark::Featureset::LocaleCountry> your values for some options.

For that, see config/.htbenchmark.featureset.localecountry.conf.

If you are using Build.PL, running Build (without parameters) will run scripts/copy.config.pl,
as explained next.

If you are using Makefile.PL, running make (without parameters) will also run scripts/copy.config.pl.

Either way, before editing the config file, ensure you run scripts/copy.config.pl. It will copy
the config file using L<File::HomeDir>, to a directory where the run-time code in
L<Benchmark::Featureset::LocaleCountry> will look for it.

	shell>cd Benchmark-Featureset-LocaleCountry-1.00
	shell>perl scripts/copy.config.pl

Under Debian, this directory will be $HOME/.perl/Benchmark-Featureset-LocaleCountry/. When you
run copy.config.pl, it will report where it has copied the config file to.

Check the docs for L<File::HomeDir> to see what your operating system returns for a
call to my_dist_config().

The point of this is that after the module is installed, the config file will be
easily accessible and editable without needing permission to write to the directory
structure in which modules are stored.

That's why L<File::HomeDir> and L<Path::Class> are pre-requisites for this module.

All modules which ship with their own config file are advised to use the same mechanism
for storing such files.

=head1 Constructor and Initialization

C<new()> is called as C<< my($builder) = Benchmark::Featureset::LocaleCountry -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Benchmark::Featureset::LocaleCountry>.

Key-value pairs in accepted in the parameter list (see corresponding methods for details):

=over 4

=item o (None as yet)

=back

=head1 Methods

=head2 build_country_data()

Returns an arrayref of module names and country counts.

=head2 build_environment()

Returns an arrayref of stuff about my working environment.

=head2 build_mismatched_countries()

Returns an arrayref of mismatches between modules and the country names they use.

=head2 build_mismatched_division_list()

See build_mismatched_divisions().

=head2 build_mismatched_divisions()

Returns an arrayref of mismatches between modules and the division names they use.

Uses build_mismatched_division_list() to do the work.

=head2 build_module_data()

Returns:

=over 4

=item o An object of type Set::Array, called $common_countries

This holds the list of countries which all modules have in common.

=item o A hashref called $module_data

This is the hashref of the modules being tested.

=item o An arrayref called $module_list

This is for outputting. It contains the modules' names and links to CPAN.

=back

=head2 build_purpose()

Returns an arrayref of stuff about the purpose of this module.

=head2 build_templater()

Returns an object of type Text::Xslate.

=head2 new()

For use by subclasses.

=head2 run()

Does the real work.

See scripts/locale.report.pl.

Hint: Redirect the output of that script to $doc_root/locale.report.html.

=head1 References

The modules compared in this package often have links to various documents, which I won't repeat here...

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

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
