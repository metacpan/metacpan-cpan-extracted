use strict;
use warnings;
use utf8;

use File::Temp ();
use Readonly;
use Test::Most;
use Time::HiRes qw(time);

use App::Actions::Docker;
use App::Actions::Error;
use App::Actions::Expression;
use App::Actions::I18N;
use App::Actions::Runner::Parallel;
use App::Actions::Util;

# Regular expressions that were quadratic on hostile input, or that let a
# trailing newline through.  Each slow case is timed against a limit many
# times what the linear code needs and far below what the old patterns took
# (they ran for seconds to minutes on the same input), so a regression fails
# without making a slow machine flaky.
#
# Devel::Cover, which the CI coverage job loads for the whole suite, makes
# every statement several times slower (the tokenizer about five times), which
# took the 40,000-comparison case past the limit.  Under it the limit is scaled
# up: the timing is no longer what is being measured there, and the jobs that
# run without coverage still hold the code to the plain limit.
Readonly::Scalar my $COVERAGE_FACTOR => 10;
Readonly::Scalar my $LIMIT => 2 * ($INC{'Devel/Cover.pm'} ? $COVERAGE_FACTOR : 1);

# Runs $code and says whether it finished within the limit.
sub quick {
	my ($code) = @_;

	my $start = time;
	$code->();

	return time - $start < $LIMIT;
}

subtest 'trimming is linear in the white space inside the text' => sub {
	my $text = 'a' . (' ' x 400_000) . 'b';
	my $trimmed;
	ok(quick(sub { $trimmed = App::Actions::Util::trim("  $text \n") }), 'a long inner run of spaces is trimmed quickly');
	is($trimmed, $text, 'and only the ends are trimmed');
	is(App::Actions::Util::trim(" \t\n "), '', 'white space alone trims to nothing');
	is(App::Actions::Util::trim(undef), '', 'and so does nothing');
};

subtest 'an error location is found in linear time' => sub {
	my $hostile = ('x at f line ' x 40_000) . 'z';
	my $described;
	ok(quick(sub { $described = App::Actions::Error->describe($hostile) }), 'many " at F line " fragments are quick');
	is($described, $hostile, 'and, with no location at the end, nothing is cut');

	my $spaces = 'm' . (' ' x 400_000) . 'at f line 1.';
	ok(quick(sub { $described = App::Actions::Error->describe($spaces) }), 'so is a long run of spaces before it');
	is($described, 'm', 'and the location is still cut');

	is(App::Actions::Error->describe("a at b at c.pm line 5.\n"), 'a at b', 'the last " at " is the location');
	is(App::Actions::Error->describe("bad JSON at character offset 9 at /a b/c.pm line 12.\n"),
		'bad JSON at character offset 9', 'even when the file name has a space in it');
	is(App::Actions::Error->describe("x at f line\n"), 'x at f line', 'a location needs its line number');
	is(App::Actions::Error->describe(" at f line 1.\n"), '', 'a message that is only a location is empty');
};

subtest 'a placeholder that is not one is rejected in linear time' => sub {
	local $Sub::Private::BYPASS = 1;

	my $template = '%(x)' . ('0' x 400_000) . 'z';
	my $rendered;
	ok(quick(sub { $rendered = App::Actions::I18N::_render($template, { x => 1 }) }), 'a run of zeros with no conversion is quick');
	is($rendered, $template, 'and is left as written');
	is(App::Actions::I18N::_render('%(a)05.2f|%(b)-3d|%(c) d|%(d)#x|%(e)s', { a => 3.14159, b => 7, c => 4, d => 255, e => 'E' }),
		'03.14|7  | 4|0xff|E', 'flags, width and precision still format as before');
};

subtest 'a long expression is tokenized in linear time' => sub {
	local $Sub::Private::BYPASS = 1;

	# Four times the input takes about four times as long when linear and
	# sixteen when quadratic, so the ratio is held to eight rather than the
	# time to a fixed limit, which a slow or busy machine went past.  The
	# best of a few runs is taken, so a pause in one of them does not count.
	my $best = sub {
		my ($count, $runs) = @_;
		my $text = join ' && ', ('a.b == 1.5e3') x $count;
		my ($fastest, $tokens);
		for (1 .. $runs) {
			my $start = time;
			$tokens = App::Actions::Expression->new->_tokenize($text);
			my $taken = time - $start;
			$fastest = $taken if !defined $fastest || $taken < $fastest;
		}
		return ($fastest, $tokens);
	};
	my ($small) = $best->(10_000, 3);
	my ($large, $tokens) = $best->(40_000, 2);
	cmp_ok($large, '<', 8 * $small, '40,000 comparisons take less than eight times as long as 10,000');
	is(scalar @{$tokens}, 40_000 * 5 + 39_999 + 1, 'five tokens a comparison, the && between them, and the end');
	is_deeply([ map { $_->{value} } @{$tokens}[ 0 .. 5 ] ], [ 'a', '.', 'b', '==', 1500, '&&' ],
		'identifiers, numbers and operators are told apart');
	is_deeply([ map { $_->{value} } @{ App::Actions::Expression->new->_tokenize('.5 1. x-y_1') } ], [ 0.5, 1, 'x-y_1', '' ],
		'numbers may start or end with the point, and identifiers may contain - and _');
};

subtest 'a parallel job\'s output is split into lines in linear time' => sub {
	plan skip_all => 'jobs run one at a time where fork() is not reliable' if $^O eq 'MSWin32';
	local $Sub::Private::BYPASS = 1;

	my $directory = File::Temp->newdir;
	my $log = "$directory/job.log";
	open my $handle, '>', $log or die "cannot write $log: $!";
	print {$handle} "line of output\r\n" x 200_000, "\n", 'unfinished';
	close $handle;

	my $parallel = App::Actions::Runner::Parallel->new(capacity => 2, temp_path => "$directory", run_job => sub { {} });
	my $entry = { log => $log, shown => 0, pending => '', plan => { display_name => 'job' } };

	my $printed = '';
	open my $sink, '>', \$printed or die;
	my $old = select $sink;
	my $fast = quick(sub { $parallel->_stream($entry) });
	select $old;

	ok($fast, '200,000 lines are streamed quickly');
	my @lines = split /\n/, $printed, -1;
	is(scalar(grep { $_ eq '[job] line of output' } @lines), 200_000, 'each line is prefixed, its carriage return gone');
	is($lines[-2], '', 'a blank line stays blank');
	is($entry->{pending}, 'unfinished', 'and an unfinished line waits for the rest of it');
};

subtest 'a trailing newline is not a valid ending' => sub {
	local $Sub::Private::BYPASS = 1;

	is(App::Actions::Docker::_quote("abc\n"), "'abc\n'", 'a word with a newline is quoted');
	is(App::Actions::Docker::_quote('abc'), 'abc', 'a plain word is not');

	throws_ok { App::Actions::I18N->new(language => "fr\n") } qr/^Invalid arguments/, 'a language with a newline is refused';
	throws_ok { App::Actions::I18N->language_for_country("GB\n") } qr/Invalid arguments/,
		'and so is a country';
	is(App::Actions::I18N->language_for_country('gb'), 'en', 'while a country in either case is accepted');
};

done_testing();
