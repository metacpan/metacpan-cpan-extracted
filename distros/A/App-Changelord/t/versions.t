use 5.36.0;

use Test2::V0;

use App::Changelord::Command::Version;

my $version = App::Changelord::Command::Version->new(
    changelog => {
        releases => [
            { version => 'NEXT' },
            { version => 'v1.2.3' },
        ]
    }
);

is $version->latest_version => 'v1.2.3';

is $version->next_version => 'v1.2.4';

$version->{changelog}{releases}[0]{changes} = [
    { type => 'feat' }
];

is $version->next_version => 'v1.3.0';

done_testing();
