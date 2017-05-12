#!/usr/bin/perl
#
# smethods.t
#

BEGIN { 

$lastest = 13;
$| = 1; print "1..$lastest\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

require Data::Dumper::Sorted;

$loaded = 1;
print "ok 1\n";
#########################
my $test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub chkstr {
  my($g,$e) = @_;
  print "got: $g\nexp: $e\nnot "
        unless $g eq $e;
  &ok;
}

sub chkno {
  my($g,$e) = @_;
  print "got: $g\nexp: $e\nnot "
        unless $g == $e;
  &ok;
}

# run again with unblessed pointer just for the heck of it
my $dd = 'Data::Dumper::Sorted';

my $thash = bless({
	'BDB'	=> bless({
		'conf'	=> {
			'MDipaddr'	=> '127.0.0.1',
			'MDpidpath'	=> '/usr/src/perl-bzs/My/Data/Dumper/Test/Package/tmp',
			'MDport'	=> 8149,
			'MDstatrefresh'	=> 300,
			'MDzone'	=> 'pseudo.dnsbl',
			'SCHEME'	=> 1,
		},
		'env'	=> bless([139642744,], 'BerkeleyDB::Env'),
		'key'	=> bless([139506064,bless([139642744,], 'BerkeleyDB::Env'),
	], 'BerkeleyDB::Btree'),
		'val'	=> bless([139630296,bless([139642744,], 'BerkeleyDB::Env'),
	], 'BerkeleyDB::Btree'),
	}, 'Web::Shorten::Me'),
	'CACHE'	=> sub {'DUMMY'},
	'CLASS'	=> sub {'DUMMY'},
	'LOOKUP'	=> sub {'DUMMY'},
	'NAME'	=> sub {'DUMMY'},
	'NOTFOUND'	=> sub {'DUMMY'},
	'OPCODE'	=> sub {'DUMMY'},
	'TYPE'	=> sub {'DUMMY'},
	'conf'	=> {
		'MDipaddr'	=> '127.0.0.1',
		'MDpidpath'	=> '/usr/src/perl-bzs/My/Data/Dumper/Test/Package/tmp',
		'MDport'	=> 8149,
		'MDstatrefresh'	=> 300,
		'MDzone'	=> 'pseudo.dnsbl',
		'SCHEME'	=> 1,
	},
}, 'My::Data::Dumper::Test::Package');

my $exp = q|$Var00 = bless({
	'BDB'	=> bless({
		'conf'	=> {
			'MDipaddr'	=> '127.0.0.1',
			'MDpidpath'	=> '/usr/src/perl-bzs/My/Data/Dumper/Test/Package/tmp',
			'MDport'	=> 8149,
			'MDstatrefresh'	=> 300,
			'MDzone'	=> 'pseudo.dnsbl',
			'SCHEME'	=> 1,
		},
		'env'	=> bless([139642744,], 'BerkeleyDB::Env'),
		'key'	=> bless([139506064,bless([139642744,], 'BerkeleyDB::Env'),
	], 'BerkeleyDB::Btree'),
		'val'	=> bless([139630296,bless([139642744,], 'BerkeleyDB::Env'),
	], 'BerkeleyDB::Btree'),
	}, 'Web::Shorten::Me'),
	'CACHE'	=> sub {'DUMMY'},
	'CLASS'	=> sub {'DUMMY'},
	'LOOKUP'	=> sub {'DUMMY'},
	'NAME'	=> sub {'DUMMY'},
	'NOTFOUND'	=> sub {'DUMMY'},
	'OPCODE'	=> sub {'DUMMY'},
	'TYPE'	=> sub {'DUMMY'},
	'conf'	=> {
		'MDipaddr'	=> '127.0.0.1',
		'MDpidpath'	=> '/usr/src/perl-bzs/My/Data/Dumper/Test/Package/tmp',
		'MDport'	=> 8149,
		'MDstatrefresh'	=> 300,
		'MDzone'	=> 'pseudo.dnsbl',
		'SCHEME'	=> 1,
	},
}, 'My::Data::Dumper::Test::Package');
|;

# test 2
my $got = $dd->Dumper($thash);
chkstr($got,$exp);

# test 3	should produce same result
my $evald = eval $got;
$got = $dd->Dumper($evald);
chkstr($got,$exp);

# test 4
my $hexp = q|$Var00 = bless({
	'BDB'	=> bless({
		'conf'	=> {
			'MDipaddr'	=> '127.0.0.1',
			'MDpidpath'	=> '/usr/src/perl-bzs/My/Data/Dumper/Test/Package/tmp',
			'MDport'	=> 0x1fd5,
			'MDstatrefresh'	=> 0x12c,
			'MDzone'	=> 'pseudo.dnsbl',
			'SCHEME'	=> 0x1,
		},
		'env'	=> bless([0x852c778,], 'BerkeleyDB::Env'),
		'key'	=> bless([0x850b190,bless([0x852c778,], 'BerkeleyDB::Env'),
	], 'BerkeleyDB::Btree'),
		'val'	=> bless([0x85296d8,bless([0x852c778,], 'BerkeleyDB::Env'),
	], 'BerkeleyDB::Btree'),
	}, 'Web::Shorten::Me'),
	'CACHE'	=> sub {'DUMMY'},
	'CLASS'	=> sub {'DUMMY'},
	'LOOKUP'	=> sub {'DUMMY'},
	'NAME'	=> sub {'DUMMY'},
	'NOTFOUND'	=> sub {'DUMMY'},
	'OPCODE'	=> sub {'DUMMY'},
	'TYPE'	=> sub {'DUMMY'},
	'conf'	=> {
		'MDipaddr'	=> '127.0.0.1',
		'MDpidpath'	=> '/usr/src/perl-bzs/My/Data/Dumper/Test/Package/tmp',
		'MDport'	=> 0x1fd5,
		'MDstatrefresh'	=> 0x12c,
		'MDzone'	=> 'pseudo.dnsbl',
		'SCHEME'	=> 0x1,
	},
}, 'My::Data::Dumper::Test::Package');
|;
$got = $dd->hexDumper($thash);
chkstr($got,$hexp);

# test 5	should product the original result
$evald = eval $got;
$got = $dd->Dumper($evald);
chkstr($got,$exp);

# check variants

# test 6
$exp =~ s/\$Var00 =/32\t=/;	# substitute count for $Var00
$got = $dd->DumperC($thash);
chkstr($got,$exp);

# test 7
$hexp  =~ s/\$Var00 =/32\t=/;	# substitute count for $Var00
$got = $dd->hexDumperC($thash);
chkstr($got,$hexp);

# in scalar mode, DumperC and DumperA should be the same

# test 8
$got = $dd->hexDumperA($thash);
chkstr($got,$hexp);

# test 9
$got = $dd->DumperA($thash);
chkstr($got,$exp);

$hexp =~ s/32\s=\s//;
$exp =~ s/32\s=\s//;

# test 10
my($data,$count) = $dd->DumperA($thash);
chkstr($data,$exp);

# test 11
chkno($count,32);

# test 12
($data,$count) = $dd->hexDumperA($thash);
chkstr($data,$hexp);

# test 13
chkno($count,32);
