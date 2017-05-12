use strict;
use warnings;
BEGIN { $^O eq 'MSWin32' ? eval q{ use Event; 1 } || q{ use EV } : eval q{ use EV } }
use Test::More;

use File::Temp qw(tempdir);
use IO::File;
use AnyEvent;
use AnyEvent::Git::Wrapper;
use File::Spec;
use File::Path qw(mkpath);
use POSIX qw(strftime);
use Sort::Versions;
use Test::Deep;
use Test::Exception;

#my $global_timeout = AE::timer 30, 0, sub { say STDERR "TIMEOUT!"; exit 2 };

my $dir = tempdir(CLEANUP => 1);

my $git = AnyEvent::Git::Wrapper->new($dir);

my $version = $git->version(AE::cv)->recv;
if ( versioncmp( $git->version(AE::cv)->recv , '1.5.0') eq -1 ) {
  plan skip_all =>
    "Git prior to v1.5.0 doesn't support 'config' subcmd which we need for this test."
}

#diag( "Testing git version: " . $version );

$git->init(AE::cv)->recv; # 'git init' also added in v1.5.0 so we're safe

$git->config( 'user.name'  , 'Test User'        , AE::cv)->recv;
$git->config( 'user.email' , 'test@example.com' , AE::cv)->recv;

# make sure git isn't munging our content so we have consistent hashes
$git->config( 'core.autocrlf' , 'false' , AE::cv)->recv;
$git->config( 'core.safecrlf' , 'false' , AE::cv)->recv;

mkpath(File::Spec->catfile($dir, 'foo'));

IO::File->new(File::Spec->catfile($dir, qw(foo bar)), '>:raw')->print("hello\n");

$git->ls_files({ o => 1 }, sub {
  my($out, $err) = shift->recv;
  is_deeply( $out, [ 'foo/bar' ] , 'ls_files -o');
})->recv;

$git->add('.', AE::cv)->recv;

$git->ls_files(sub {
  my($out, $err) = shift->recv;
  is_deeply( $out, [ 'foo/bar' ] , 'ls_files -o');
})->recv;

SKIP: {
  skip 'testing old git without porcelain' , 1 unless $git->supports_status_porcelain;
  is( $git->status(AE::cv)->recv->is_dirty , 1 , 'repo is dirty' );
}

my $time = time;
$git->commit({ message => "FIRST\n\n\tBODY\n" }, AE::cv)->recv;

SKIP: {
  skip 'testing old git without porcelain' , 1 unless $git->supports_status_porcelain;
  is( $git->status(AE::cv)->recv->is_dirty , 0 , 'repo is clean' );
}


my @rev_list;

$git->rev_list({ all => 1, pretty => 'oneline' }, sub {
  my($out, $err) = shift->recv;
  @rev_list= @$out;
  is(@rev_list, 1);
  like($rev_list[0], qr/^[a-f\d]{40} FIRST$/);
})->recv;

my $args = $git->supports_log_raw_dates ? { date => 'raw' } : {};
my @log = $git->log( $args , AE::cv)->recv;
is(@log, 1, 'one log entry');

my $log = $log[0];
is($log->id, (split /\s/, $rev_list[0])[0], 'id');
like($log->message, qr/FIRST\n\n(\t|        )BODY\n/, 'message');

SKIP: {
  skip 'testing old git without raw date support' , 1
    unless $git->supports_log_raw_dates;

  my $log_date = $log->date;
  $log_date =~ s/ [+-]\d+$//;
  cmp_ok(( $log_date - $time ), '<=', 5, 'date');
}

SKIP:
{
  skip 'testing old git without no abbrev commit support' , 1
    unless $git->supports_log_no_abbrev_commit;

  $git->config( 'log.abbrevCommit', 'true' , AE::cv)->recv;

  @log = $git->log( $args , AE::cv)->recv;

  $log = $log[0];
  is($log->id, (split /\s/, $rev_list[0])[0], 'id');
}

SKIP:
{
  if ( versioncmp( $git->version , '1.6.3') eq -1 ) {
    skip 'testing old git without log --oneline support' , 3;
  }

  throws_ok { $git->log('--oneline', AE::cv)->recv } qr/^unhandled/ , 'log(--oneline) dies';

  $git->RUN('log', '--oneline', sub {
    my($out, $err) = shift->recv;
    my @lines = @$out;
    lives_ok { @lines  } 'RUN(log --oneline) lives';
    is( @lines , 1 , 'one log entry' );
  });
}

my @raw_log = $git->log({ raw => 1 }, AE::cv)->recv;
is(@raw_log, 1, 'one raw log entry');

SKIP: {
    if ( versioncmp( $git->version , '1.7.0.5') eq -1 ) {
      skip 'testing old git without commit --allow-empty-message support' , 1;
    }

    # Test empty commit message
    IO::File->new(">" . File::Spec->catfile($dir, qw(second_commit)))->print("second_commit\n");
    $git->add('second_commit', AE::cv)->recv;

    do {
      my $cv = AE::cv;
      my $w = AE::timer 5, 0, sub { $cv->send(0) };
      $git->commit(sub { $cv->send(1)});
      ok $cv->recv, 'Attempt to commit interactively fails quickly';
    };
    
    my $error;
    my $timeout = do {
      my $cv = AE::cv;
      my $w = AE::timer 5, 0, sub { $cv->send(1) };
      $git->commit({ message => "", 'allow-empty-message' => 1 }, sub { $error = $@ unless eval { shift->recv }; $cv->send(0) });
      $cv->recv;
    };

    if ( $error && !$timeout ) {
      my $msg = substr($error,0,50);
      skip $msg, 1;
    }

    @log = $git->log(AE::cv)->recv;
    is(@log, 2, 'two log entries, one with empty commit message');
};


# test --message vs. -m
my @arg_tests = (
    ['message', 'long_arg_no_spaces',   'long arg, no spaces in val',  ],
    ['message', 'long arg with spaces', 'long arg, spaces in val',     ],
    ['m',       'short_arg_no_spaces',  'short arg, no spaces in val', ],
    ['m',       'short arg w spaces',   'short arg, spaces in val',    ],
);

my $arg_file = IO::File->new('>' . File::Spec->catfile($dir, qw(argument_testfile)));

for my $arg_test (@arg_tests) {
    my ($flag, $msg, $descr) = @$arg_test;

    $arg_file->print("$msg\n");
    $git->add('argument_testfile', AE::cv)->recv;
    $git->commit({ $flag => $msg }, AE::cv)->recv;

    my ($arg_log) = $git->log('-n 1', AE::cv)->recv;

    is $arg_log->message, "$msg\n", "argument test: $descr";
}

$git->checkout({b => 'new_branch'}, AE::cv)->recv;

$git->branch(sub {
  my $out = shift->recv;
  my ($new_branch) = grep {m/^\*/} @$out;
  $new_branch =~ s/^\*\s+|\s+$//g;
  is $new_branch, 'new_branch', 'new branch name is correct';
})->recv;


SKIP: {
  skip 'testing old git without no-filters' , 1 unless $git->supports_hash_object_filters;

  my $cv = $git->hash_object({
    no_filters => 1,
    stdin      => 1,
    -STDIN     => 'content to hash',
  }, AE::cv);

  my $out = $cv->recv;
  my $hash = $out->[0];
  is $hash, '4b06c1f876b16951b37f4d6755010f901100f04e',
    'passing content with -STDIN option';
}

done_testing;
