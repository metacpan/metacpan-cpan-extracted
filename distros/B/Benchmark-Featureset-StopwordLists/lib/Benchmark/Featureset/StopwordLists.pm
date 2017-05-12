package Benchmark::Featureset::StopwordLists;

use strict;
use warnings;

use Benchmark::Featureset::StopwordLists::Config;

use Config;
use Config::Tiny;

use Date::Simple;

use Lingua::EN::StopWordList;
use Lingua::EN::StopWords;
use Lingua::StopWords;

use Moo;

use Text::Xslate 'mark_raw';

use Types::Standard qw/Any Str/;

has html_config =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has module_config =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has os_version =>
(
	default  => sub{return '! Debian'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.03';

# --------------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = Benchmark::Featureset::StopwordLists::Config -> new;

	$self -> html_config($config -> config);
	$self -> module_config(Config::Tiny -> read('config/module.list.ini') );
	$self -> os_version($config -> os_version);

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
	{left => 'OS',     right => $self -> os_version},
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

	push @tr, [{td => 'Name'}, {td => 'Package'}, {td => 'Notes'}];

	for my $module (sort keys %$module_config)
	{
		next if ($$module_config{$module}{include} eq 'Yes');

		$count++;

		($href = $$module_config{$module}{package}) =~ s/::/-/g;

		# mark_raw() is needed because notes contain the HTML tag <br />.

		push @tr,
		[
			{td => mark_raw("$count: $module")},
			{td => mark_raw(qq|<a href="https://metacpan.org/release/$href">$$module_config{$module}{package}</a>|)},
			{td => mark_raw($$module_config{$module}{notes} || '')},
		];
	}

	push @tr, [{td => 'Name'}, {td => 'Package'}, {td => 'Notes'}];

	return [@tr];
}
 # End of _build_excluded_list.

# ------------------------------------------------

sub _build_module_list
{
	my($self, $module_config) = @_;
	my($count) = 0;

	my($href);
	my(@tr);
	my($version);
	my($word_list, %word_list);

	push @tr, [{td => 'Name'}, {td => 'Package'}, {td => 'Version'}, {td => 'Word count'}];

	for my $module (sort keys %$module_config)
	{
		next if ($$module_config{$module}{include} eq 'No');

		$count++;

		($href     = $$module_config{$module}{package}) =~ s/::/-/g;
		$version   = `mversion $module`;
		$word_list = [];

		if ($module eq 'Lingua::EN::StopWordList')
		{
			$word_list = Lingua::EN::StopWordList -> new -> words;
		}
		elsif ($module eq 'Lingua::EN::StopWords')
		{
			$word_list = [sort keys %Lingua::EN::StopWords::StopWords];
		}
		elsif ($module eq 'Lingua::StopWords')
		{
			$word_list = [sort keys %{Lingua::StopWords::getStopWords('en')}];
		}

		$word_list{$module} = [@$word_list];

		push @tr,
		[
			{td => "$count: $module"},
			{td => mark_raw(qq|<a href="https://metacpan.org/release/$href">$$module_config{$module}{package}</a>|)},
			{td => $version},
			{td => scalar @$word_list},
		];
	}

	push @tr, [{td => 'Name'}, {td => 'Package'}, {td => 'Version'}, {td => 'Word count'}];

	return (\@tr, \%word_list);
}
 # End of _build_module_list.

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

sub _build_word_lists
{
	my($self, $module_list) = @_;

	# 1: Build a list of all words.

	my(%word, %word_list);

	for my $module (keys %$module_list)
	{
		$word{$_}                                            = 1 for @{$$module_list{$module} };
		$word_list{$module}                                  = {};
		@{$word_list{$module} }{@{$$module_list{$module} } } = (1) x @{$$module_list{$module} };
	}

	# 2: Determine which module has which words.

	my(@temp);

	push @temp, {td => 'Id'};

	for my $module (sort keys %$module_list)
	{
		push @temp, {td => $module};
	}

	my(@tr)    = [@temp];
	my($count) = 0;

	for my $word (sort keys %word)
	{
		@temp = ();

		push @temp, {td => ++$count};

		for my $module (sort keys %$module_list)
		{
			push @temp, {td => $word_list{$module}{$word} ? $word : ''};
		}

		push @tr, [@temp];
	}

	@temp = ();

	push @temp, {td => 'Id'};

	for my $module (sort keys %$module_list)
	{
		push @temp, {td => $module};
	}

	push @tr, [@temp];

	return \@tr;

} # End of _build_word_lists.

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level ||= 'debug';
	$s     ||= '';

	print "$level: $s\n";

} # End of log.

