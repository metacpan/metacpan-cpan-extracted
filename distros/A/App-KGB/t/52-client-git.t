use strict;
use warnings;

use autodie qw(:all);
use Test::More;
use Test::Exception;

BEGIN {
    eval { require Git; 1 }
        or plan skip_all => "Git.pm required for testing Git client";
}

use lib 't';
use TestBot;

use App::KGB::Change;
use App::KGB::Client::Git;
use App::KGB::Client::ServerRef;
use Git;
use File::Temp qw(tempdir);
use File::Spec;
use Test::Differences;

unified_diff();

use utf8;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $tmp_cleanup = not $ENV{TEST_KEEP_TMP};
my $dir = tempdir( 'kgb-XXXXXXX', CLEANUP => $tmp_cleanup, DIR => File::Spec->tmpdir );
diag "Temp directory $dir will pe kept" unless $tmp_cleanup;

my $test_bot = TestBot->start;

sub write_tmp {
    my( $fn, $content ) = @_;

    open my $fh, '>', "$dir/$fn";
    print $fh $content;
    close $fh;
}

my $remote = "$dir/there.git";
my $local = "$dir/here";

sub w {
    my ( $fn, $content ) = @_;

    write_tmp( "here/$fn", "$content\n" );
}

sub a {
    my ( $fn, $content ) = @_;

    open my $fh, '>>', "$local/$fn";
    print $fh $content, "\n";
    close $fh;
}

mkdir $remote;
$ENV{GIT_DIR} = $remote;
system 'git', 'init', '--bare';

use Cwd;
my $R = getcwd;

my $hook_log = "$dir/hook.log";
my $hook = "$dir/there.git/hooks/post-receive";

my $client_script = $ENV{KGB_CLIENT_SCRIPT} || "$R/script/kgb-client";

# the real test client
{
    my $ccf = $test_bot->client_config_file;
    open my $fh, '>', $hook;
    print $fh <<EOF;
#!/bin/sh

tee -a "$dir/reflog" | PERL5LIB=$R/lib $^X -- $client_script --conf $ccf >> $hook_log 2>&1
EOF
    close $fh;
    chmod 0755, $hook;
}

if ( $ENV{TEST_KGB_BOT_RUNNING} ) {
    diag "will try to send notifications to locally running bot";
    open( my $fh, '>>', $hook);
    print $fh <<"EOF";

cat "$dir/reflog" | PERL5LIB=$R/lib $^X -- $client_script --conf $R/eg/test-client.conf
EOF
    close $fh;
}

mkdir $local;
$ENV{GIT_DIR} = "$local/.git";
mkdir "$local/.git";
system 'git', 'init';

my $git = 'Git'->repository($local);
ok( $git, 'local repository allocated' );
isa_ok( $git, 'Git' );

my $ign = $git->command( 'config', 'user.name', 'Test U. Ser' );
$ign = $git->command( 'config', 'user.email', 'ser@example.neverland' );

write_tmp 'reflog', '';

my $c = new_ok(
    'App::KGB::Client::Git' => [
        {   repo_id => 'test',
            servers => [
                App::KGB::Client::ServerRef->new(
                    {   uri      => "http://127.0.0.1:1234/",
                        password => "hidden",               # not used by this client instance
                    }
                ),
            ],

            #br_mod_re      => \@br_mod_re,
            #br_mod_re_swap => $br_mod_re_swap,
            #ignore_branch  => $ignore_branch,
            git_dir => $remote,
            reflog  => "$dir/reflog",
        }
    ]
);

sub push_ok {
    write_tmp 'reflog', '';
    unlink $hook_log if $hook_log and -s $hook_log;

    my $ign = $git->command( [qw( push origin --all )], { STDERR => 0 } );
    $ign = $git->command( [qw( push origin --tags )], { STDERR => 0 } );

    $c->_reset;
    $c->_detect_commits;

    diag `cat $hook_log` if $hook_log and -s $hook_log;
}

