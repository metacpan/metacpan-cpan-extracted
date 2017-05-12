use warnings;
use strict;
#########################

# change 'tests => 1' to 'tests => last_test_to_print';
my $CLASS;
use Test::More qw/no_plan/;
BEGIN {
	$CLASS = 'Array::OrdHash';
	use_ok($CLASS) or die;
};

#########################

{
    my $array = $CLASS->new;
    can_ok $array, qw/First Last Length Indices Keys Values/;
}

# test push

{
    my $array = $CLASS->new(qw(a A b B));
	 my $res = push @$array, (qw/foo bar baz quux/);
    ok ($res == 4, 'push()');
}

# test unshift
{
    my $array = $CLASS->new(qw(a A b B));
	 my $res = unshift @$array, (qw/foo bar baz quux/);
    ok ($res == 4, 'unshift()');
}

# test pop
{
    my $array = $CLASS->new(qw(a A b B foo bar baz quux));
	 my $res = pop @$array;
    ok (($res->[0] eq 'baz' && $res->[1] eq 'quux'), 'pop()');
}

# test shift
{
    my $array = $CLASS->new(qw(a A b B foo bar baz quux));
	 my $res = shift @$array;
    ok (($res->[0] eq 'a' && $res->[1] eq 'A'), 'shift()');
}

#test splice
{
	my $array = $CLASS->new;
	my @ins = ('INS3'=>' insi', 'INS1'=>'upli', 'INS4'=>'  fhjk', 'INS2'=>'mund', 'INS0', 'oo');
	unshift(@$array, @ins);
	my @spl = splice @$array, 4, 2, ('faNEW', '6FA new');
	ok (($spl[0] eq 'INS0' && $spl[1] eq 'oo' && $array->{ faNEW } eq '6FA new'), 'splice()');
}
