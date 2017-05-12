#!/usr/bin/perl

use Test::More tests => 7;

use Algorithm::Accounting;

my $fields = [qw/id author file date/];
my $groups = [[qw/author file/]];
my $data = [
	    [1, 'alice', '/foo.txt', '2004-05-01' ],
	    [2, 'bob',   '/foo.txt', '2004-05-03' ],
	    [3, 'alice', '/foo.txt', '2004-05-04' ],
	    [4, 'john', '/foo.txt', '2004-05-04' ],
	    [5, 'alice', ['/jar.txt','/bar.txt'], '2004-05-04' ],
	   ];

my $acc = Algorithm::Accounting->new();

# give the object information
$acc->fields($fields);
$acc->field_groups($groups);

$acc->append_data($data);

my $result = $acc->result;
ok($result->[0]->{1}==1);

my $author_result = $acc->result('author');
ok($author_result->{alice} == 3);

use YAML;
my $group0 = $acc->group_result(0);
is($group0->{alice}{'/foo.txt'} , 2);
is($group0->{alice}{'/bar.txt'} , 1);
is($group0->{alice}{'/jar.txt'} , 1);
is($group0->{bob}{'/foo.txt'} , 1);

is($acc->group_result(0,'alice','/foo.txt') , 2);