my %commits;
sub do_commit {
    my $ign = $git->command_oneline( 'commit', '-m', shift ) =~ /\[(\w+).*\s+(\w+)\]/;
    push @{ $commits{$1} }, $2;
    #diag "commit $2 in branch $1" unless $tmp_cleanup;
}



###### first commit
w( 'a', 'some content' );
$ign = $git->command( 'add', '.' );
do_commit('initial import');
$ign = $git->command( 'remote', 'add', 'origin', "file://$remote" );
push_ok;

# now "$dir/reflog" shall have some refs
#diag "Looking for the reflog in '$dir/reflog'";
ok -s "$dir/reflog", "post-receive hook logs";

my $commit = $c->describe_commit;

ok( defined($commit), 'commit 1 present' );

is( $commit->branch, 'master' );
is( $commit->id, shift @{ $commits{master} } );
is( $commit->log, "initial import" );
is( $commit->author, 'ser' );
is( scalar @{ $commit->changes }, 1 );
is( $commit->changes->[0]->as_string, '(A)a' );

TestBot->expect( 'dummy/#test 12test/03there 05master '
        . $commit->id
        . ' 06Test U. Ser (06ser) 03a initial import * 14http://scm.host.org/there/master/?commit='
        . $commit->id
        . '' );



##### modify and add
a 'a', 'some other content';
w 'b', 'some other content';

$ign = $git->command( 'add', '.' );
do_commit('some changes');
push_ok();

$commit = $c->describe_commit;
ok( defined($commit), 'commit 2 present' );

is( $commit->branch, 'master' );
is( $commit->id, shift @{ $commits{master} } );
is( $commit->log, "some changes" );
is( $commit->author, 'ser' );
is( scalar @{ $commit->changes }, 2 );
is( $commit->changes->[0]->as_string, 'a' );
is( $commit->changes->[1]->as_string, '(A)b' );

TestBot->expect( 'dummy/#test 12test/03there 05master '
        . $commit->id
        . ' 06Test U. Ser (06ser) 10a 03b some changes * 14http://scm.host.org/there/master/?commit='
        . $commit->id
        . '' );

##### remove, banch, modyfy, add, tag; batch send
$ign = $git->command( 'rm', 'a' );
do_commit('a removed');

$ign = $git->command( 'checkout', '-q', '-b', 'other', 'master' );
w 'c', 'a new file was born';
w 'b', 'new content';
$ign = $git->command( 'add', '.' );
do_commit('a change in the other branch');
$ign = $git->command( 'tag', '1.0-beta' );
push_ok();

my $other_branch_point = $commits{master}[0];

my $c1 = $commit = $c->describe_commit;
ok( defined($commit), 'commit 3 present' );
is( $commit->branch, 'master', 'commit 3 branch is "master"' );
is( $commit->id, shift @{ $commits{master} } );
is( $commit->log, "a removed" );
is( $commit->author, 'ser' );
is( scalar @{ $commit->changes }, 1 );
is( $commit->changes->[0]->as_string, '(D)a' );

my $c2 = $commit = $c->describe_commit;
ok( defined($commit), 'commit 4 present' );
is( $commit->branch, 'other' );
is( $commit->id, shift @{ $commits{other} } );
is( $commit->log, "a change in the other branch" );
is( $commit->author, 'ser' );
is( scalar @{ $commit->changes }, 2 );
is( $commit->changes->[0]->as_string, 'b' );
is( $commit->changes->[1]->as_string, '(A)c' );

my $tagged = $commit->id;

$commit = $c->describe_commit;
ok( defined($commit), 'commit 5 present' );
is( $commit->id, $tagged, "commit 5 id" );
is( $commit->branch, 'tags', "commit 5 branch" );
is( $commit->log, "tag '1.0-beta' created", "commit 5 log" );
is( $commit->author, undef, "commit 5 author" );
is( $commit->changes->[0]->as_string, '(A)1.0-beta', "commit 5 changes" );