# ------------------------------------------------

sub run
{
	my($self)             = @_;
	my($html_config)      = $self -> html_config;
	my($module_config)    = $self -> module_config;
	my(@module_list)      = $self -> _build_module_list($module_config);
	my($templater)        = $self -> _build_templater($html_config);
	my($excluded_modules) = $self -> _build_excluded_list($module_config);

	print $templater -> render
		(
		 'stopwordlists.report.tx',
		 {
			default_css      => "$$html_config{css_url}/default.css",
			environment      => $self -> _build_environment,
			fancy_table_css  => "$$html_config{css_url}/fancy.table.css",
			modules_excluded => $#$excluded_modules > 1 ? $excluded_modules : [],
			modules_included => $module_list[0],
			report_generator => $self -> _build_report_generator,
			word_data        => $self -> _build_word_lists($module_list[1]),
		 }
		);

} # End of run.

# ------------------------------------------------

1;

=pod

=head1 NAME

Benchmark::Featureset::StopwordLists - Compare various stopword list modules

=head1 Synopsis

	#!/usr/bin/env perl

	use Benchmark::Featureset::StopwordLists;

	Benchmark::Featureset::StopwordLists -> new -> run;

See scripts/stopwordlists.report.pl. This outputs HTML to STDOUT.

Hint: Redirect the output of that script to your $doc_root/stopwordlists.report.html.

A copy of the report ships in html/stopwordlists.report.html.

L<View this report on my website|http://savage.net.au/Perl-modules/html/stopwordlists.report.html>.

=head1 Description

L<Benchmark::Featureset::StopwordLists> compares various stopword list modules.

The list of modules processed is shipped in data/module.list.ini, and can easily be edited before re-running:

	shell> scripts/copy.config.pl
	shell> scripts/stopwordlists.report.pl

The config stuff is explained below.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

=head2 The Module Itself

Install L<Benchmark::Featureset::StopwordLists> as you would for any C<Perl> module:

Run:

	cpanm Benchmark::Featureset::StopwordLists

or run:

	sudo cpan Benchmark::Featureset::StopwordLists

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

All that remains is to tell L<Benchmark::Featureset::StopWwordLists> your values for some options.

For that, see config/.htbenchmark.featureset.stopwordlists.conf.

If you are using Build.PL, running Build (without parameters) will run scripts/copy.config.pl,
as explained next.

If you are using Makefile.PL, running make (without parameters) will also run scripts/copy.config.pl.

Either way, before editing the config file, ensure you run scripts/copy.config.pl. It will copy
the config file using L<File::HomeDir>, to a directory where the run-time code in
L<Benchmark::Featureset::StopwordLists> will look for it.

	shell>cd Benchmark-Featureset-StopwordLists-1.00
	shell>perl scripts/copy.config.pl

Under Debian, this directory will be $HOME/.perl/Benchmark-Featureset-StopwordLists/. When you
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

C<new()> is called as C<< my($builder) = Benchmark::Featureset::StopwordLists -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Benchmark::Featureset::StopwordLists>.

Key-value pairs in accepted in the parameter list (see corresponding methods for details):

=over 4

=item o (None as yet)

=back

=head1 Methods

=head2 new()

For use by subclasses.

=head2 run()

Does the real work.

See scripts/stopwordlists.report.pl and its output html/stopwordlists.report.html.

Hint: Redirect the output of that script to $doc_root/stopwordlists.report.html.

=head1 FAQ

=head2 Where is the HTML template for the report?

Templates ship in htdocs/assets/templates/benchmark/featureset/stopwordlists/.

See also htdocs/assets/css/benchmark/featureset/stopwordlists/.

=head2 How did you choose the modules to review?

By searching MetaCPAN.org for phrases like 'stopword' and 'stop word'.

=head1 See Also

The other modules in this series are L<Benchmark::Featureset::LocaleCountry> and
L<Benchmark::FeatureSet::SetOps>.

One set of module comparison reviews, by Neil Bowers, is L<here|http://neilb.org/reviews/>.

And another set of module comparison reviews, by Ron Savage, is L<here|http://savage.net.au/Module-reviews.html>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Benchmark::Featureset::StopwordLists>.

=head1 Repository

L<https://github.com/ronsavage/Benchmark-Featureset-StopwordLists.git>.

=head1 Author

L<Benchmark::Featureset::StopwordLists> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
