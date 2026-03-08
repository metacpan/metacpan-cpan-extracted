use strict;
use Test::More;
use Container::Builder;

my $b = Container::Builder->new(debian_pkg_hostname => 'iaan.be');

# I'm not sure how I feel about these tests.
# They expose the internals of the class which I think shouldn't be exposed.
# But because I didn't make classes for modeling the Entrypoint, Directories, Users, ... it's a bit tough to make tests.
# Furthermore, these tests don't guarantee that the class will use them correctly at build() time and create a valid container archive (which is actually what we want to test).
# TODO: The first solution is to make classes for all of these. (Doesn't fix the above fully)
# TODO: The second solution is to make a class that can read my Container::Builder archives and parse/analyze it. This is the preferred solution imo but a lot of work. For now we'll keep it at these simple tests.

$b->set_entry('/bin/perl', '-e', "'print(\"hallo\")'");
# entry
my @e = $b->get_entry();
ok(@e == 1, 'Entry only contains the binary to be executed');
ok($e[0] eq '/bin/perl', 'Entry is /bin/perl');
# cmd
my @c = $b->get_cmd();
ok(@c == 2, 'The arguments are in cmd');
ok($c[0] eq '-e');
ok($c[1] eq "'print(\"hallo\")'");

$b->set_env('JAJA', 'JEJE');
$b->set_env('HOI', 'HAI');
# env
my %env = $b->get_env();
ok(keys(%env) == 2, '2 entries in env');
ok($env{'JAJA'} eq 'JEJE');
ok($env{'HOI'} eq 'HAI');
$b->set_env('HOI', 'HEY');
%env = $b->get_env();
ok($env{'HOI'} eq 'HEY', "it's equal to $env{HOI}");

# dirs
$b->create_directory('/', 0755, 0, 0);
$b->create_directory('/home', 0750, 0, 0);
$b->create_directory('/home/larry', 0750, 1337, 1337);
my @dirs = $b->get_dirs();
ok(@dirs == 3, '3 dirs will be created');
ok($dirs[0]->{path} eq '/', 'path is /');
ok($dirs[2]->{mode} == 0750, 'mode is 0750');
ok($dirs[2]->{uid} == 1337, 'uid is 1337');
ok($dirs[0]->{gid} == 0, 'gid is 0');

# users
$b->add_user('adri', 1000, 1000, '/bin/bash', '/home/adri');
$b->add_user('larry', 1337, 1337, '/bin/zsh', '/home/larry');
$b->add_user('bassie', 2000, 3000, '/bin/sh', '/home/bas');
my @users = $b->get_users();
ok(@users == 3, '3 users');
ok($users[0]->{name} eq 'adri');
ok($users[1]->{uid} == 1337);
ok($users[2]->{gid} == 3000);
ok($users[1]->{shell} eq '/bin/zsh');
ok($users[0]->{homedir} eq '/home/adri');

# groups
$b->add_group('users', 1000);
$b->add_group('leet', 1337);
$b->add_group('awesomepeople', 3000);
my @groups = $b->get_groups();
ok(@groups == 3, '3 groups');
ok($groups[0]->{name} eq 'users');
ok($groups[1]->{gid} == 1337);
ok($groups[2]->{name} eq 'awesomepeople');

done_testing;
