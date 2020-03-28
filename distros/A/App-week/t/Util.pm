use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
    $Data::Dumper::Sortkeys = 1;
}

package Script {
    use strict;
    use warnings;
    use utf8;
    use Data::Dumper;
    $Data::Dumper::Sortkeys = 1;

    our $lib;
    our $script;

    sub new {
	my $class = shift;
	my $obj = bless {}, $class;
	my $command = shift;
	$obj->{OPTION} = do {
	    if (ref $command eq 'ARRAY') {
		$command;
	    } else {
		use Text::ParseWords;
		[ shellwords $command ];
	    }
	};
	$obj;
    }
    sub run {
	my $obj = shift;
	use IO::File;
	my $pid = (my $fh = new IO::File)->open('-|') // die "open: $@\n";
	if ($pid == 0) {
	    open STDERR, ">&STDOUT";
	    execute(@{$obj->{OPTION}});
	    exit 1;
	}
	binmode $fh, ':encoding(utf8)';
	$obj->{RESULT} = do { local $/; <$fh> };
	my $child = wait;
	$child != $pid and die "child = $child, pid = $pid";
	$obj->{STATUS} = $?;
	$obj;
    }
    sub status {
	my $obj = shift;
	$obj->{STATUS} >> 8;
    }
    sub result {
	my $obj = shift;
	$obj->{RESULT};
    }
    sub execute {
	exec $^X, "-I$lib", $script, @_;
    }
}

1;
