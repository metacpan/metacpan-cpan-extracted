use strict;
use warnings;
use Test::More tests => 41;
use CPAN::Testers::Common::Client;

can_ok( 'CPAN::Testers::Common::Client',
    qw( new comments via author distname grade command
        is_duplicate record_history
        populate metabase_data email
    )
);

{
    no warnings 'redefine';
    *CPAN::Testers::Common::Client::History::is_duplicate = sub {
        my $params = shift;
        is_deeply(
            $params,
            {
                phase     => 'test',
                dist_name => 'CPAN-Metabase-Fact-0.001',
                grade     => 'pass',
            },
            'is_duplicate() called with the right params'
        );
    };
    *CPAN::Testers::Common::Client::History::record_history= sub {
        my $params = shift;
        is_deeply(
            $params,
            {
                phase     => 'test',
                dist_name => 'CPAN-Metabase-Fact-0.001',
                grade     => 'pass',
            },
            'record_history() called with the right params'
        );
    };
}


my $author = 'RJBS';
my $dist   = 'CPAN-Metabase-Fact-0.001';
my $grade  = 'pass';

my $client = CPAN::Testers::Common::Client->new(
    author   => $author,
    distname => $dist,
    grade    => $grade,
);
ok $client, 'client spawns';

isa_ok $client, 'CPAN::Testers::Common::Client', 'client has the proper class';

is $client->author, $author, 'got the author';

is $client->distname, $dist, 'got proper distname';

is $client->grade, $grade, 'got the proper grade';

is $client->command, '', 'got the proper command';

$client->is_duplicate();
$client->record_history();

is(
    $client->via,
    'your friendly CPAN Testers client version ' . $CPAN::Testers::Common::Client::VERSION,
    'got the default "via" information'
);

like(
    $client->comments,
    qr/this report is from an automated|none provided/,
    'got the default comment'
);

my $data;
ok $data = $client->populate, 'could populate';
is ref $data, 'HASH', 'got back a hash reference';

my @facts = qw(
        TestSummary TestOutput TesterComment
        Prereqs InstalledModules
        PlatformInfo PerlConfig TestEnvironment
        LegacyReport
    );

foreach my $fact (@facts) {
  ok exists $data->{$fact}, "found data for '$fact' fact";
}

my $data2;
ok $data2 = $client->metabase_data, 'got metabase_data';
is_deeply $data, $data2, 'metabase_data() returns the same (cached) data structure';

ok my $email = $client->email, 'could retrieve the email';

ok length $email, 'email is not empty';

foreach my $section ( 'TESTER COMMENTS', 'PROGRAM OUTPUT',
                      'PREREQUISITES', 'ENVIRONMENT AND OTHER CONTEXT'
) {
    like $email, qr/$section/, "standard email section $section is shown";
}



#===========================================
# second run -- passing more stuff around
#===========================================

$author = 'David Golden';
$dist   = 'CPAN-Reporter-0.003.tar.bz2';
$grade  = 'fail';

ok $client = CPAN::Testers::Common::Client->new(
    distname => $dist,
    author   => $author,
    grade    => $grade,
    via      => 'AwesomeClient 2.0 pre-beta',
    comments => 'oh, noes!',
    command  => '/compile/and/test/me/please',

    configure_output => 'TUPTUO ERUGIFNOC',
    build_output     => 'TUPTUO DLIUB',
    test_output      => 'ZOMG THIS TEST FAILED',

    prereqs => {
       runtime   => { requires => { 'Test::More' => 0 }  },
       build     => { requires => { 'Test::Most' => 0, 'Test::LongString' => 0 } },
       configure => { requires => { 'Test::Builder' => 1.2 } },
    },
), 'could create a new object';


ok $email = $client->email, 'got the email on the second run (auto populates)';

like $email, qr/^Dear David Golden,/, 'addressing author';
like $email, qr/created by AwesomeClient 2.0 pre-beta/, 'client label';
like $email, qr/oh, noes!/, 'tester comments';
like $email, qr/ZOMG THIS TEST FAILED/, 'test output';
like $email, qr/Test::More/, 'runtime prereq';
like $email, qr/Test::Most/, 'build prereq 1';
like $email, qr/Test::LongString/, 'build_prereq 2';
like $email, qr/Test::Builder/, 'configure_prereq';
like $email, qr|Output from '/compile/and/test/me/please':|, 'command';


