use strict;
use warnings;

use autodie qw(:all);
use File::Spec::Functions qw( catdir catfile );
use Test::More;
use Test::Differences;
use lib 't';
use TestBot;
use POSIX qw(setlocale LC_CTYPE);

BEGIN {
    eval { require SVN::Core; 1 }
        or plan skip_all => "SVN::Core required for testing the Subversion client";
    eval { require SVN::Fs; 1 }
        or plan skip_all => "SVN::Fs required for testing the Subversion client";
    eval { require SVN::Repos; 1 }
        or plan skip_all => "SVN::Repos required for testing the Subversion client";
};

use utf8;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $test_bot = TestBot->start;

diag sprintf( "Test bot started on %s:%d", $test_bot->addr, $test_bot->port );

use File::Temp qw(tempdir);
my $r = tempdir( CLEANUP => not $ENV{TEST_KEEP_TEMP} );
diag "Temporary directory $r will be kept" if $ENV{TEST_KEEP_TEMP};

my $repo = catdir( $r,     'repo' );
my $wd   = catdir( $r,     'checkout' );
my $tf = catfile( $wd, 'file' );

sub poke {
    my $f;
    open $f, ">", $tf;
    print $f @_;
    close $f;
}

sub in_wd {
    system 'sh', '-c', "cd $wd && " . shift;
}

system 'svnadmin', 'create', $repo;

use Cwd;
my $hook_log = catdir( $r, 'hook.log' );

# the real test client
{
    my $R = getcwd;
    my $client_script = $ENV{KGB_CLIENT_SCRIPT} || "$R/script/kgb-client";
    my $ccf = $test_bot->client_config_file;
    open my $fh, '>', "$repo/hooks/post-commit";
    print $fh <<EOF;
#!/bin/sh

PERL5LIB=$R/lib $^X -- $client_script --conf $ccf \$1 \$2 >> $hook_log 2>&1
EOF
    close $fh;
    chmod 0755, "$repo/hooks/post-commit";
}

# duplicate, talking to a different bot, connected to IRC
if ( $ENV{TEST_KGB_BOT_RUNNING} ) {
    diag "will try to send notifications to locally running bot";
    my $R = getcwd;
    my $h;
    open $h, '>>', "$repo/hooks/post-commit";
    print $h <<"EOF";

PERL5LIB=$R/lib $^X -- $R/script/kgb-client --conf $R/eg/test-client.conf --status-dir $r \$1 \$2 >> /dev/null
EOF
    close $h;
}
system 'svn', 'checkout', "file://$repo", $wd;

poke('one');
in_wd "svn add $tf";
in_wd "svn ci -m 'add file'";

TestBot->expect(
    "dummy/#test ${TestBot::COMMIT_USER} 1 12test/ 03/file add file * 14http://scm.host.org///?commit=1"
);

poke('two');
in_wd "svn ci -m 'modify file'";

TestBot->expect(
    "dummy/#test ${TestBot::COMMIT_USER} 2 12test/ 10/file modify file * 14http://scm.host.org///?commit=2"
);

in_wd "svn rm file";
poke('three');
in_wd "svn add file";
in_wd "svn ci -m 'replace file'";

TestBot->expect(
    "dummy/#test ${TestBot::COMMIT_USER} 3 12test/ 05/file replace file * 14http://scm.host.org///?commit=3"
);

ok( 1, "Test repository prepared" );

use App::KGB::Client::Subversion;
use App::KGB::Client::ServerRef;

my $port = 7645;
my $password = 'v,sjflir';

my $c = new_ok(
    'App::KGB::Client::Subversion' => [
        {   repo_id => 'test',
            servers => [
                App::KGB::Client::ServerRef->new(
                    {   uri      => "http://127.0.0.1:$port/",
                        password => $password,
                    }
                ),
            ],

            #br_mod_re      => \@br_mod_re,
            #br_mod_re_swap => $br_mod_re_swap,
            #ignore_branch  => $ignore_branch,
            repo_path => $repo,
            revision  => 1,
        }
    ]
);

my $commit = $c->describe_commit;

my $me = getpwuid($>);

is( $commit->id, 1 );
is( $commit->log, 'add file' );
diag "\$>=$> \$<=$< \$ENV{USER}=$ENV{USER} getpwuid(\$>)=$me";
is( $commit->author, $me );
is( scalar @{ $commit->changes }, 1 );

my $change = $commit->changes->[0];
is( $change->path, '/file' );
ok( not $change->prop_change );
is( $change->action, 'A' );

$c->revision(2);
$c->_called(0);
$commit = $c->describe_commit;

is( $commit->id, 2 );
is( $commit->log, 'modify file' );
is( $commit->author, $me );
is( scalar @{ $commit->changes }, 1 );

$change = $commit->changes->[0];
is( $change->path, '/file' );
ok( not $change->prop_change );
is( $change->action, 'M' );

$c->revision(3);
$c->_called(0);
$commit = $c->describe_commit;

is( $commit->id, 3 );
is( $commit->log, 'replace file' );
is( $commit->author, $me );
is( scalar @{ $commit->changes }, 1 );

$change = $commit->changes->[0];
is( $change->path, '/file' );
ok( not $change->prop_change );
is( $change->action, 'R' );

SKIP: {
    skip "UTF-8 locale needed for the test with UTF-8 commit message", 7,
        unless ( ( setlocale(LC_CTYPE) // '' ) =~ /utf-8$/i );

    in_wd "svn rm file";
    in_wd "svn ci -m 'remove file. Über cool with cyrillics: здрасти'";

    TestBot->expect( "dummy/#test "
        . ${TestBot::COMMIT_USER}
        . " 4 12test/ 04/file "
        . "remove file. Über cool with cyrillics: здрасти "
        . "* 14http://scm.host.org///?commit=4");

    $c->revision(4);
    $c->_called(0);
    $commit = $c->describe_commit;

    is( $commit->id, 4 );
    is( $commit->log, 'remove file. Über cool with cyrillics: здрасти' );
    is( $commit->author, $me );
    is( scalar @{ $commit->changes }, 1 );

    $change = $commit->changes->[0];
    is( $change->path, '/file' );
    ok( not $change->prop_change );
    is( $change->action, 'D' );
}

diag `cat $hook_log` if $hook_log and -s $hook_log;

my $output = $test_bot->get_output;

undef($test_bot);   # make sure all output us there
unified_diff;

eq_or_diff( $output, TestBot->expected_output );

done_testing();
