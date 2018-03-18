use strict;
use warnings;
use utf8;
use Test::Base::Less;
use Dwarf::Validator;
use Dwarf::Request;
use Hash::MultiValue;

filters {
	query    => [qw/eval/],
	rule     => [qw/eval/],
	expected => [qw/eval/],
};

for my $block (blocks) {
	my $q = Dwarf::Request->new({ env => {} });
	$q->env->{'dwarf.request.merged'} = Hash::MultiValue->from_mixed($block->query);

	my $v = Dwarf::Validator->new($q);
	$v->check(
		$block->rule
	);

	my @expected = $block->expected;
	while (my ($key, $val) = splice(@expected, 0, 2)) {
		if (ref $val eq 'ARRAY') {
			my @params = $q->env->{'dwarf.request.merged'}->get_all($key);
			for my $i (0 .. @params - 1) {
				is($params[$i], $val->[$i], $block->name . "($i)");
			}
		}  else {
			is($q->param($key), $val, $block->name);
		}
	}
}

done_testing;

__END__

=== FILTER
--- query: { 'foo' => ' 123 ', bar => 'one' }
--- rule
(
	foo => [[FILTER => 'TRIM'], 'INT'],
	bar => [[FILTER => sub { my $v = shift; $v =~ s/one/1/; $v } ], 'INT'],
)
--- expected
(
	foo => '123',
	bar => 1,
)

=== FILTER (DEFAULT)
--- query: { 'foo' => undef }
--- rule
(
	foo => [[DEFAULT => 1], 'INT'],
)
--- expected
(
	foo => 1,
)

=== FILTER (BLANK_TO_NULL)
--- query: { 'foo' => '' }
--- rule
(
	foo => ['BLANK_TO_NULL'],
)
--- expected
(
	foo => undef,
)

=== FILTER (with multiple values)
--- query: { 'foo' => [' 0 ', ' 123 ', ' 234 '], 'bar' => [qw(one one)] }
--- rule
(
	'foo' => [[FILTER => 'trim'], 'INT'],
	'bar' => [[FILTER => sub { my $v = shift; $v =~ s/one/1/; $v } ], 'INT'],
)
--- expected
(
	'foo' => [0, 123, 234],
	'bar' => [1, 1],
)
