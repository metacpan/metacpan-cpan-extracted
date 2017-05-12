#!/usr/bin/perl -w

use strict;

use Test::More tests => 27;
use Test::Exception;

use Config::XPath;

dies_ok( sub { get_config_string( "/data/aaa/bbb" ) },
         'no default config throws exception' );

read_default_config( "t/data.xml" );

my $s;

$s = get_config_string( "/data/aaa/bbb" );
is( $s, "Content", 'content' );

dies_ok( sub { $s = get_config_string( "/data/nonexistent" ) },
         'nonexistent throws exception' );

dies_ok( sub { $s = get_config_string( "/data/eee/ff" ) },
         'multiple nodes throws exception' );

dies_ok( sub { $s = get_config_string( "/data/eee" ) },
         'multiple children throws exception' );

dies_ok( sub { $s = get_config_string( "/data/ggg" ) },
         'non-text throws exception' );

dies_ok( sub { $s = get_config_string( "/data/comment()" ) },
         'unrepresentable throws exception' );

$s = get_config_string( "/data/empty" );
is( $s, "", 'empty' );

my $aref;

$aref = get_config_attrs( "/data/ccc/dd[\@name=\"one\"]" );
ok( defined $aref, 'attributes hash defined'  );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'attribute values' );

dies_ok( sub { $aref = get_config_attrs( "/data/nonexistent" ) },
         'missing attrs throws exception' );

dies_ok( sub { $aref = get_config_attrs( "/data/ccc/dd" ) },
         'multiple attrs throws exception' );

dies_ok( sub { $aref = get_config_attrs( "/data/aaa/\@str" ) },
         'attrs of attrs throws exception' );

my @l;

@l = get_config_list( "/data/ccc/dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'list of attrs values' );

@l = get_config_list( "/data/nonexistent" );
is_deeply( \@l, [], 'list of missing values' );

dies_ok( sub { @l = get_config_list( "/data/comment()" ) },
         'list of comment throws exception' );

my $m;

$m = get_config_map( "/data/eee/ff", '@name', '.' );
is_deeply( $m, { one => 1, two => 2 }, 'map values' );

$m = get_config_map( "/data/nonodes", '@name', '@value' );
is_deeply( $m, {}, 'map of missing values' );

my $sub = get_sub_config( "/data/ccc" );
ok( defined $sub, 'subconfig defined' );

$s = $sub->get_string( "dd[\@name=\"one\"]/\@value" );
is( $s, "1", 'subconfig string' );

$aref = $sub->get_attrs( "dd[\@name=\"one\"]" );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'subconfig attrs' );

@l = $sub->get_list( "dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'subconfig list' );

my @subs = get_sub_config_list( "/data/ccc/dd" );
is( scalar @subs, 2, 'number of subconfig list' );
ok( defined $subs[0], 'defined subconfig[0]' );
is( ref $subs[0], 'Config::XPath', 'type of subconfig[0]' );
ok( defined $subs[1], 'defined subconfig[1]' );
is( ref $subs[1], 'Config::XPath', 'type of subconfig[1]' );
