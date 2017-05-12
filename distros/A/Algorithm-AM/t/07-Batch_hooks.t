# hooks and their arguments
use strict;
use warnings;
use feature qw(state);
use Test::More 0.88;
use Test::NoWarnings;
use t::TestAM qw(chapter_3_train chapter_3_test);

use Algorithm::AM::Batch;

# Tests are run by the hooks passed into the classify() method.
# Each hook contains one test with several subtests. Each is called
# this many times:
my %hook_calls = (
	begin_hook => 1,
	begin_test_hook => 2,
	begin_repeat_hook => 4,
	end_repeat_hook => 4,
	training_item_hook => 20,
	end_test_hook => 2,
	end_hook => 1,
);
my $total_calls = 0;
$total_calls += $_ for values %hook_calls;
# +1 for test_defaults, run twice
# +2 for test_training_item_hook
# +1 for Test::NoWarnings
plan tests => $total_calls + 1*2 + 2 + 1;

# store number of tests run by each method so we
# can plan subtests
my %tests_per_sub = (
	test_beginning_vars => 5,
	test_item_vars => 4,
	test_iter_vars => 1,
	test_training_item_hook_vars => 2,
	test_end_iter_vars => 2,
	test_end_test_vars => 3,
	test_end_vars => 4
);
# store methods for choosing to what run in make_hook
my %test_subs = (
	test_beginning_vars => \&test_beginning_vars,
	test_item_vars => \&test_item_vars,
	test_iter_vars => \&test_iter_vars,
	test_training_item_hook_vars => \&test_training_item_hook_vars,
	test_end_iter_vars => \&test_end_iter_vars,
	test_end_test_vars => \&test_end_test_vars,
	test_end_vars => \&test_end_vars
);

my $train = chapter_3_train();
my $test = chapter_3_test();
$test->add_item(
	features => [qw(3 1 3)],
	comment => 'second test item',
	class => 'e',
);

my $batch = Algorithm::AM::Batch->new(
	training_set => $train,
	repeat => 2,
	max_training_items => 10,
	begin_hook => make_hook(
		'begin_hook',
		'test_beginning_vars'
	),
	begin_test_hook => make_hook(
		'begin_test_hook',
		'test_beginning_vars',
		'test_item_vars'),
	begin_repeat_hook => make_hook(
		'begin_repeat_hook',
		'test_beginning_vars',
		'test_item_vars',
		'test_iter_vars'),
	training_item_hook => make_hook(
		'training_item_hook',
		'test_beginning_vars',
		'test_item_vars',
		'test_iter_vars',
		'test_training_item_hook_vars'),
	end_repeat_hook => make_hook(
		'end_repeat_hook',
		'test_beginning_vars',
		'test_item_vars',
		'test_iter_vars',
		'test_end_iter_vars'),
	end_test_hook => make_hook(
		'end_test_hook',
		'test_beginning_vars',
		'test_item_vars',
		'test_end_test_vars'
		),
	end_hook => make_hook(
		'end_hook',
		'test_beginning_vars',
		'test_end_vars'
	),
);

# test that defaults are set before and after classification
test_defaults($batch);

# most tests are run in classification hooks
$batch->classify_all($test);

test_defaults($batch);

# test item exclusion via data hook
test_training_item_hook();

# make a hook which runs the given test subs in a single subtest.
# Pass on the arguments passed to the hook at classification time.
sub make_hook {
	my ($name, @subs) = @_;
	return sub {
		my (@args) = @_;
		subtest $name => sub {
			my $plan = 0;
			$plan += $tests_per_sub{$_} for @subs;
			plan tests => $plan;
			$test_subs{$_}->(@args) for @subs;
		};
		# true return value is needed by training_item_hook to signal
		# that item should be included in training set
		return 1;
	};
}

#check vars available from beginning to end of classification
sub test_beginning_vars {
	my ($batch) = @_;
	isa_ok($batch, 'Algorithm::AM::Batch');
	is($batch->training_set->size, 5,
		'training set');
	is($batch->test_set->size, 2, 'test set');
	is($batch->probability, 1,
		'probability is 1 by default');
	is($batch->max_training_items, 10,
		'training set capped at 10 items');
	return;
}

# Check variables set before each test
# There are two items, 312 and 313, marked with
# different comments and class labels. Check each one.
sub test_item_vars {
	my ($batch, $test_item) = @_;

	isa_ok($test_item, 'Algorithm::AM::DataSet::Item');

	ok($test_item->class eq 'r' || $test_item->class eq 'e',
		'test class');
	if($test_item->class eq 'e'){
		like(
			$test_item->comment,
			qr/second test item$/,
			'test comment'
		);
		is_deeply($test_item->features, [3,1,3], 'test item features')
			or note explain $test_item->features;
	}else{
		like(
			$test_item->comment,
			qr/test item comment$/,
			'test comment'
		);
		is_deeply($test_item->features, [3,1,2], 'test item features')
			or note explain $test_item->features;
	}
	return;
}

# Test variables available for each iteration
sub test_iter_vars {
	my ($batch, $test_item, $iteration) = @_;
	ok(
		$iteration == 1 || $iteration == 2,
		'only do 2 iteration of classification');
	return;
}

sub test_training_item_hook_vars {
	my ($batch, $test_item, $iteration, $train_item) = @_;
	isa_ok($train_item, 'Algorithm::AM::DataSet::Item');
	ok($train_item->comment =~ /my.*CommentHere/,
		'item is from training set');
}

# Test variables provided after an iteration is finished
sub test_end_iter_vars {
	my ($batch, $test_item, $iteration, $excluded_items, $result) = @_;

	if($test_item->class eq 'e'){
		is_deeply($result->scores, {e => '4', r => '4'},
			'class scores');
	}else{
		is_deeply($result->scores, {e => '4', r => '9'},
			'classes scores');
	}
	is_deeply($excluded_items, [], 'no items excluded');
	return;
}

sub test_end_test_vars {
	my ($self, $test_item, @item_results) = @_;
	isa_ok($item_results[0], 'Algorithm::AM::Result');
	is(scalar @item_results, 2, '1 result for each iteration');
	is($item_results[0]->test_item, $item_results[0]->test_item,
		'results have the same test item');
}

# Test variables provided after all iterations are finished
sub test_end_vars {
	my ($batch, @results) = @_;

	is_deeply($results[0]->scores, {e => '4', r => '9'},
		'scores for first result');
	is_deeply($results[1]->scores, {e => '4', r => '9'},
		'scores for second result');
	is_deeply($results[2]->scores, {e => '4', r => '4'},
		'scores for third result');
	is_deeply($results[3]->scores, {e => '4', r => '4'},
		'scores for fourth result');
	return;
}

sub test_defaults {
	my ($batch) = @_;
	is($batch->test_set, undef, 'test_set is undef outside of hooks');
	return;
}

# test that training_item_hook excludes items via false return value
sub test_training_item_hook {
	my $batch = Algorithm::AM::Batch->new(
		training_set => chapter_3_train(),
		training_item_hook 	=> sub {
			# false return value indicates that item should be excluded
			return 0;
		},
		end_repeat_hook => sub {
			my $excluded_items = $_[3];
			is(scalar @$excluded_items, 5,
				'training_item_hook excluded all items');
			isa_ok($excluded_items->[0],
				'Algorithm::AM::DataSet::Item');
		},
	);
	$batch->classify_all(chapter_3_test());
	return;
}
