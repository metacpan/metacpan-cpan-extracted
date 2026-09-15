use v5.14;
use warnings;
use Test::More 0.98;

use lib 'lib';
use App::Greple::wordle;
use App::Greple::wordle::NYT;

# initialize() keeps its state in the module, so run each case in a
# child process.  The answer is picked from the yellow pattern "[answer]".
sub answer_for {
    my($result, @opt) = @_;
    my $pid = open(my $from_child, '-|') // die "fork: $!";
    if ($pid == 0) {
	# stay non-interactive even when the test is run from a terminal
	open STDIN, '<', '/dev/null' or die "/dev/null: $!";
	my(@fetched, @warn);
	no warnings qw(redefine once);
	*App::Greple::wordle::NYT::fetch_answer = sub { push @fetched, shift; $result };
	local $SIG{__WARN__} = sub { push @warn, @_ };
	my @argv = ('--data=NYT', @opt);
	App::Greple::wordle::initialize('wordle', \@argv);
	my($answer) = map { /^\[([a-z]+)\]$/ ? $1 : () } @argv;
	print join "\t", $answer // '', join(',', @fetched), join('', @warn) =~ s/\n/ /gr;
	exit 0;
    }
    my $out = do { local $/; <$from_child> };
    close $from_child;
    my($answer, $fetched, $warn) = split /\t/, $out, 3;
    return ($answer, [ split /,/, $fetched // '' ], $warn // '');
}

my($answer, $fetched, $warn);

($answer, $fetched, $warn) = answer_for('zesty', '--series=0', '--index=5000');
is $answer, 'zesty', 'series 0 out of range uses fetched answer';
is_deeply $fetched, [ 5000 ], 'fetched with the index';
is $warn, '', 'no warning when fetched';

my @hidden = @App::Greple::wordle::NYT::HIDDEN;
my $wrap = 5000 % @hidden;

($answer, $fetched, $warn) = answer_for(undef, '--series=0', '--index=5000');
like $warn, qr/no data for 5000, so use answer #$wrap instead/, 'fetch failure warns';
is $answer, $hidden[$wrap], 'fetch failure uses index modulo answer count';

($answer, $fetched, $warn) = answer_for('zesty', '--series=0', '--index=0');
is $answer, 'cigar', 'local data is used when available';
is_deeply $fetched, [], 'no fetch when local data is available';

($answer, $fetched, $warn) = answer_for('zesty', '--series=1', '--index=5000');
is_deeply $fetched, [], 'no fetch for series other than 0';
is $warn, '', 'series 1 out of range does not warn';
my($wrapped) = answer_for(undef, '--series=1', "--index=$wrap");
is $answer, $wrapped, 'series 1 out of range uses index modulo answer count';
my($next) = answer_for(undef, '--series=1', '--index=5001');
isnt $next, $answer, 'series 1 answer changes with the index';

done_testing;
