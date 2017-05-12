#!/usr/bin/perl

use Test::More tests => 4;

use Algorithm::Accounting;

my $fields = [qw/id author file date/];
my $data = [
	    [1, 'alice', ['/foo.txt','/bar.txt'], '2004-05-01' ],
	    [2, 'bob',   '/foo.txt', '2004-05-03' ],
	    [3, 'alice', ['/foo.txt'], '2004-05-04' ],
	    [4, 'john', ['/lalala.txt','/foo.txt'], '2004-05-04' ],
	   ];

my $acc = Algorithm::Accounting->new();

# give the object information
$acc->fields($fields);
$acc->append_data($data);

my $result = $acc->result('file');

ok($result->{'/foo.txt'} == 4);
ok($result->{'/bar.txt'} == 1);
ok($result->{'/lalala.txt'} == 1);

ok($acc->result('author')->{alice} == 2);

