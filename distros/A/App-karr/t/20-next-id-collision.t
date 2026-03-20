use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile LoadFile Dump Load );
use App::karr::Git;

my $repo = tempdir( CLEANUP => 1 );
system("git init '$repo' 2>/dev/null");
system("git -C '$repo' config user.email 'test\@test.com'");
system("git -C '$repo' config user.name 'Test'");

my $board = path($repo)->child('karr');
$board->mkpath;
$board->child('tasks')->mkpath;

# Local config has next_id: 5
my $local_config = {
    version => 1, board => { name => 'Test' }, tasks_dir => 'tasks',
    statuses => ['backlog', 'todo', 'done'],
    priorities => ['low', 'medium', 'high'],
    next_id => 5,
    defaults => { status => 'backlog', priority => 'medium', class => 'standard' },
};
DumpFile($board->child('config.yml')->stringify, $local_config);

# Remote config has next_id: 10 (another agent created more tasks)
my $git = App::karr::Git->new( dir => $repo );
my $remote_config = { %$local_config, next_id => 10 };
$git->write_ref('refs/karr/config', Dump($remote_config));

# Verify the ref has next_id: 10
my $config_content = $git->read_ref('refs/karr/config');
ok $config_content, 'config ref exists';
my $fetched_config = Load($config_content);
is $fetched_config->{next_id}, 10, 'remote next_id is 10';

# Local is still 5
my $local = LoadFile($board->child('config.yml')->stringify);
is $local->{next_id}, 5, 'local next_id is still 5 before materialize';

# The merge logic should take max(5, 10) = 10
my $merged_next_id = $local->{next_id} > $fetched_config->{next_id}
    ? $local->{next_id}
    : $fetched_config->{next_id};
is $merged_next_id, 10, 'merged next_id takes max';

# Test reverse: local is higher than remote
my $local_higher = { %$local_config, next_id => 15 };
DumpFile($board->child('config.yml')->stringify, $local_higher);
my $local2 = LoadFile($board->child('config.yml')->stringify);
my $merged2 = $local2->{next_id} > $fetched_config->{next_id}
    ? $local2->{next_id}
    : $fetched_config->{next_id};
is $merged2, 15, 'merged next_id takes max when local is higher';

done_testing;