TestBot->expect( 'dummy/#test 12test/03there 05master '
        . $c1->id
        . ' 06Test U. Ser (06ser) 04a a removed * 14http://scm.host.org/there/master/?commit='
        . $c1->id
        . '' );
TestBot->expect( 'dummy/#test 12test/03there 05other '
        . $c2->id
        . ' 06Test U. Ser (06ser) 10b 03c a change in the other branch * 14http://scm.host.org/there/other/?commit='
        . $c2->id
        . '' );
TestBot->expect( 'dummy/#test 12test/03there 05tags '
        . $c2->id
        . ' 031.0-beta tag \'1.0-beta\' created * 14http://scm.host.org/there/tags/?commit='
        . $c2->id
        . '' );

##### annotated tag
mkdir( File::Spec->catdir($local, 'debian') );

w( File::Spec->catfile( 'debian', 'README' ),
    'You read this!? Good boy/girl.' );
$ign = $git->command( 'add', 'debian' );
do_commit( "add README for release\n\nas everybody knows, releases have to have READMEs\nHello, hi!" );
$ign = $git->command( 'tag', '-a', '-m', 'Release 1.0', '1.0-release' );
push_ok();

$c1 = $commit = $c->describe_commit;
ok( defined($commit), 'commit 6 present' );
is( $commit->id, shift @{ $commits{other} } );
is( $commit->branch, 'other' );
is( $commit->log, "add README for release\n\nas everybody knows, releases have to have READMEs\nHello, hi!" );
is( $commit->author, 'ser' );
is( scalar @{ $commit->changes }, 1 );
is( $commit->changes->[0]->as_string, '(A)debian/README' );

$tagged = $commit->id;

$c2 = $commit = $c->describe_commit;
ok( defined($commit), 'annotated tag here' );
is( $commit->branch, 'tags' );
is( $commit->author, 'ser' );
is( scalar( @{ $commit->changes } ), 1 );
is( $commit->changes->[0]->as_string, '(A)1.0-release' );
is( $commit->log,
    "Release 1.0 (tagged commit: $tagged)",
    'annotated tag log'
);

TestBot->expect( 'dummy/#test 12test/03there 05other '
        . $c1->id
        . ' 06Test U. Ser (06ser) 03debian/README add README for release * 14http://scm.host.org/there/other/?commit='
        . $c1->id
        . '' );
TestBot->expect( 'dummy/#test 12test/03there 05tags '
        . $c2->id
        . ' 06Test U. Ser (06ser) 031.0-release Release 1.0 (tagged commit: '
        . $c1->id
        . ') * 14http://scm.host.org/there/tags/?commit='
        . $c2->id
        . '' );

# a hollow branch

$ign = $git->command('branch', 'hollow');
push_ok();

# hollow branches are not detected for now

$commit = $c->describe_commit;
ok( defined($commit), 'hollow branch described' );
is( $commit->id, $tagged, "hollow commit is $tagged" );
is( $commit->branch, 'hollow', "hollow commit branch is 'hollow'" );
is( scalar( @{ $commit->changes } ), 0, "no changes in hollow commit" );
is( $commit->log, "branch created", "hollow commit log is 'branch created'" );

TestBot->expect( 'dummy/#test 12test/03there 05hollow '
        . $commit->id
        . ' branch created * 14http://scm.host.org/there/hollow/?commit='
        . $commit->id
        . '' );

$commit = $c->describe_commit;
ok( !defined($commit), 'hollow branch has no commits' );

# some UTF-8
w 'README', 'You dont read this!? Bad!';
$ign = $git->command( 'add', '.' );
do_commit( "update readme with an über cléver cómmít with cyrillics: привет" );
push_ok();

