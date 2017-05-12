#!/usr/bin/env perl

use feature 'say';
use strict;
use warnings;

use Business::Cart::Generic::Database;
use Business::Cart::Generic::Util::Config;
use Business::Cart::Generic::Util::Logger;

use CGI::Simple;

use DBI;

use Text::Xslate 'mark_raw';

# --------------------------------------------------

sub get_id2name_map
{
	my($self) = @_;
	my(@rs)   = $self -> schema -> resultset('Zone') -> search({country_id => 1}, {columns => [qw/id name/]});

	my(%map);

	for my $rs (@rs)
	{
		$map{$rs -> id} = $rs -> name;
	}

	return {%map};

} # End of get_id2name_map.

# --------------------------------------------------

my($config) = Business::Cart::Generic::Util::Config -> new -> config;
my($tx)     = Text::Xslate -> new
(
 input_layer => '',
 path        => $$config{template_path},
);
my($logger) = Business::Cart::Generic::Util::Logger -> new(config => $config);
my($db)     = Business::Cart::Generic::Database -> new
	(
	 logger => $logger,
	 online => 0,
	 query  => CGI::Simple -> new,
	);
my($map)  = get_id2name_map($db);
my($data) = [];

for my $key (sort keys %$map)
{
	push @$data, {td => mark_raw("$key => $$map{$key}")};
}

my($page_name) = './utf8.txt';

open(OUT, '>', $page_name) || die "Can't open($page_name): $!";

print OUT <<EOS;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>Business::Cart::Generic</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
EOS

print OUT $tx -> render
(
 'basic.table.tx',
 {
	 border => 1,
	 row    => [$data],
 }
);

print OUT <<EOS;
</body>
</html>
EOS

close OUT;

print "Saved $page_name. \n";
