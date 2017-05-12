
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved.
###
###  test.pl - test harness for Config::Objective
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test;

# change 'tests => 1' to 'tests => last_test_to_print';
BEGIN { plan tests => 9 };

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


###############################################################################
###  Module Initialization
###############################################################################

use Config::Objective;
use Config::Objective::String;
use Config::Objective::Boolean;
use Config::Objective::List;
use Config::Objective::Hash;
use Config::Objective::Integer;
use Config::Objective::Table;
ok(1);


###############################################################################
###  Config Parsing
###############################################################################

$conf = Config::Objective->new('test.conf',
	{
		'string'	=> Config::Objective::String->new(),
		'quoted_string'	=> Config::Objective::String->new(),
		'special_str'	=> Config::Objective::String->new(),
		'empty_string'	=> Config::Objective::String->new(),
		'gsub_string'	=> Config::Objective::String->new(),
		'no_value'	=> Config::Objective::String->new(
						'value_optional' => 1
					),
		'path'		=> Config::Objective::String->new(
						'value_abspath' => 1
					),
		'integer'	=> Config::Objective::Integer->new(),
		'boolean'	=> Config::Objective::Boolean->new(),
		'bool_no_arg'	=> Config::Objective::Boolean->new(),
		'list'		=> Config::Objective::List->new(),
		'build_list'	=> Config::Objective::List->new(),
		'complex_list'	=> Config::Objective::List->new(),
		'hash'		=> Config::Objective::Hash->new(),
		'empty_hash'	=> Config::Objective::Hash->new(),
		'hash_opt_vals'	=> Config::Objective::Hash->new(
						'value_optional' => 1
					),
		'hash_ol'	=> Config::Objective::Hash->new(
						'value_type' => 'ARRAY'
					),
		'hash_ul'	=> Config::Objective::Hash->new(
						'value_type' => 'HASH'
					),
		'table'		=> Config::Objective::Table->new(),
		'i1'		=> Config::Objective::Integer->new(),
		'i2'		=> Config::Objective::Integer->new()
	});
ok (defined($conf));

#use Data::Dumper;
#print Dumper($conf->values);


###############################################################################
###  string data
###############################################################################

ok ($conf->string eq '3value'
    && $conf->quoted_string eq "quoted\n\tstring\non\n\t\tmultiple\n\tlines\n\n"
    && $conf->special_str eq 'quoted with "special" characters'
    && $conf->empty_string eq ''
    && $conf->gsub_string eq 'foo WHEE baz WHEE quux'
    && $conf->no_value eq ''
    && $conf->path eq '/usr/local/bin');


###############################################################################
###  integer data
###############################################################################

ok ($conf->integer == 8);


###############################################################################
###  boolean data
###############################################################################

ok (! $conf->boolean && $conf->bool_no_arg);


###############################################################################
###  list data
###############################################################################

$list = $conf->list;
$build_list = $conf->build_list;
$complex_list = $conf->complex_list;
ok (ref($list) eq 'ARRAY'
    && @$list == 3
    && $list->[0] eq 'this'
    && $list->[1] eq 'is'
    && $list->[2] eq 'cool'
    && ref($build_list) eq 'ARRAY'
    && @$build_list == 4
    && $build_list->[0] eq 'foo'
    && $build_list->[1] eq 'bar'
    && $build_list->[2] eq 'baz'
    && $build_list->[3] eq 'quux'
    && ref($complex_list) eq 'ARRAY'
    && ref($complex_list->[3]) eq 'ARRAY'
    && $complex_list->[3]->[0] eq 'random'
    && $complex_list->[3]->[1] eq 'sublist'
    && ref($complex_list->[4]) eq 'HASH'
    && scalar(keys %{$complex_list->[4]}) == 1
    && $complex_list->[4]->{'sub'} eq 'hash');


###############################################################################
###  hash data
###############################################################################

$hash = $conf->hash;
$hash_opt_vals = $conf->hash_opt_vals;
$empty_hash = $conf->empty_hash;
$hash_ol = $conf->hash_ol;
$hash_ul = $conf->hash_ul;
ok (ref($hash) eq 'HASH'
    && scalar(keys %$hash) == 4
    && exists($hash->{'bar'})
    && exists($hash->{'baz'})
    && exists($hash->{'list'})
    && ref($hash->{'list'}) eq 'ARRAY'
    && @{$hash->{'list'}} == 7
    && exists($hash->{'hash'})
    && ref($hash->{'hash'}) eq 'HASH'
    && scalar(keys %{$hash->{'hash'}}) == 2
    && ref($hash_opt_vals) eq 'HASH'
    && scalar(keys %$hash_opt_vals) == 4
    && exists($hash_opt_vals->{'larry'})
    && !defined($hash_opt_vals->{'larry'})
    && exists($hash_opt_vals->{'moe'})
    && !defined($hash_opt_vals->{'moe'})
    && exists($hash_opt_vals->{'curly'})
    && !defined($hash_opt_vals->{'curly'})
    && exists($hash_opt_vals->{'key'})
    && $hash_opt_vals->{'key'} eq 'with_val_in_same_hash'
    && ref($empty_hash) eq 'HASH'
    && scalar(keys %$empty_hash) == 0
    && ref($hash_ol) eq 'HASH'
    && scalar(keys %$hash_ol) == 2
    && ref($hash_ol->{'key1'}) eq 'ARRAY'
    && @{$hash_ol->{'key1'}} == 5
    && ref($hash_ol->{'key2'}) eq 'ARRAY'
    && @{$hash_ol->{'key2'}} == 3
    && ref($hash_ul) eq 'HASH'
    && scalar(keys %$hash_ul) == 2
    && ref($hash_ul->{'key1'}) eq 'HASH'
    && scalar(keys %{$hash_ul->{'key1'}}) == 2
    && ref($hash_ul->{'key2'}) eq 'HASH'
    && scalar(keys %{$hash_ul->{'key2'}}) == 3);


###############################################################################
###  table data
###############################################################################

$table = $conf->table;
ok (ref($table) eq 'ARRAY'
    && @$table == 4
    && ref($table->[0]) eq 'ARRAY'
    && @{$table->[0]} == 3
    && $table->[0]->[0] eq 'row'
    && $table->[0]->[1] eq '1'
    && $table->[0]->[2] eq 'foo'
    && ref($table->[1]) eq 'ARRAY'
    && @{$table->[1]} == 3
    && $table->[1]->[0] eq 'row'
    && $table->[1]->[1] eq '1.5'
    && $table->[1]->[2] eq 'quux'
    && ref($table->[2]) eq 'ARRAY'
    && @{$table->[2]} == 3
    && $table->[2]->[0] eq 'UNrow again'
    && $table->[2]->[1] eq '2'
    && $table->[2]->[2] eq 'bar'
    && ref($table->[3]) eq 'ARRAY'
    && @{$table->[3]} == 3
    && $table->[3]->[0] eq 'row'
    && $table->[3]->[1] eq '3'
    && $table->[3]->[2] eq 'baz');


###############################################################################
###  conditional data
###############################################################################

$i1 = $conf->i1;
$i2 = $conf->i2;
ok ($i1 == 1 && $i2 == 2);


