#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use App::Office::Contacts::Util::Config;

use List::Compare;

use Path::Tiny;

# --------------------------------------

my($config) = App::Office::Contacts::Util::Config -> new -> module_config;
my($inside) = 0;

my(@add_list);

for my $line (path("$$config{template_path}/homepage.tx") -> lines)
{
	if ($inside)
	{
		last if ($line =~ /dataType/);

		if ($line =~ /"#(.+)"/)
		{
			push @add_list, $1;
		}
	}
	elsif ($line =~ /function add_org/)
	{
		$inside = 1;
	}
}

$inside = 0;

my($s);
my(@update_list);

for my $line (path("$$config{template_path}/homepage.tx") -> lines)
{
	if ($inside)
	{
		last if ($line =~ /dataType/);

		if ($line =~ /"#(.+)"/)
		{
			# We rig it since the update form is not available until
			# a user does a search and then clicks on an org.

			$s = $1 =~ s/update_/add_/r;

			push @update_list, $s;
		}
	}
	elsif ($line =~ /function submit_update_org/)
	{
		$inside = 1;
	}
}

# Note: Conditional code in the template which produces this file
# can cause fields to be absent when the CGI form is rendered.
# E.g. delete_organization.

my(@form_list);

for my $line (path('docs/add.organization.form.html') -> lines)
{
	push @form_list, $line =~ /id="(.+?)"/g;
}

@form_list   = map{s/organization/org/; $_} @form_list;
my($compare) = List::Compare -> new(\@add_list, \@form_list);

say 'Report for add_org logic:';
say 'Items in the add list only:';
say map{"$_\n"} $compare -> get_unique;
say 'Items in the form list only:';
say map{"$_\n"} $compare -> get_complement;
say '-' x 50;

$compare = List::Compare -> new(\@update_list, \@form_list);

say 'Report for update_org logic:';
say 'Items in the update list only:';
say map{"$_\n"} $compare -> get_unique;
say 'Items in the form list only:';
say map{"$_\n"} $compare -> get_complement;
say '-' x 50;
