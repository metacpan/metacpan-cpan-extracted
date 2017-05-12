#!perl -w
# synopsis.pl
use strict;
use Data::Util qw(:all);

# print the file for example
open my $this, '<', __FILE__;
print while <$this>;

sub f{
	printf "f(%s) called.\n", neat($_[0]);

	my $ary_ref = array_ref shift;
}

sub g{
	f([undef, 42]);      # pass
	f({foo => "bar\n"}); # FATAL
}

g();

__END__

