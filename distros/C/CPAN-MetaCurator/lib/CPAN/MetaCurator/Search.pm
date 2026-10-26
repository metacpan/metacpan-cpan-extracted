package CPAN::MetaCurator::Search;

use boolean;
use feature 'say';
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use File::Slurper 'read_lines';
use File::Spec;

use Mew;
use Mojo::JSON qw/to_json/;

has names_path => (Str, default => sub{return 'data/module.names.txt'}, chained => 1);

has report_type => (Str, default => sub{return 'topics'}, chained => 1);

our $VERSION = '1.34';

# --------------------------------------------------

sub check
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)			= $self -> build_pad;
	my($database_path)	= File::Spec -> catfile($self -> home_path, $self -> database_path);
	my($names_path)		= $self -> names_path;

	$self -> logger -> info("Searching modules table");
	$self -> logger -> info("Reading: $database_path");
	$self -> logger -> info("Reading: $names_path");

	my(@names) = read_lines($names_path);

	my($found, @found);
	my(@not_found);
	my(%seen);

	for my $name (@names)
	{
		$name = ($name =~ /^o (.+):/) ? $1 : '';

		next if (! $name);
		next if ($seen{$name});

		$seen{$name}	= true;
		$found			= exists $$pad{module_names}{$name};

		if ($found)
		{
			push @found, $name;
		}
		else
		{
			push @not_found, $name;
		}
	}

	$self -> logger -> info('Found:');
	$self -> logger -> info(Dumper sort @found);
	$self -> logger -> info('Not found:');
	$self -> logger -> info(Dumper sort @not_found);
	$self -> logger -> info('check() finished');

	return 1; # Success.

} # End of check.

# --------------------------------------------------
# Warning: This does not find all CamelCase usages.

sub fix_camel_case
{
	my($self)	= @_;
	my($data)	= $self -> read_tiddlers_file;
	my($pad)	= $self -> pad;
	my($regexp)	= $self -> get_special_para_names_regexp($pad);
	my($topics)	= $self -> read_table('topics');
	my($count)	= 0;

	my($item);
	my(@output);
	my($text, $title, $topic);

	$self -> logger -> info("Size of data: $#$data");

	for my $index (0 .. $#$data)
	{
		$item	= $$data[$index];
		$text	= $$item{text};
		$title	= $$item{title};

		next if ($title =~ $regexp);

		$count++;

		# Scan the $text looking for each topic not surrounded by [[]].

		for $topic (@$topics)
		{
			if ($text =~ /(.+?)(\s$$topic{title})(\s?.*)/gsm)
			{
				$text = "$1\[\[$2]]$3";
			}
		}

		$$item{text} = $text;

		push @output, $item;
	}

	open(OUT, '>', 'data/new.tiddlers.json');
	print OUT to_json([@output]);
	close OUT;

	$self -> logger -> info("Input count: $count. Size of output: $#output");

	return 1;

} # End of fix_camel_case.

# --------------------------------------------------

sub report
{
	my($self)	= @_;
	my($data)	= $self -> read_tiddlers_file;
	my($pad)	= $self -> pad;
	my($regexp)	= $self -> get_special_para_names_regexp($pad);

	my($text, $title);

	for my $index (0 .. $#$data)
	{
		$text	= $$data[$index]{text};
		$title	= $$data[$index]{title};

		if ($title =~ $regexp)
		{
			$self -> logger -> warn("Skipping paragraph: $1");

			next;
		}

		$self -> logger -> info("title: $title. text: $text");
		$self -> logger -> info('-' x 50);
	}

	return 1;

} # End of report.

# --------------------------------------------------

1;

=pod

=head1 NAME

CPAN::MetaCurator::Search - Parse output from scripts/parse.metacpan.recent.pl

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author.

=head1 Method check()

Note: Module names are case-sensitive.

The purpose is to read a file of module names and classify them as found (already in the db)
and not found (new). This makes updating Perl.Wiki.html much easier since I can ignore the former.

This module is used via check.module.names.pl.

=head1 Author

L<CPAN::MetaCurator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2025.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2026, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