$commit = $c->describe_commit;
ok( defined($commit), 'UTF-8 commit exists' );
is( $commit->branch, 'other' );
is( $commit->author, 'ser' );
is( scalar( @{ $commit->changes } ), 1 );
is( $commit->log, "update readme with an über cléver cómmít with cyrillics: привет" );

TestBot->expect( 'dummy/#test 12test/03there 05other '
        . $commit->id
        . ' 06Test U. Ser (06ser) 03README update readme with an über cléver cómmít with cyrillics: привет * 14http://scm.host.org/there/other/?commit='
        . $commit->id
        . '' );

# parent-less branch
    write_tmp 'reflog', '';
$ign = $git->command( [ 'checkout', '--orphan', 'allnew' ], { STDERR => 0 } );
$ign = $git->command( 'rm', '-rf', '.' );
$ign = $git->command( 'commit', '--allow-empty', '-m', 'created empty branch allnew' );
$ign = $git->command( [ 'push', '-u', 'origin', 'allnew' ], { STDERR => 0 } );
    $c->_reset;
    $c->_detect_commits;

$commit = $c->describe_commit;
ok( defined($commit), 'empty branch creation commit exists' );
is( $commit->branch, 'allnew', 'empty branch name' );
is( $commit->log, "created empty branch allnew", 'empty branch log' );

TestBot->expect( 'dummy/#test 12test/03there 05allnew '
        . $commit->id
        . ' 06Test U. Ser (06ser) created empty branch allnew * 14http://scm.host.org/there/allnew/?commit='
        . $commit->id
        . '' );

##### No more commits after the last
$commit = $c->describe_commit;
is( $commit, undef );

# now the same on the master branch
$ign = $git->command( [ 'checkout', '-q', 'master' ], { STDERR => 0 } );
( my $gitversion = Git::command_oneline('version') ) =~ s/^git version\s*//;
my ( $major, $minor, $patch, $ignored ) = split( /\./, $gitversion );
note "Git version $major $minor";
if ( $major > 2 or $major == 2 and $minor >= 9 ) {  # 2.9.0+
    $ign = $git->command( 'merge', 'allnew', '--allow-unrelated-histories' );
} else {
    $ign = $git->command( 'merge', 'allnew' );
}
push_ok();
$c2 = $commit = $c->describe_commit;
ok( defined($commit), 'empty branch merge commit exists' );
is( $commit->branch, 'master' );
is( $commit->log, "Merge branch 'allnew'" );

TestBot->expect( 'dummy/#test 12test/03there 05master '
        . $c2->id
        . ' 06Test U. Ser (06ser) Merge branch \'allnew\' * 14http://scm.host.org/there/master/?commit='
        . $c2->id
        . '' );

$ign = $git->command( checkout => '-q', 'other' );
mkdir( File::Spec->catdir( $local, 'debian', 'patches' ) );

w( File::Spec->catfile( 'debian', 'patches', 'series' ), 'some.patch' );
w( File::Spec->catfile( 'debian', 'patches', 'some.patch' ), 'This is a patch' );

$ign = $git->command( add => 'debian' );
$ign = $git->command( commit => -m => 'A change in two files' );
push_ok();

$commit = $c->describe_commit;

TestBot->expect( 'dummy/#test 12test/03there 05other '
        . $commit->id
        . ' 06Test U. Ser (06ser) 10debian/patches/ 03series 03some.patch A change in two files * 14http://scm.host.org/there/other/?commit='
        . $commit->id
        . '' );

##### No more commits after the last
$commit = $c->describe_commit;
is( $commit, undef );
$commit = $c->describe_commit;
is( $commit, undef );

diag `cat $hook_log` if $hook_log and -s $hook_log;

my $output = $test_bot->get_output;

undef($test_bot);   # make sure all output us there

eq_or_diff( [split(/\n/, $output)], [split(/\n/, TestBot->expected_output)] );

$c->_reset;
write_tmp("reflog", '');
throws_ok { $c->describe_commit } qr/Reflog was empty/, 'should die without reflog data';

done_testing();
