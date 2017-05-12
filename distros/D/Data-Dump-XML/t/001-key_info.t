#!/usr/bin/perl

use Class::Easy;

use Data::Dumper;

use Test::More qw(no_plan);

use_ok 'Data::Dump::XML';
use_ok 'Data::Dump::XML::Parser';

$Class::Easy::DEBUG = 'immediately';

my $dumper = Data::Dump::XML->new;

my $data = {aaa => 'bbb'};

my ($key_prefix, $key_name, $val_type, $can_be_tag) = Data::Dump::XML->key_info ($data, aaa => $data->{aaa});

ok !defined $key_prefix;
ok $key_name eq 'aaa';
ok !defined $val_type;
ok $can_be_tag;

$data = {'@aaa' => {bbb => 'ccc'}};
($key_prefix, $key_name, $val_type, $can_be_tag) = Data::Dump::XML->key_info ($data, '@aaa' => $data->{'@aaa'});
ok $key_prefix eq '@', "key_prefix is: $key_prefix";
ok $key_name eq 'aaa';
ok $val_type eq 'HASH', "val_type is: $val_type";
ok $can_be_tag;

$data = {'-aaa-' => bless [bbb => 'ccc'], 'Foo'};
($key_prefix, $key_name, $val_type, $can_be_tag) = Data::Dump::XML->key_info ($data, '-aaa-' => $data->{'-aaa-'});
ok ! defined $key_prefix;
ok $key_name eq '-aaa-';
ok $val_type eq 'ARRAY';
ok ! $can_be_tag;

1;
