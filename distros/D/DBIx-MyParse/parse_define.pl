#!/usr/bin/perl

use strict;
use warnings;

my $path = $ARGV[0];

my %included;

my @headers = (
	{
		# We specify the list manually since there is no naming convention
		# for the options that would allow us to extract it automatically
		# from sql/mysql_priv.h. Too bad.
		file_name => 'sql/mysql_priv.h',
		define_type => 'bit',
		define_list => [
			'SELECT_DISTINCT',
			'SELECT_STRAIGHT_JOIN',
			'SELECT_DESCRIBE',
			'SELECT_SMALL_RESULT',
			'SELECT_BIG_RESULT',
			'OPTION_FOUND_ROWS',
			'OPTION_TO_QUERY_CACHE',
			'SELECT_NO_JOIN_CACHE',
			'OPTION_BIG_TABLES',
			'OPTION_BIG_SELECTS',
			'OPTION_LOG_OFF',
			'OPTION_UPDATE_LOG',
			'TMP_TABLE_ALL_COLUMNS',
			'OPTION_WARNINGS',
			'OPTION_AUTO_IS_NULL',
			'OPTION_FOUND_COMMENT',
			'OPTION_SAFE_UPDATES',
			'OPTION_BUFFER_RESULT',
			'OPTION_BIN_LOG',
			'OPTION_NOT_AUTOCOMMIT',
			'OPTION_BEGIN',
			'OPTION_TABLE_LOCK',
			'OPTION_QUICK',
			'OPTION_QUOTE_SHOW_CREATE',
#			'OPTION_INTERNAL_SUBTRANSACTIONS'
		],
		function_name => 'my_parse_query_options'
	},
	{
		file_name => 'sql/mysql_priv.h',
		define_type => 'bit',
		define_list => [
			'TL_OPTION_UPDATING',
			'TL_OPTION_FORCE_INDEX',
			'TL_OPTION_IGNORE_LEAVES',
			'TL_OPTION_ALIAS'
		],
		function_name => 'my_parse_table_join_options'
	},
	{
		file_name => 'include/mysqld_error.h',
		function_name => 'my_parse_errno',
		define_type => 'byte'
	}
);

my $output_header = 'my_define.h';
my $output_code = 'my_define.c';

open (HEADER, ">$output_header") or die "Unable to open output file $output_header: $!";
open (CODE, ">$output_code") or die "Unable to open output file $output_code: $!";

print CODE "
#include <$output_header>
#include <string.h>
#include <my_parse.h>

";

foreach my $header (@headers) {

	print localtime()." [$$] Creating function $header->{function_name}.\n";

	if ($header->{define_type} eq 'bit') {
		print HEADER "

void * $header->{function_name} (unsigned long define_value);

		";

		print CODE "

#include <$header->{file_name}>

		" if not defined $included{$header->{file_name}};
		$included{$header->{file_name}} = 1;

print CODE "

void * $header->{function_name} (unsigned long define_value) {

	void * array = my_parse_create_array();

";

	} elsif ($header->{define_type} eq 'byte') {
		print HEADER "

void $header->{function_name} (unsigned long define_value, char * buff);

";

		print CODE "

#include <$header->{file_name}>

" if not defined $included{$header->{file_name}};
		$included{$header->{file_name}} = 1;

		print CODE "

void $header->{function_name} (unsigned long define_value, char * buff) {

";
	} else {
		die("Unknown define_type: $header->{define_type}");
	}		

	my @define_list;

	if (defined $header->{define_list}) {
		@define_list = @{$header->{define_list}};
	} else {
		my $input_file = $path.$header->{file_name};
		open (INP, "$input_file") or die "Can not open header file $input_file: $!";
		read( INP, my $input_contents, -s $input_file);
		my @tmp_define_list = $input_contents =~ m{#define (.*?)[\t\r\n ]}sgio;
		foreach my $define_item (@tmp_define_list) {
			next if $define_item =~ m{_LAST$}sio;
			next if $define_item =~ m{_FIRST$}sio;
			push @define_list, $define_item;
		}
	}

	if ($header->{define_type} eq 'bit') {
		foreach my $define_item (@define_list) {
			print CODE "
	if (define_value & $define_item) {
		my_parse_set_array(
			array,
			MYPARSE_ARRAY_APPEND,
			(void *) \"$define_item\",
			MYPARSE_ARRAY_STRING
		);
	}
";
		};
		print CODE "

	return array;
}
";
	} elsif ($header->{define_type} eq 'byte') {
		print CODE "
	switch (define_value) {

";
	
		foreach my $define_item (@define_list) {
			print CODE "

		case $define_item:
			strcpy( buff, \"$define_item\");
			break;

";
		}
		print CODE "
		
	};

};

";
		
	}
}
	
close HEADER;
close CODE;
