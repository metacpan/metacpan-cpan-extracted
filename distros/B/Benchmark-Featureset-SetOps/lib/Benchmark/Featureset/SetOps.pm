package Benchmark::Featureset::SetOps;

use strict;
use warnings;

use Benchmark::Featureset::SetOps::Config;

use Config;
use Config::Tiny;

use Date::Simple;

use File::Slurper 'read_lines';

use Moo;

use Text::Xslate 'mark_raw';

use Types::Standard qw/Any HashRef/;

has html_config =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has module_config =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

our $VERSION = '1.06';

# --------------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> html_config(Benchmark::Featureset::SetOps::Config -> new -> config);
	$self -> module_config(Config::Tiny -> read('config/module.list.ini') );

} # End of BUILD.

# ------------------------------------------------

sub _build_environment
{
	my($self) = @_;

	my(@environment);

	# mark_raw() is needed because of the HTML tag <a>.

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => 'Debian V 6.0.4'},
	{left => 'Perl',   right => $Config{version} };

	return \@environment;
}
 # End of _build_environment.

# ------------------------------------------------

sub _build_excluded_list
{
	my($self, $module_config) = @_;
	my($count) = 0;

	my($href);
	my(@tr);

	push @tr, [{td => 'Name'}, {td => 'Notes'}];

	for my $module (sort keys %$module_config)
	{
		next if ($$module_config{$module}{include} eq 'Yes');

		$count++;

		($href = $module) =~ s/::/-/g;

		# mark_raw() is needed because notes contain the HTML tag <br />.

		push @tr,
		[
			{td => mark_raw(qq|$count: <a href="https://metacpan.org/release/$href">$module</a>|)},
			{td => mark_raw($$module_config{$module}{notes} || '')},
		];
	}

	push @tr, [{td => 'Name'}, {td => 'Notes'}];

	return [@tr];
}
 # End of _build_excluded_list.

# ------------------------------------------------

sub _build_method_list
{
	my($self, $module_config, $method_list, $overload) = @_;

	my(@name, %name);

	for my $module (keys %$method_list)
	{
		@name        = keys %{$$method_list{$module} };
		@name{@name} = (1) x @name;
	}

	my(@tr, @th, @td);

	push @th, {td => 'Method'};
	push @th, {td => $_} for sort keys %$method_list;

	push @tr, [@th];

	my($count) = 0;

	my($alias);

	for my $name (sort keys %name)
	{
		$count++;

		@td = ({td => "$count: $name"});

		for my $module (sort keys %$method_list)
		{
			$alias = $$overload{$module} ? $$overload{$module}{$name} ? $$overload{$module}{$name} : '' : '';

			push @td, {td => $$method_list{$module}{$name} ? $alias ? "Yes. $alias" : 'Yes' : ''};
		}

		push @tr, [@td];
	}

	push @tr, [@th];

	return [@tr];

} # End of _build_method_list.

# ------------------------------------------------

sub _build_module_list
{
	my($self, $module_config) = @_;
	my($count) = 0;

	my($href);
	my(%method_list);
	my($overload, %overload);
	my(@tr);
	my($version);

	push @tr, [{td => 'Name'}, {td => 'Version'}, {td => 'Method count'}, {td => 'Notes'}];

	for my $module (sort keys %$module_config)
	{
		next if ($$module_config{$module}{include} eq 'No');

		$count++;

		($href = $module)                  =~ s/::/-/g;
		($method_list{$module}, $overload) = $self -> _scan_source($module_config, $module);
		$overload{$module}                 = {%$overload};
		$version                           = `mversion $module`;

		push @tr,
		[
			{td => mark_raw(qq|$count: <a href="https://metacpan.org/release/$href">$module</a>|)},
			{td => $version},
			{td => scalar keys %{$method_list{$module} } },
			{td => mark_raw($$module_config{$module}{notes})},
		];
	}

	push @tr, [{td => 'Name'}, {td => 'Version'}, {td => 'Method count'}, {td => 'Notes'}];

	return (\@tr, \%method_list, \%overload);
}
 # End of _build_module_list.

# ------------------------------------------------

sub _build_purpose
{
	my($self) = @_;

	my(@purpose);

	push @purpose,
	{left => 'Array and Set modules', right => 'Method lists'},
	{left => '"',                     right => 'Overloaded methods'};

	return \@purpose;

} # End of _build_purpose;

# ------------------------------------------------

