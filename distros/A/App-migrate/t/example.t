use strict;
use POSIX qw(locale_h); BEGIN { setlocale(LC_MESSAGES,'en_US.UTF-8') } # avoid UTF-8 in $!
use Test::More;
use Test::Exception;
use Test::Output qw( :all );
use Path::Tiny qw( path tempdir tempfile );
use App::migrate;

plan skip_all => 'pgrep not installed'      if !grep {-x "$_/pgrep"} split /:/, $ENV{PATH};


my $migrate = App::migrate->new;
my $file    = tempfile('migrate.XXXXXX');

my $proj    = tempdir('migrate.project.XXXXXX');
my $guard   = bless {};
sub DESTROY { chdir q{/} }
chdir $proj or die "chdir($proj): $!";

my (@backup, @restore);
$migrate->on(BACKUP  => sub { push @backup,  shift->{version} });
$migrate->on(RESTORE => sub { push @restore, shift->{version} });
$migrate->on(error   => sub { diag 'on ERROR was called'      });

ok $migrate, 'new';

# Make sure example from documentation actually works
$file->spew_utf8(<<'MIGRATE');
VERSION 0.0.0
# To upgrade from 0.0.0 to 0.1.0 we need to create new empty file and
# empty directory.
upgrade     touch   empty_file
downgrade   rm      empty_file
upgrade     mkdir   empty_dir
downgrade   rmdir   empty_dir
VERSION 0.1.0
# To upgrade from 0.1.0 to 0.2.0 we need to drop old database. This
# change can't be undone, so only way to downgrade from 0.2.0 is to
# restore 0.1.0 from backup.
upgrade     rm      useless.db
RESTORE
VERSION 0.2.0
# To upgrade from 0.2.0 to 1.0.0 we need to run several commands,
# and after downgrading we need to kill some background service.
before_upgrade
  patch -E   <0.2.0.patch >/dev/null
  rm -f *.orig
  chmod +x some_daemon
downgrade
  patch -E -R <0.2.0.patch >/dev/null
  rm -f *.orig
upgrade
  ./some_daemon &
after_downgrade
  pkill -9 -x -f '/bin/sh ./some_daemon'
VERSION 1.0.0

# Let's define some lazy helpers:
DEFINE2 only_upgrade
upgrade
downgrade true

DEFINE2 mkdir
upgrade
  mkdir "$@"
downgrade
  rm -rf "$@"

# ... and use it:
only_upgrade
  echo "Just upgraded to $MIGRATE_NEXT_VERSION"

VERSION 1.0.1

# another lazy macro (must be defined above in same file)
mkdir dir1 dir2

VERSION 1.1.0
MIGRATE

lives_ok { $migrate->load($file) } 'load';

subtest '0.0.0 <-> 0.1.0', sub {
    ok !$proj->children,                    'proj is empty';
    run('0.0.0' => '0.1.0');
    is $proj->children, 2,                  'proj is not empty:';
    ok $proj->child('empty_file')->is_file, '... has empty_file';
    ok $proj->child('empty_dir')->is_dir,   '... has empty_dir/';

    run('0.1.0' => '0.0.0');
    ok !$proj->children,                    'proj is empty';

    done_testing;
};

subtest '0.1.0 <-> 0.2.0', sub {
    path('useless.db')->touch;
    ok -e 'useless.db', 'created useless.db';
    run('0.1.0' => '0.2.0');
    ok !-e 'useless.db', 'useless.db was removed';

    run('0.2.0' => '0.1.0');
    is_deeply \@restore, [qw(0.1.0)], '... RESTORE 0.1.0';

    done_testing;
};

subtest '0.2.0 <-> 1.0.0', sub {
    path('0.2.0.patch')->spew_utf8(<<'PATCH');
diff -uNr some_daemon some_daemon
--- some_daemon	1970-01-01 03:00:00.000000000 +0300
+++ some_daemon	2015-02-24 06:34:47.321969399 +0200
@@ -0,0 +1,2 @@
+#!/bin/sh
+kill -STOP $$
PATCH

    run('0.2.0' => '1.0.0');
    ok -e 'some_daemon', '... ./some_daemon exists';

SKIP: {
    skip 'unstable on CPAN Testers', 1 if !$ENV{RELEASE_TESTING} && ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CPAN_REPORTER_CONFIG});
    is system('pgrep -x -f "/bin/sh ./some_daemon" >/dev/null'), 0, '... some_daemon is running';
}

    run('1.0.0' => '0.2.0');
SKIP: {
    skip 'unstable on CPAN Testers', 1 if !$ENV{RELEASE_TESTING} && ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CPAN_REPORTER_CONFIG});
    isnt system('pgrep -x -f "/bin/sh ./some_daemon" >/dev/null'), 0, '... some_daemon is not running';
}
    ok !-e 'some_daemon', '... ./some_daemon does not exists';

    path('0.2.0.patch')->remove;
    done_testing();
};

subtest '1.0.0 -> 1.0.1', sub {
    run('1.0.0' => '1.0.1', "Just upgraded to 1.0.1\n"."\n", undef, 'echo was run');
    run('1.0.1' => '1.0.0',                            "\n", undef, 'nothing was run');
    done_testing;
};

subtest '1.0.1 -> 1.1.0', sub {
    ok !$proj->children, 'proj is empty';
    run('1.0.1' => '1.1.0');
    ok -d 'dir1', '... dir1/ exists';
    ok -d 'dir2', '... dir2/ exists';
    run('1.1.0' => '1.0.1');
    ok !$proj->children, 'proj is empty';
};


done_testing;


sub run {
    my ($from, $to, $wantout, $wanterr, $msg) = @_;
    lives_ok {
        my ($stdout, $stderr) = output_from sub {
            $migrate->run( $migrate->find_paths($from => $to) )
        };
        is $stdout, $wantout, ($msg ? "(stdout) $msg" : ()) if defined $wantout;
        is $stderr, $wanterr, ($msg ? "(stderr) $msg" : ()) if defined $wanterr;
    } "$from -> $to";
}
