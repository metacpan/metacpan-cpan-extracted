use Test::More;
use App::count;
use Getopt::Config::FromPod;
Getopt::Config::FromPod->set_class_default(-file => 'bin/count');

sub check
{
	pipe(FROM_PARENT, TO_CHILD);
	pipe(FROM_CHILD, TO_PARENT);
	my $pid = fork;
	die "fork failed: $!" if ! defined($pid);
	if($pid) {
		close FROM_PARENT;
		close TO_PARENT;
		print TO_CHILD $_[1];
		close TO_CHILD;
		local $/ = undef;
		my $output = <FROM_CHILD>;
		close FROM_CHILD;
		is($output, $_[2], $_[3]);
		waitpid $pid, 0;
	} else {
		close FROM_CHILD;
		close TO_CHILD;
		# Need to close first, at least, on Win32
		close STDIN;
		close STDOUT;
		open STDIN, "<&FROM_PARENT";
		open STDOUT, ">&TO_PARENT";
		App::count->run(@{$_[0]});
		close FROM_PARENT;
		close TO_PARENT;
		exit;
	}
}

my @tests = (
	[
		[], <<EOF,
1	2	3
1	1	1
2	3	1
3	1	2
EOF
		<<EOF,
4
EOF
		'no argument'
	],
	[
		[qw(-g 1)], <<EOF,
1	2	3
1	1	1
2	3	1
3	1	2
EOF
		<<EOF,
1	2
2	1
3	1
EOF
		'-g'
	],
	[
		[qw(-g 1 -c -s 2,3)], <<EOF,
1	2	3
1	1	1
2	3	1
3	1	2
EOF
		<<EOF,
1	2	3	4
2	1	3	1
3	1	1	2
EOF
		'-gcs,'
	],
	[
		[qw(-g 1 -c -s 2 -s 3)], <<EOF,
1	2	3
1	1	1
2	3	1
3	1	2
EOF
		<<EOF,
1	2	3	4
2	1	3	1
3	1	1	2
EOF
		'-gcss'
	],
	[
		[qw(-g 1,2)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	1	2
1	2	2
2	3	2
3	1	1
EOF
		'-g,'
	],
	[
		[qw(-g 1 -g 2)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	1	2
1	2	2
2	3	2
3	1	1
EOF
		'-gg'
	],
	[
		[qw(-g 2 -g 1)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	1	2
1	3	1
2	1	2
3	2	2
EOF
		'-gg rev'
	],
	[
		[qw(-g 2 -g 1 -t ,)], <<EOF,
1,2,3
1,2,4
1,1,1
2,3,1
3,1,2
1,1,2
2,3,2
EOF
		<<EOF,
1,1,2
1,3,1
2,1,2
3,2,2
EOF
		'-ggt rev'
	],
	[
		[qw(-g 1 -s 2 -s 3 -c)], <<EOF,
1	2	3
1	1	1
2	3	1
3	1	2
EOF
		<<EOF,
1	3	4	2
2	3	1	1
3	1	2	1
EOF
		'-gssc'
	],
	[
		[qw(-g 1 -s 2 --max 3 --min 3 --avg 3)], <<EOF,
1	2	3
1	1	1
2	3	1
3	1	2
EOF
		<<EOF,
1	3	3	1	2
2	3	1	1	1
3	1	2	2	2
EOF
		'max, min, avg'
	],
	[
		[qw(-g * -m 1,field1 -m 2,field2 -M t/map.yaml)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	1	1	one	ONE
1	1	2	one	ONE
1	2	3	one	TWO
1	2	4	one	TWO
2	3	1	two	THREE
2	3	2	two	THREE
3	1	2	three	ONE
EOF
		'-g*'
	],
	[
		[qw(-g 1,2 -m 1,field1 -m 2,field2 -c -M t/map.yaml)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	1	one	ONE	2
1	2	one	TWO	2
2	3	two	THREE	2
3	1	three	ONE	1
EOF
		'-g,mm'
	],
	[
		[qw(-g 1,2 -m 1,field1,2,field2 -c -M t/map.yaml)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	1	one	ONE	2
1	2	one	TWO	2
2	3	two	THREE	2
3	1	three	ONE	1
EOF
		'-g,mm'
	],
	[
		[qw(-g 1 -c -s 2 -s 3 -r ,3,2)], <<EOF,
1	2	3
1	1	1
2	3	1
3	1	2
EOF
		<<EOF,
1	3	2	4
2	3	1	1
3	1	1	2
EOF
		'-gcssr,'
	],
	[
		[qw(-r -2 -g 1,2)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	1	2
2	1	2
3	2	2
1	3	1
EOF
		'-r-g,'
	],
	[
		[qw(-r 1,-3,2,-2 -g 1,2 -m 1,field1,2,field2 -c -M t/map.yaml)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	one	1	ONE	2
1	one	2	TWO	2
2	two	3	THREE	2
3	three	1	ONE	1
EOF
		'-rg,mm'
	],
	[
		[qw(-r ,-3,,-2 -g 1,2 -m 1,field1,2,field2 -c -M t/map.yaml)], <<EOF,
1	2	3
1	2	4
1	1	1
2	3	1
3	1	2
1	1	2
2	3	2
EOF
		<<EOF,
1	one	1	ONE	2
1	one	2	TWO	2
2	two	3	THREE	2
3	three	1	ONE	1
EOF
		'-r,g,mm'
	],
);

plan tests => scalar @tests;
check(@$_) for @tests;
