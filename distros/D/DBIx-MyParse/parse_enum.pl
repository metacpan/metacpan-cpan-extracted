#!/usr/bin/perl

use strict;
use warnings;

my $path = $ARGV[0];
my @headers = (
	{
		file_name => 'sql/item_func.h',
		enum_name => 'Functype',
	},
	{
		file_name => 'sql/item.h',
		enum_name => 'Type',
	},
	{
		file_name => 'sql/item_timefunc.h',
		enum_name => 'interval_type',
	},
	{
		file_name => 'sql/sql_lex.h',
		enum_name => 'enum_sql_command'
	},
	{
		file_name => 'include/thr_lock.h',
		enum_name => 'thr_lock_type'
	},
	{
		file_name => 'sql/item_sum.h',
		enum_name => 'Sumfunctype'
	}

);

my $output_header = 'my_enum.h';
my $output_code = 'my_enum.c';
my $output_header_private = 'my_enum_priv.h';

open (HEADER, ">$output_header") or die "Unable to open output file $output_header: $!";
open (HEADER_PRIVATE, ">$output_header_private") or die "Unable to open output file $output_header_private: $!";
open (CODE, ">$output_code") or die "Unable to open output file $output_code: $!";

print CODE "
#include <$output_header_private>
#include <$output_header>
#include <string.h>
#include <assert.h>
";

foreach my $header (@headers) {

	my $full_file_name = $path.$header->{file_name};
	open (INPUT, $full_file_name) or die "Unable to open header file $full_file_name for parsing: $!";
	read(INPUT, my $header_contents, -s $full_file_name);
	close INPUT;
	my $enum_name = $header->{enum_name};
	my ($enum_string) = $header_contents =~ m{enum $enum_name[\r\n ]*?\{(.*?)\}}si;

	print localtime()." [$$] Parsing $full_file_name, enum $enum_name\n";
	
	if (not defined $enum_string) {
		die "Unable to locate enum $header->{enum_name} in $full_file_name";
	}

	$enum_string =~ s{\/\*.*?\*\/}{}sgio;
	
	$enum_string =~ s{[^A-Za-z0-9,_=-]}{}sgio;

	my @enum_list = split(',', $enum_string);

	print HEADER "
int my_parse_$header->{enum_name} (const int enum_value, char * buff);
";

	print HEADER_PRIVATE "
enum $header->{enum_name} {
	$enum_string
};
";

	print CODE "
int my_parse_$header->{enum_name} (const int enum_value, char * buff) {

	switch(enum_value) {
";
	foreach my $enum_item (@enum_list) {

		if ($enum_item =~ m{^(.*?)=}sio) {
			$enum_item = $1;
		};

		print CODE "
		case $enum_item:
			strcpy(buff, \"$enum_item\");
			break;
";
	}

	print CODE "
		default:
			assert(enum_value);
	}
	return 0;
}
";
}

close HEADER;
close CODE;
