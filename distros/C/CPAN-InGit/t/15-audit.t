#! /usr/bin/perl
use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use File::Temp;
use Git::Raw;
use JSON::PP;
use CPAN::InGit;
use CPAN::InGit::Advisories;
use v5.36;

my $feed_json= "WARNING: this text precedes the JSON\n" . JSON::PP->new->canonical->encode({
   Example => [
      { id => 'CPANSA-Example-2025-01', cves => ['CVE-2025-0001'], severity => 'high', reported => '2025-01-02',
        affected_versions => ['<1.02'], fixed_versions => ['>=1.02'], description => 'Bad thing' },
      { id => 'CPANSA-Example-2019-01', cves => ['CVE-2019-0009'], affected_versions => ['<0.50'] },
   ],
   Vuln    => [ { id => 'CPANSA-Vuln-2024-01', cves => [], affected_versions => ['>=1.0,<3.0', '==0.5'] } ],
   Current => [ { cves => ['CVE-2020-0001'], affected_versions => ['<0.9'] } ],
   Always  => [ { cves => ['CVE-2021-0001'] } ],
   Odd     => [ { cves => ['CVE-2022-0001'], affected_versions => ['before 2.0'] } ],
});

subtest advisories => sub {
   my $adv= CPAN::InGit::Advisories->new_from_json($feed_json);
   my $ids= sub (@args) { [ map @{ $_->{ids} }, $adv->affecting(@args) ] };
   is( [ $adv->affecting('Example', '1.00') ],
      [ { ids => [ 'CVE-2025-0001', 'CPANSA-Example-2025-01' ], severity => 'high', reported => '2025-01-02',
          affected_versions => ['<1.02'], fixed_versions => ['>=1.02'], description => 'Bad thing' } ],
      'advisory fields' );
   is( $ids->('Example', '1.02'), [], 'fixed version is not affected' );
   is( $ids->('Example', '0.49'), [ 'CVE-2025-0001', 'CPANSA-Example-2025-01', 'CVE-2019-0009', 'CPANSA-Example-2019-01' ], 'two advisories' );
   is( $ids->('Example', '1.01_01'), [ 'CVE-2025-0001', 'CPANSA-Example-2025-01' ], 'underscore ignored' );
   is( $ids->('Vuln', '2.0'), ['CPANSA-Vuln-2024-01'], 'comparisons are ANDed' );
   is( $ids->('Vuln', '3.0'), [], 'outside of ANDed range' );
   is( $ids->('Vuln', '0.5'), ['CPANSA-Vuln-2024-01'], 'ranges are ORed' );
   is( $ids->('Vuln', '0.6'), [], 'outside every range' );
   is( $ids->('Always', '99'), ['CVE-2021-0001'], 'no ranges means every version' );
   is( $ids->('Odd', '5'), ['CVE-2022-0001'], 'unreadable range is reported rather than hidden' );
   is( $ids->('Unknown', '1'), [], 'unknown dist' );
   is( $ids->('Example', 'banana'), [], 'unparseable version' );
   is( [ map @{ $_->{ids} }, $adv->affecting_path('A/AU/AUTHOR/Example-1.00.tar.gz') ],
      [ 'CVE-2025-0001', 'CPANSA-Example-2025-01' ], 'affecting_path' );
   is( [ $adv->affecting_path('A/AU/AUTHOR/Example-1.02-TRIAL.tar.gz') ], [], 'affecting_path, TRIAL release' );
   is( [ $adv->affecting_path('modules/02packages.details.txt') ], [], 'affecting_path of a non-dist' );

   my $v= sub ($s) { CPAN::InGit::Advisories->parse_version($s) };
   ok( $v->('1.002003') == $v->('v1.2.3'), 'decimal and dotted versions compare as perl does' );
   ok( $v->('1.23') != $v->('v1.23'), '1.23 is not v1.23' );
   ok( $v->('1.10') < $v->('1.9'), 'decimal 1.10 < 1.9' );
   ok( $v->('1.10.0') > $v->('1.9.0'), 'dotted 1.10.0 > 1.9.0' );
   is( $v->('1.x'), undef, 'not a version' );
   like( dies { CPAN::InGit::Advisories->new_from_json('<html>not found</html>') }, qr/Missing CPANSA JSON/, 'not a feed' );
};

my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
my $git_repo= Git::Raw::Repository->init($repodir, 1);
my $cpan_repo= CPAN::InGit->new(repo => $git_repo);

