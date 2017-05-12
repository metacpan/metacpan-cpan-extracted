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
		like($output, $_[2], $_[3]);
		waitpid $pid, 0;
	} else {
		close FROM_CHILD;
		close TO_CHILD;
		# Need to close first, at least, on Win32
		close STDIN;
		close STDOUT;
		close STDERR;
		open STDIN, "<&FROM_PARENT";
		open STDOUT, ">&TO_PARENT";
		open STDERR, ">&TO_PARENT";
		App::count->run(@{$_[0]});
		close FROM_PARENT;
		close TO_PARENT;
		exit;
	}
}

my @tests = (
	map({ [
		[$_,2], <<EOF,
1,2,3
1,1,1
2,3,1
3,1,2
EOF
		qr{Wrong delimiter\?: 1 field\(s\) is/are fewer than 2 specified in the option},
		'too few fields '.$_
	] } qw(-g -group --sum -s --min --max --ave -r --reorder)),
	map { [
		['-M','t/map.yaml',$_,'2,field2'], <<EOF,
1,2,3
1,1,1
2,3,1
3,1,2
EOF
		qr{Wrong delimiter\?: 1 field\(s\) is/are fewer than 2 specified in the option},
		'too few fields '.$_
	] } qw(-m --map),
);

plan tests => scalar @tests;
check(@$_) for @tests;