sub _build_report_generator
{
	my($self)   = @_;
	my($module) = __PACKAGE__;
	my($href)   = $module;
	$href       =~ s/::/-/g;

	my(@report);

	push @report,
	{left => 'Module',                                                               right => 'Version'},
	{left => mark_raw(qq|<a href="https://metacpan.org/release/$href">$module</a>|), right => $VERSION};

	return \@report;

} # End of _build_report_generator;

# ------------------------------------------------

sub _build_templater
{
	my($self, $html_config) = @_;

	return Text::Xslate -> new
		(
		 input_layer => '',
		 path        => $$html_config{template_path},
		);

} # End of _build_templater.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level ||= 'debug';
	$s     ||= '';

	print "$level: $s\n";

} # End of log.

# --------------------------------------------------

sub _process_overload_1
{
	my($self, $name, $source) = @_;
	my($inside_overload)      = 0;

	my(%overload);

	for my $line (@$source)
	{
		if ($line =~ /use overload/)
		{
			$inside_overload = 1;

			next;
		}

		next if (! $inside_overload);

		# The || '' is for Set::Object and Set::Toolkit.

		$overload{$2}       = $1 if ($line =~ /\s+"(.+)"\s+=>\s+"(.+)"/);
		$overload{$2 || ''} = $1 if ($line =~ /\s+'(.+)'\s+=>\s+\\&(.+),/);
		$overload{$2}       = $1 if ($line =~ /\s+q\((.+)\)\s+=>\s+\\&(.+),/);

		$inside_overload = 0 if ($line =~ /;/);
	}

	return {%overload};

} # End of _process_overload_1.

# --------------------------------------------------

sub _process_overload_2
{
	my($self, $name, $source) = @_;
	my($inside_overload)      = 0;

	my(%overload);

	for my $line (@$source)
	{
		if ($line =~ /\{/)
		{
			$inside_overload = 1;

			next;
		}

		next if (! $inside_overload);

		$overload{$2} = $1 if ($line =~ /\s+\*(.+)\s+=\s+\\&(.+);/);

		$inside_overload = 0 if ($line =~ /\}/);
	}

	return {%overload};

} # End of _process_overload_2.

# --------------------------------------------------

sub _process_overload_3
{
	my($self, $name, $source) = @_;
	my($inside_overload)      = 0;

	my(@name);

	for my $line (@$source)
	{
		if ($line =~ /\@UTILS\s+=\s+qw\(/)
		{
			$inside_overload = 1;

			next;
		}

		next if (! $inside_overload);

		push @name, $1 while ($line =~ /\s+(\w+)/g);

		$inside_overload = 0 if ($line =~ /\);/);
	}

	return [@name];

} # End of _process_overload_3.

# ------------------------------------------------

sub run
{
	my($self)          = @_;
	my($html_config)   = $self -> html_config;
	my($module_config) = $self -> module_config;
	my(@module_list)   = $self -> _build_module_list($module_config);
	my($templater)     = $self -> _build_templater($html_config);

	print $templater -> render
		(
		 'setops.report.tx',
		 {
			default_css      => "$$html_config{css_url}/default.css",
			environment      => $self -> _build_environment,
			fancy_table_css  => "$$html_config{css_url}/fancy.table.css",
			method_data      => $self -> _build_method_list($module_config, $module_list[1], $module_list[2]),
			modules_excluded => $self -> _build_excluded_list($module_config),
			modules_included => $module_list[0],
			purpose          => $self -> _build_purpose,
			report_generator => $self -> _build_report_generator,
		 }
		);

} # End of run.

# --------------------------------------------------

sub _scan_source
{
	my($self, $module_config, $name) = @_;
	my($path) = `mwhere $name`;

	chomp $path; # :-(.

	my(@line) = read_lines($path);

	# 1: Process sub-classes.

	if ($$module_config{$name}{sub_classes})
	{
		for my $sub_class (split(/\s*,\s*/, $$module_config{$name}{sub_classes}) )
		{
			$path = `mwhere $sub_class`;

			chomp $path; # :-(.

			push @line, read_lines($path);
		}
	}

	# 2: Get the sub names.

	my(@name) = grep{s/^sub\s+([a-zA-Z][a-zA-Z_]+).*$/$1/; $1} @line;

	if ($$module_config{$name}{overload_type} && ($$module_config{$name}{overload_type} == 3) )
	{
		# In Object::Array::Plugin::ListMoreUtils, a list of method names
		# is installed by transferring them from List::MoreUtils.

		push @name, @{$self -> _process_overload_3($name, \@line)};
	}

	my(%name);

	@name{@name} = (1) x @name;

	# 3: Get the overloads.

	my($overload)     = {};
	#my($method_name) = "_process_overload_$$module_config{$name}{overload_type}";

	if ($$module_config{$name}{overload_type})
	{
		if ($$module_config{$name}{overload_type} == 1)
		{
			$overload = $self -> _process_overload_1($name, \@line)
		}
		elsif ($$module_config{$name}{overload_type} == 2)
		{
			$overload = $self -> _process_overload_2($name, \@line)
		}
	}

	return (\%name, $overload);

} # End of _scan_source.

