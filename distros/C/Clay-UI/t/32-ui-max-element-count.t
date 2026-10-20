use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib 't/lib';

use Object::Pad 0.800;
use Clay::XS qw(Clay_MinMemorySize Clay_SetTransitionHandlers);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Test::Box;
use Clay::UI::Test::Text;

# A box that plays an exit transition when it leaves the tree.
class LeavingBox :strict(params) :does(Clay::UI::Box) {
	method contribute_transition ($config) {
		$config->{transition} = { duration => 1, properties => Clay::XS::CLAY_TRANSITION_PROPERTY_X(), exit => { has_set_final => 1 } };
		return;
	}
}

# -----------------------------------------------------------------------------
# max_element_count sizes each Clay::UI's own context; a tree that does not
# fit fails with an error that says so.
# -----------------------------------------------------------------------------

sub make_ui ($box_count, %params) {
	my $root = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child(map { Clay::UI::Test::Box->new } 1 .. $box_count);
	return Clay::UI->new(width => 100, height => 100, root => $root, %params);
}

subtest 'max_element_count is validated' => sub {
	for my $bad (0, -1, 1.5, 'many', [1]) {
		like( dies { make_ui(0, max_element_count => $bad) },
			qr/'max_element_count' must be a positive integer/, "rejects '$bad'" );
	}
};

subtest 'the default is 8192' => sub {
	is( make_ui(0)->max_element_count, 8192, 'reader reports the default' );
};

subtest 'a larger count lets a UI render a larger tree' => sub {
	my $small = make_ui(1);
	my $big   = make_ui(10_000, max_element_count => 20_000);
	is( $big->max_element_count, 20_000, 'reader reports the count' );
	ok( lives { $big->render }, '10000 boxes render' ) or note $@;
	ok( lives { $small->render }, 'the UI that was current meanwhile still renders' ) or note $@;
};

subtest "memory_size must fit this UI's count" => sub {
	make_ui(0);
	my $default_minimum = Clay_MinMemorySize();
	like( dies { make_ui(0, max_element_count => 20_000, memory_size => $default_minimum) },
		qr/'memory_size' must be an integer >= Clay_MinMemorySize\(\) \(\d+\) for max_element_count 20000 and the default max_measure_text_cache_word_count/,
		'the minimum for the default count is too small' );
	like( dies { make_ui(0, max_element_count => 20_000, max_measure_text_cache_word_count => 40_000, memory_size => $default_minimum) },
		qr/for max_element_count 20000 and max_measure_text_cache_word_count 40000/, 'a given word count is named' );
};

subtest 'a tree larger than max_element_count fails with a clear error' => sub {
	my $ui = make_ui(9000);
	like( dies { $ui->render },
		qr/\AClay::UI: the widget tree has more elements than max_element_count \(8192\) allows: 9001 widgets, at most 8190 fit; pass a larger max_element_count/,
		'the error names the parameter' );
};

subtest 'elements still playing an exit transition leave room for fewer widgets' => sub {
	my $root    = Clay::UI::Test::Box->new(id => 'root');
	my @leaving = map { LeavingBox->new } 1 .. 4;
	$root->add_child(@leaving);
	my $ui = Clay::UI->new(width => 100, height => 100, root => $root, max_element_count => 16);
	Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
	ok( lives { $ui->render for 1 .. 2 }, 'the boxes render' ) or note $@;

	# 12 widgets fit 16 elements, but not while the 4 boxes leave.
	$root->remove_child(@leaving);
	$root->add_child(map { Clay::UI::Test::Box->new } 1 .. 11);
	like( dies { $ui->render },
		qr/\AClay::UI: the widget tree has more elements than max_element_count \(16\) allows: 12 widgets, at most 10 fit;/,
		'the error counts the elements Clay keeps for them' );
};

subtest "a user error_handler gets Clay's own error" => sub {
	my @errors;
	my $ui = make_ui(9000, error_handler => sub ($error, $userdata) { push @errors, $error; return });
	ok( lives { $ui->render }, 'render returns as the handler did' ) or note $@;
	like( $errors[0]{errorText}, qr/still open layout elements/, 'the handler saw the raw Clay error' );
};

# -----------------------------------------------------------------------------
# max_measure_text_cache_word_count sizes Clay's cache of measured words; a
# frame whose texts have more words fails with an error that says so.
# -----------------------------------------------------------------------------

# One text of $word_count words on a line wide enough never to wrap.
sub make_text_ui ($word_count, %params) {
	my $root = Clay::UI::Test::Box->new(id => 'root');
	$root->add_child(Clay::UI::Test::Text->new(text => join ' ', map { "w$_" } 1 .. $word_count));
	return Clay::UI->new(width => 10_000_000, height => 100, root => $root, %params);
}

subtest 'max_measure_text_cache_word_count is validated' => sub {
	for my $bad (0, 1.5, 'many', [1]) {
		like( dies { make_ui(0, max_measure_text_cache_word_count => $bad) },
			qr/'max_measure_text_cache_word_count' must be a positive integer/, "rejects '$bad'" );
	}
	like( dies { make_ui(0, max_measure_text_cache_word_count => 31) },
		qr/\AClay::UI: Clay cannot size a context for max_element_count 8192 and max_measure_text_cache_word_count 31 \(.*expected an integer in 32\.\./,
		'Clay::XS refuses fewer than 32 words, and the error names the parameters' );
	like( dies { make_ui(0, max_element_count => 10, max_measure_text_cache_word_count => 1000) },
		qr/\AClay::UI: Clay cannot size a context for max_element_count 10 and max_measure_text_cache_word_count 1000 \(.*hash buckets/,
		'and more than 32 words per element' );
};

subtest 'the default is twice max_element_count' => sub {
	is( make_ui(0)->max_measure_text_cache_word_count, 16_384, 'reader reports the default' );
	is( make_ui(0, max_element_count => 10)->max_measure_text_cache_word_count, 32, 'and never fewer than 32 words' );
};

subtest 'a frame with more words than the cache holds fails with a clear error' => sub {
	like( dies { make_text_ui(20_000)->render },
		qr/\AClay::UI: the texts laid out in one frame have more words than max_measure_text_cache_word_count \(16384\) allows; pass a larger max_measure_text_cache_word_count/,
		'the error names the parameter' );
	my @errors;
	ok( lives { make_text_ui(20_000, error_handler => sub ($error, $userdata) { push @errors, $error; return })->render },
		'render returns as a user error_handler did' ) or note $@;
	like( $errors[0]{errorText}, qr/text measurement cache/, 'the handler saw the raw Clay error' );
};

subtest 'a larger count lets a UI lay out more words' => sub {
	my $ui = make_text_ui(20_000, max_measure_text_cache_word_count => 50_000);
	is( $ui->max_measure_text_cache_word_count, 50_000, 'reader reports the count' );
	ok( lives { $ui->render }, '20000 words render' ) or note $@;
};

done_testing;
