use strict;
use warnings;
use Test::More; # tests => 3;
use t::MockHomeDir;
use Capture::Tiny qw( capture   );
use File::Path    qw( make_path );

select(STDERR); $|=1;
select(STDOUT); $|=1;

my $class = 'CPAN::Testers::Common::Client::History';

my ($stdout, $stderr);

delete $INC{'CPAN/Testers/Common/Client/History.pm'};
eval {
    ($stdout, $stderr) = capture {
        require_ok( $class );
    };
};
BAIL_OUT $@ if $@;

can_ok( $class, qw( have_tested is_duplicate record_history ) );

# ensure file doesn't exist
my $history_file = CPAN::Testers::Common::Client::History::_get_history_file();
ok( ! -e $history_file, "test history file $history_file not present" )
    or BAIL_OUT "test history file $history_file exists already! Aborting.";

ok my $config_dir = CPAN::Testers::Common::Client::Config::get_config_dir()
    => 'got config dir';

like $history_file, qr/^\Q$config_dir\E/
    => "$history_file is a subdir of $config_dir";

ok make_path($config_dir) => "testing dir $config_dir created successfully";

my $entry = {
    dist_name => 'Class-Load-0.22',
    phase     => 'test',
    grade     => 'PASS',
};
ok ! CPAN::Testers::Common::Client::History::is_duplicate( $entry )
    => 'is_duplicate() returns false when entry is not found';

# record_history for 3 dists
my @entries = (
    $entry,
    { dist_name => 'Clone-0.06'   , phase => 'make', grade => 'PASS' },
    { dist_name => 'Clone-0.06'   , phase => 'test', grade => 'FAIL' },
    { dist_name => 'Try-Tiny-0.20', phase => 'test', grade => 'NA'   },
);
foreach my $i ( 0 .. $#entries) {
    CPAN::Testers::Common::Client::History::record_history( $entries[$i] );
    pass "recorded fake history ($i)";
}

ok CPAN::Testers::Common::Client::History::is_duplicate( $entry )
    => 'is_duplicate() returns true when entry is found';

$entry->{grade} = 'FAIL';
ok ! CPAN::Testers::Common::Client::History::is_duplicate( $entry )
    => 'is_duplicate() returns false for modified grade';

# have_tested returns proper results
ok my @results = CPAN::Testers::Common::Client::History::have_tested(
    dist => 'Clone-0.06'
) => 'have_tested() returns values for tested dist';

is scalar @results, 2 => "have_tested() returned 2 results";

my @expected = @entries[1,2];
foreach my $i (0 .. $#results) {
    is $results[$i]{dist}, $expected[$i]{dist_name}
        => "have_tested(dist) dist result $i";
    is $results[$i]{phase}, $expected[$i]{phase}
        => "have_tested(dist) phase result $i";
    is $results[$i]{grade}, $expected[$i]{grade}
        => "have_tested(dist) grade result $i";
};

@results = CPAN::Testers::Common::Client::History::have_tested(
    grade => 'PASS'
);

$entry->{grade} = 'PASS'; # restore our original data
@expected = @entries[0,1];
foreach my $i (0 .. $#results) {
    is $results[$i]{dist}, $expected[$i]{dist_name}
        => "have_tested(grade) dist result $i";
    is $results[$i]{phase}, $expected[$i]{phase}
        => "have_tested(grade) phase result $i";
    is $results[$i]{grade}, $expected[$i]{grade}
        => "have_tested(grade) grade result $i";
};




done_testing;
