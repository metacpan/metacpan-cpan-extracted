use strictures 2;
use Test::More;
use File::chdir;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture);
use IPC::System::Simple ();
use Mojo::File qw(path); sub slurp { path($_[0])->slurp }
use Import::Into;

my $test_cwd = $CWD;

delete @ENV{grep /^OPAN_/, keys %ENV};

my $tempdir = tempdir(CLEANUP => 1);

sub entries_for {
  my ($pan) = @_;
  App::opan::entries_from_packages_file($tempdir."/pans/${pan}/index");
}

sub App::opan::gmtime { 'TIME GOES HERE' }

subs->import::into('App::opan', 'gmtime');

my $app = require "./script/opan";

sub run {
  local $CWD = $tempdir;
  local $ENV{OPAN_MIRROR} = '/fakepan/';
  my @args = @_;
  my ($stdout, $stderr) = capture { $app->start(@args) };
  diag("STDERR for ".join(' ', @args)." was\n".$stderr) if $stderr;
  #is($stderr, '', 'No stderr output running '.join(' ', @args));
  return $stdout;
}

$app->ua->server->app(my $fakepan = Mojolicious->new);

$fakepan->log->level('fatal');

$fakepan->routes->tap(sub {
  $_[0]->get('/fakepan/modules/02packages.details.txt.gz' => sub {
    $_[0]->render(data =>
      scalar IPC::System::Simple::capture(
        gzip => '-c', $test_cwd.'/t/fix/upstream.fragment'
      )
    );
  });
  foreach my $f (map "AAAAAAAAA-1.0${_}.tar.gz", qw(0 1)) {
    $_[0]->get("/fakepan/authors/id/M/MS/MSCHWERN/${f}" => sub {
      $_[0]->reply->asset(
        Mojo::Asset::File->new(
          path => $test_cwd.'/t/fix/'.$f
        )
      );
    });
  }
});

run('init');

is(
  slurp($tempdir.'/pans/upstream/index'),
  slurp('t/fix/upstream.fragment'),
  'init fetch ok'
);

foreach my $pan (qw(pinset custom)) {

  is(
    slurp($tempdir."/pans/${pan}/index"),
    slurp('t/fix/empty.index'),
    "index for ${pan} initialized ok"
  );
}

foreach my $pan (qw(nopin combined)) {
  is_deeply(
    entries_for('upstream'), entries_for($pan),
    "index for ${pan} initialized ok"
  );
}

my $aaa = slurp('t/fix/AAAAAAAAA-1.00.tar.gz');

foreach my $pan (qw(upstream nopin combined)) {
  ok(
    run(get => "/${pan}/authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.00.tar.gz")
    eq $aaa,
    "Served upstream tarball via ${pan}"
  );
}

eval { run(pin => 'X/Y-0.00.tar.gz') };
like $@, qr{^GET .*X/Y-0\.00\.tar\.gz: Not Found\n}, 'invalid pin distro';

run(pin => 'MSCHWERN/AAAAAAAAA-1.00.tar.gz');

ok(
  -f $tempdir.'/pans/pinset/dists/M/MS/MSCHWERN/AAAAAAAAA-1.00.tar.gz',
  'Pinned dist copied into pinset'
);

is_deeply(
  entries_for('pinset'),
  [ [ 'AAAAAAAAA', '1.00', 'M/MS/MSCHWERN/AAAAAAAAA-1.00.tar.gz' ] ],
  'Pinned dist indexed'
);

run(add => $test_cwd.'/t/fix/M-1.tar.gz');

ok(
  -f $tempdir.'/pans/custom/dists/M/MY/MY/M-1.tar.gz',
  'Added dist copied into custom'
);

is_deeply(
  entries_for('custom'),
  [ [ 'M', '1', 'M/MY/MY/M-1.tar.gz' ] ],
  'Custom dist indexed'
);

run(merge =>);

{
  my %entries = map +($_ => entries_for($_)),
                  qw(upstream pinset custom nopin combined);

  foreach my $test (
    [ combined => A_Third_Package => upstream => ],
    [ nopin => A_Third_Package => upstream => ],
    [ combined => M => custom => ],
    [ nopin => M => custom => ],
    [ combined => AAAAAAAAA => pinset => ],
    [ nopin => AAAAAAAAA => upstream => ],
  ) {
    my ($in_pan, $module, $from_pan) = @$test;
    is(
      (grep $_->[0] eq $module, @{$entries{$in_pan}})[0][2],
      (grep $_->[0] eq $module, @{$entries{$from_pan}})[0][2],
      "Entry in ${in_pan} for ${module} is from ${from_pan}"
    );
  }
}

run(add => $test_cwd.'/t/fix/M-1.000001.tar.gz');

ok(
  -f $tempdir.'/pans/custom/dists/M/MY/MY/M-1.000001.tar.gz',
  'Added dist copied into custom'
);

is_deeply(
  entries_for('custom'),
  [ [ 'M', '1.000001', 'M/MY/MY/M-1.000001.tar.gz' ] ],
  'Custom dist indexed'
);

run(unpin => 'AAAAAAAAA-1.00.tar.gz');

is_deeply(
  entries_for('pinset'),
  [],
  'Pinset remove ok'
);

is(
  run(purgelist =>),
  "pans/pinset/dists/M/MS/MSCHWERN/AAAAAAAAA-1.00.tar.gz\n"
  ."pans/custom/dists/M/MY/MY/M-1.tar.gz\n",
  'Purgelist ok'
);

run(purge =>);

ok(
  !-f $tempdir.'/pans/custom/dists/M/MY/MY/M-1.tar.gz',
  'Added dist purged from custom'
);

ok(
  !-f $tempdir.'/pans/pinset/dists/M/MS/MSCHWERN/AAAAAAAAA-1.00.tar.gz',
  'Pinned dist purged from pinset'
);

{
  local $ENV{OPAN_AUTOPIN} = 1;
  is(
    run(get => '/autopin/modules/02packages.details.txt'),
    run(get => '/nopin/modules/02packages.details.txt'),
    'autopin pan provides same index as nopin'
  );

  run(get => '/autopin/authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz');

  is_deeply(
    entries_for('pinset'),
    [ [ 'AAAAAAAAA', '1.01', 'M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz' ] ],
    'Autopin did, indeed, automatically pin the dist'
  );
}

# 0 for release, 1 for debugging, not allowed to barf

if (0) {
  warn "Tempdir is $tempdir; hit enter to finish and cleanup\n";
  <STDIN>;
}

done_testing;