{
   package FakeUA;
   sub new($class) { bless { requests => [], response => [ 200, '' ] }, $class }
   sub get($self, $url, $headers={}) {
      push @{ $self->{requests} }, { url => $url, %$headers };
      return bless { r => $self->{response} }, 'FakeUA::Tx';
   }
   package FakeUA::Tx;
   sub result($self)     { $self }
   sub code($self)       { $self->{r}[0] }
   sub message($self)    { 'Message' }
   sub is_success($self) { $self->{r}[0] == 200 }
   sub body($self)       { $self->{r}[1] }
}

subtest load_advisories => sub {
   my $ua= FakeUA->new;
   my $repo= CPAN::InGit->new(repo => $git_repo, useragent => $ua);
   my $path= $repo->cve_feed_path;
   is( $path, $git_repo->path.'cpan-ingit-cpansa.json', 'default path is in the git dir' );
   like( dies { $repo->load_advisories(refresh => 0) }, qr/No copy of the CVE list/, 'no copy and no network' );

   $ua->{response}= [ 500, 'oops' ];
   like( dies { $repo->load_advisories }, qr/Can't download the CVE list: 500/, 'download fails without a copy' );
   $ua->{response}= [ 200, '<html>captive portal</html>' ];
   like( dies { $repo->load_advisories }, qr/Can't download the CVE list: Missing CPANSA JSON/, 'download of a non-feed' );
   ok( !-e $path, 'nothing was written' );

   $ua->{response}= [ 200, $feed_json ];
   $ua->{requests}= [];
   my $adv= $repo->load_advisories;
   is( $ua->{requests}, [ { url => $repo->cve_feed_url } ], 'unconditional download' );
   is( slurp($path), $feed_json, 'feed written to file' );
   is( $adv, object { call source_path => $path; call fetched => T; }, 'attributes' );
   is( scalar $adv->affecting('Example', '1.00'), 1, 'usable' );
   is( [ glob "$path.*" ], [], 'no temp files left' );

   $ua->{requests}= [];
   $repo->load_advisories;
   is( $ua->{requests}, [], 'recent copy is used without a request' );

   my $old= time - 86400*3;
   utime $old, $old, $path;
   $ua->{response}= [ 304, '' ];
   $adv= $repo->load_advisories;
   is( $ua->{requests}, [ { url => $repo->cve_feed_url, 'If-Modified-Since' => match qr/GMT\z/ } ], 'conditional request for an old copy' );
   ok( $adv->fetched > time - 60, 'file was touched after 304' );
   is( slurp($path), $feed_json, 'file unchanged after 304' );

   utime $old, $old, $path;
   $ua->{response}= [ 503, '' ];
   $adv= $repo->load_advisories;
   is( $adv->fetched, $old, 'old copy used when the refresh fails' );
   $ua->{response}= [ 200, 'garbage' ];
   $repo->load_advisories(refresh => 1);
   is( slurp($path), $feed_json, 'a non-feed does not replace the copy' );

   my $other= "$repodir/other.json";
   $ua->{response}= [ 200, '{"Other":[]}' ];
   $adv= $repo->load_advisories(path => $other);
   is( slurp($other), '{"Other":[]}', 'path option downloads to that file' );
   is( $adv->source_path, $other, 'source_path' );
   unlink $path;
};

# The app has an old Example, which has since been split into two dists and lost a module
my %src= (
   'A/AU/AUTHOR/Example-1.02.tar.gz'      => { 'Example' => '1.02' },
   'A/AU/AUTHOR/Example-Util-0.01.tar.gz' => { 'Example::Util' => '1.01' },
   'A/AU/AUTHOR/Example-1.00.tar.gz'      => { 'Example::Old' => '1.00' },
   'V/VU/VULN/Vuln-2.0.tar.gz'            => { 'Vuln' => '2.0' },
   'C/CU/CURRENT/Current-1.0.tar.gz'      => { 'Current' => '1.0' },
   'P/PA/PAT/Patched-1.5.tar.gz'          => { 'Patched' => '1.5' },
   'A/AH/AHEAD/Ahead-1.0.tar.gz'          => { 'Ahead' => '1.0' },
);
my %app= (
   'A/AU/AUTHOR/Example-1.00.tar.gz'      => { 'Example' => '1.00', 'Example::Util' => '1.00',
                                               'Example::Old' => '1.00', 'Example::Private' => '1.00' },
   'V/VU/VULN/Vuln-2.0.tar.gz'            => { 'Vuln' => '2.0' },
   'C/CU/CURRENT/Current-1.0.tar.gz'      => { 'Current' => '1.0' },
   'L/LO/LOCAL/Patched-1.5.tar.gz'        => { 'Patched' => '1.5' },
   'A/AH/AHEAD/Ahead-2.0.tar.gz'          => { 'Ahead' => '2.0' },
   'P/PR/PRIVATE/Private-1.0.tar.gz'      => { 'Private' => '1.0' },
);
{
   my $source= $cpan_repo->create_archive_tree('source');
   $source->index_distribution($_, $src{$_}) for sort keys %src;
   $source->commit('index');
   my $app= $cpan_repo->create_archive_tree('app', default_import_sources => ['source']);
   $app->index_distribution($_, $app{$_}) for sort keys %app;
   $app->commit('index');
   $cpan_repo->create_archive_tree('lonely');
}

my $expected_upgrades= [
   {
      author_path => 'A/AU/AUTHOR/Example-1.00.tar.gz', dist => 'Example', version => '1.00',
      upgrades => [
         { author_path => 'A/AU/AUTHOR/Example-1.02.tar.gz', dist => 'Example', version => '1.02',
           source => 'source', kind => 'upgrade', modules => { 'Example' => [ '1.00', '1.02' ] } },
         { author_path => 'A/AU/AUTHOR/Example-Util-0.01.tar.gz', dist => 'Example-Util', version => '0.01',
           source => 'source', kind => 'moved', modules => { 'Example::Util' => [ '1.00', '1.01' ] } },
      ],
      left_behind   => ['Example::Old'],
      not_in_source => ['Example::Private'],
   },
];

subtest find_upgrades => sub {
   my $app= $cpan_repo->get_archive_tree('app');
   is( $app->find_upgrades, $expected_upgrades, 'grouped by (dist here, dist there)' );
   is( $app->find_upgrades(sources => []), [], 'no sources' );
   is( $cpan_repo->get_archive_tree('source')->find_upgrades(sources => [ $app ]),
      [ { author_path => 'A/AH/AHEAD/Ahead-1.0.tar.gz', dist => 'Ahead', version => '1.0',
          upgrades => [ { author_path => 'A/AH/AHEAD/Ahead-2.0.tar.gz', dist => 'Ahead', version => '2.0',
                          source => 'app', kind => 'upgrade', modules => { Ahead => [ '1.0', '2.0' ] } } ] } ],
      'reverse direction' );
};

subtest cpangit_audit => sub {
   my $feed_file= "$repodir/feed.json";
   mkfile($feed_file, $feed_json);
   my @cmd= ($^X, "-I$FindBin::Bin/../lib", "$FindBin::Bin/../bin/cpangit-audit", "--git-dir=$repodir");
   my $run= sub (@args) {
      my $errfile= File::Temp->new;
      open my $saved_err, '>&', \*STDERR or die "dup: $!";
      open STDERR, '>', "$errfile" or die "reopen: $!";
      my $pid= open my $fh, '-|', @cmd, @args or die "fork: $!";
      my $out= do { local $/; <$fh> };
      close $fh;
      my $exit= $? >> 8;
      open STDERR, '>&', $saved_err or die "restore: $!";
      return ($out, $exit, slurp("$errfile"));
   };
   my @common= ('--branch=app', "--cve-file=$feed_file", '--no-fetch');

   my ($out, $exit, $err)= $run->(@common);
   is( $exit, 0, 'exit status without assertions' );
   like( $err, qr/\ACVE list: \Q$feed_file\E \(fetched just now\)\n\z/, 'CVE list announced on STDERR' );
   is( $out, <<~END, 'text' );
      Example-1.00 -> Example-1.02  (source)  CVE: CVE-2025-0001  [fixed by upgrade]
      Example-1.00 -> Example-Util-0.01  (source)  moved: Example::Util  CVE: CVE-2025-0001  [fixed by upgrade]
         left behind: Example::Old
         not in source: Example::Private
      Vuln-2.0  (no newer version)  CVE: CPANSA-Vuln-2024-01
      6 distributions in 'app': 1 outdated, 2 affected by CVEs
      END

   ($out, $exit, $err)= $run->(@common, '--json', '-q');
   is( $err, '', 'quiet' );
   my $adv= { ids => [ 'CVE-2025-0001', 'CPANSA-Example-2025-01' ], severity => 'high', reported => '2025-01-02',
              affected_versions => ['<1.02'], fixed_versions => ['>=1.02'], description => 'Bad thing' };
   my @expected= ( { %{ $expected_upgrades->[0] }, advisories => [ $adv ] } );
   $expected[0]{upgrades}= [ map +{ %$_, advisories => [], diff_args => [ 'A/AU/AUTHOR/Example-1.00.tar.gz', $_->{author_path} ] },
      @{ $expected[0]{upgrades} } ];
   is( JSON::PP->new->utf8->decode($out),
      {
         branch => 'app', sources => ['source'],
         cve_list => { path => $feed_file, url => T, fetched => match qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/ },
         dists => [
            @expected,
            { author_path => 'V/VU/VULN/Vuln-2.0.tar.gz', dist => 'Vuln', version => '2.0', upgrades => [],
              advisories => [ { ids => ['CPANSA-Vuln-2024-01'], affected_versions => ['>=1.0,<3.0', '==0.5'] } ] },
         ],
         summary => { dists => 6, outdated => 1, affected => 2 },
         failed_assertions => [],
      },
      'json' );

   ($out, $exit, $err)= $run->(@common, '--cve-only', '--outdated-only');
   is( $exit, 2, 'conflicting options' );
   ($out)= $run->(@common, '--outdated-only');
   unlike( $out, qr/^Vuln/m, '--outdated-only' );
   ($out)= $run->(@common, '--cve-only', '--source=lonely');
   is( $out, <<~END, '--cve-only, with a source that has nothing' );
      Example-1.00  (no newer version)  CVE: CVE-2025-0001
      Vuln-2.0  (no newer version)  CVE: CPANSA-Vuln-2024-01
      6 distributions in 'app': 0 outdated, 2 affected by CVEs
      END
   ($out, $exit, $err)= $run->('--branch=app', '--no-cve');
   is( $out, <<~END, '--no-cve' );
      Example-1.00 -> Example-1.02  (source)
      Example-1.00 -> Example-Util-0.01  (source)  moved: Example::Util
         left behind: Example::Old
         not in source: Example::Private
      6 distributions in 'app': 1 outdated, CVEs not checked
      END
   is( $err, '', 'no announcement without CVEs' );

   ($out, $exit, $err)= $run->(@common, '-q', '--assert-no-cve');
   is( $exit, 1, '--assert-no-cve fails' );
   is( $out, '', 'assertion writes no report by default' );
   is( $err, <<~END, 'messages' );
      Assertion failed (--assert-no-cve): A/AU/AUTHOR/Example-1.00.tar.gz is affected by CVE-2025-0001
      Assertion failed (--assert-no-cve): V/VU/VULN/Vuln-2.0.tar.gz is affected by CPANSA-Vuln-2024-01
      END
   ($out, $exit, $err)= $run->(@common, '-q', '--assert-have-src-ver', '--cve-only', '--json');
   is( $exit, 1, '--assert-have-src-ver fails' );
   is( $err, <<~END, 'messages' );
      Assertion failed (--assert-have-src-ver): A/AU/AUTHOR/Example-1.00.tar.gz is behind A/AU/AUTHOR/Example-1.02.tar.gz of 'source'
      Assertion failed (--assert-have-src-ver): A/AU/AUTHOR/Example-1.00.tar.gz is behind A/AU/AUTHOR/Example-Util-0.01.tar.gz of 'source'
      END
   is( JSON::PP->new->utf8->decode($out)->{failed_assertions},
      [ map +{ assertion => 'have-src-ver', author_path => 'A/AU/AUTHOR/Example-1.00.tar.gz', message => T }, 1..2 ],
      'failed_assertions in json' );
   ($out, $exit, $err)= $run->('--branch=source', "--cve-file=$feed_file", '--no-fetch', '-q', '--source=source',
      '--assert-have-src-ver');
   is( $exit, 0, 'assertion passes' );
   is( "$out$err", '', 'silent when passing with -q' );
   ($out, $exit, $err)= $run->(@common, '-q', '--assert-no-cve', '--format=text');
   like( $out, qr/^Vuln-2\.0  \(no newer version\)/m, 'assertion with --format=text writes the report' );
   is( $exit, 1, 'and still fails' );
   ($out, $exit, $err)= $run->('--branch=app', '--no-fetch');
   is( $exit, 2, 'error status' );
   is( $out, '', 'no output on error' );
   like( $err, qr/No copy of the CVE list/, 'error message' );
   ($out, $exit, $err)= $run->('--branch=lonely', '--no-cve');
   is( $exit, 2, 'no sources' );
   like( $err, qr/has no import sources/, 'message for no sources' );
};

done_testing;