# ------------------------------------------------

1;

=pod

=head1 NAME

Benchmark::Featureset::SetOps - Compare various array/set handling modules

=head1 Synopsis

	#!/usr/bin/env perl

	use Benchmark::Featureset::SetOps;

	Benchmark::Featureset::SetOps -> new -> run;

See scripts/setops.report.pl.

Hint: Redirect the output of that script to your $doc_root/setops.report.html.

A copy of the report ships in html/setops.report.html.

L<View this report on my website|http://savage.net.au/Perl-modules/html/setops.report.html>.

=head1 Description

L<Benchmark::Featureset::SetOps> compares various array/set handling modules.

The list of modules processed is shipped in data/module.list.ini, and can easily be edited before re-running:

	shell> scripts/copy.config.pl
	shell> scripts/setops.report.pl

The config stuff is explained below.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

=head2 The Module Itself

Install L<Benchmark::Featureset::SetOps> as you would for any C<Perl> module:

Run:

	cpanm Benchmark::Featureset::SetOps

or run:

	sudo cpan Benchmark::Featureset::SetOps

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

All that remains is to tell L<Benchmark::Featureset::SetOps> your values for some options.

For that, see config/.htbenchmark.featureset.setops.conf.

If you are using Build.PL, running Build (without parameters) will run scripts/copy.config.pl,
as explained next.

If you are using Makefile.PL, running make (without parameters) will also run scripts/copy.config.pl.

Either way, before editing the config file, ensure you run scripts/copy.config.pl. It will copy
the config file using L<File::HomeDir>, to a directory where the run-time code in
L<Benchmark::Featureset::SetOps> will look for it.

	shell>cd Benchmark-Featureset-SetOps-1.00
	shell>perl scripts/copy.config.pl

Under Debian, this directory will be $HOME/.perl/Benchmark-Featureset-SetOps/. When you
run copy.config.pl, it will report where it has copied the config file to.

Check the docs for L<File::HomeDir> to see what your operating system returns for a
call to my_dist_config().

The point of this is that after the module is installed, the config file will be
easily accessible and editable without needing permission to write to the directory
structure in which modules are stored.

That's why L<File::HomeDir> and L<Path::Class> are pre-requisites for this module.

Although this is a good mechanism for modules which ship with their own config files, be advised that some
CPAN tester machines run tests as users who don't have home directories, resulting in test failures.

=head1 Constructor and Initialization

C<new()> is called as C<< my($builder) = Benchmark::Featureset::SetOps -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Benchmark::Featureset::SetOps>.

Key-value pairs in accepted in the parameter list (see corresponding methods for details):

=over 4

=item o (None as yet)

=back

=head1 Methods

=head2 new()

For use by subclasses.

=head2 run()

Does the real work.

See scripts/setops.report.pl and its output html/setops.report.html.

Hint: Redirect the output of that script to $doc_root/setops.report.html.

=head1 FAQ

=head2 Where is the HTML template for the report?

Templates ship in htdocs/assets/templates/benchmark/featureset/setops/.

See also htdocs/assets/css/benchmark/featureset/setops/.

=head2 How did you choose the modules to review?

I maintain (but did not write) L<Set::Array>. I have never really liked its interface, so when I started a
home-grown script that Kim Ryan (author of L<Locale::SubCountry>) and I use to compare his module with my
L<WWW::Scraper::Wikipedia::ISO3166>, I wondered if there was some module more to my liking. Hence the search
for alternatives. Then I realized my work could benefit the Perl community if I formalized the results of this
search.

Also, I have 7 modules on CPAN which use L<Set::Array>, so I wanted a good idea of the array/set modules before
I decided to switch.

=head1 Repository

L<https://github.com/ronsavage/Benchmark-Featureset-SetOps>

=head1 See Also

The modules compared in this package often have links to various modules, which I won't repeat here...

The other module in this series is L<Benchmark::Featureset::LocaleCountry>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Benchmark::Featureset::SetOps>.

=head1 Author

L<Benchmark::Featureset::SetOps> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
