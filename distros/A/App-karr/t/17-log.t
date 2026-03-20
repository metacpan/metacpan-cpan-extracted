use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json );
use App::karr::Git;

my $repo = tempdir( CLEANUP => 1 );
system("git init '$repo' 2>/dev/null");
system("git -C '$repo' config user.email 'agent-a\@test.com'");
system("git -C '$repo' config user.name 'Agent A'");

my $git = App::karr::Git->new( dir => $repo );

# Write log entries under two different agent refs
my $ref_a = 'refs/karr/log/agent-a_test.com';
my $line1 = '{"ts":"2026-03-19T10:00:00Z","agent":"agent-a","action":"pick","task_id":1}';
$git->write_ref($ref_a, $line1);

my $line2 = '{"ts":"2026-03-19T10:05:00Z","agent":"agent-a","action":"handoff","task_id":1}';
$git->write_ref($ref_a, "$line1\n$line2");

my $ref_b = 'refs/karr/log/agent-b_test.com';
my $line3 = '{"ts":"2026-03-19T10:02:00Z","agent":"agent-b","action":"pick","task_id":2}';
$git->write_ref($ref_b, $line3);

# Read and verify
my $output_a = $git->read_ref($ref_a);
my $output_b = $git->read_ref($ref_b);
ok $output_a, 'agent-a log ref exists';
ok $output_b, 'agent-b log ref exists';

# Parse and merge
my @entries;
for my $log_content ($output_a, $output_b) {
    for my $line (split /\n/, $log_content) {
        push @entries, decode_json($line);
    }
}
@entries = sort { $a->{ts} cmp $b->{ts} } @entries;

is scalar @entries, 3, 'three total log entries';
is $entries[0]{action}, 'pick', 'first by time: pick by agent-a';
is $entries[1]{action}, 'pick', 'second: pick by agent-b';
is $entries[2]{action}, 'handoff', 'third: handoff by agent-a';

done_testing;
