#! /usr/bin/env perl

use 5;
use warnings;
use strict;

use Test::More tests => 5;

# sort order for Data::Dumper.
use Data::Dumper;
$Data::Dumper::Sortkeys = sub { my ($hash) = @_; return [ sort keys %$hash ]; };

BEGIN { use_ok('Config::Nested'); }

# Read the configuration file.
my $CN ;

ok($CN = new Config::Nested(), "new");

# Get config string
my $in ='';
if (open(IN, "$TEST.conf"))
{
	while (<IN>)
	{
		$in .= $_;
	}
	close IN;
}

# Read the correct results.
my $out ='';
if (open (OUT, "$TEST.out"))
{
	while (<OUT>)
	{
		$out .= $_;
	}
	close (OUT);
}

ok($CN->autoConfigure($in), "auto configure");

my %todo;
ok($CN->parse($in), "parse");

my %sects = %{$CN->{section}};
my $string = Dumper(\%sects);
#diag ($string);

######################################################

# print the updated results.
unless ($string eq $out)
{
	use File::Temp;
	my $TMP = new File::Temp(
		template => "$TEST.out.XXXXXX",
		SUFFIX=>'.odd',
		UNLINK => 0,
	);
	diag("Test output is in $TMP.\n");
	if (open (TMP, '>', $TMP))
	{
		print TMP $string;
		close TMP;
	}
	else
	{
		diag("Cannot write to $TMP.\n");
	}
}

# Compare
ok ($string eq $out, "results");

exit;

