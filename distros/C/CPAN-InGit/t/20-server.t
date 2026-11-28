BEGIN { $ENV{MOJO_NO_TLS}= 1; }
use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Archive::Tar;
use File::Temp;
use Git::Raw;
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Compress::Zip qw(zip $ZipError);
use Test::Mojo;
use Mojo::Server::PSGI;
use Time::Piece;
use CPAN::InGit;
use CPAN::InGit::Server;
use v5.36;

my $repodir= $ENV{TEST_CPAN_INGIT_GIT_DIR}
   // File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_INGIT_CLEANUP} // 1);
my $git_repo= Git::Raw::Repository->init($repodir, 1); # new bare repo in tmpdir
note "repo at $repodir";
my $cpan_repo= CPAN::InGit->new(git_repo => $git_repo);

my $package_details_txt= <<'END';
File:         02packages.details.txt
URL:          http://www.cpan.org/modules/02packages.details.txt
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   PAUSE version 1.005
Line-Count:   9
Last-Updated: Wed, 19 Nov 2025 23:29:01 GMT

A1z::Html                          0.04  C/CE/CEEJAY/A1z-Html-0.04.tar.gz
A1z::HTML5::Template               0.22  C/CE/CEEJAY/A1z-HTML5-Template-0.22.tar.gz
A_Third_Package                   undef  C/CL/CLEMBURG/Test-Unit-0.13.tar.gz
AAA::Demo                         undef  J/JW/JWACH/Apache-FastForward-1.1.tar.gz
AAA::eBay                         undef  J/JW/JWACH/Apache-FastForward-1.1.tar.gz
AAAA                              undef  P/PR/PRBRENAN/Data-Table-Text-20210818.tar.gz
AAAA::Crypt::DH                    0.06  B/BI/BINGOS/AAAA-Crypt-DH-0.06.tar.gz
AAAA::Mail::SpamAssassin          0.002  S/SC/SCHWIGON/AAAA-Mail-SpamAssassin-0.002.tar.gz
AAAAAAAAA                          1.01  M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz
END
my $AAAAAAAAA_meta= <<'END';
---
abstract: 'Aaaaaa aaaaa aa aaaaaa Aaaaa aaaa'
author:
  - 'Aaaaaaa A Aaaaaaa <schwern@pobox.com>'
build_requires: {}
configure_requires:
  A_Third_Package: 0.13
dynamic_config: 1
generated_by: 'Module::Build version 0.38, CPAN::Meta::Converter version 2.110930'
license: perl
meta-spec:
  url: http://module-build.sourceforge.net/META-spec-v1.4.html
  version: 1.4
name: AAAAAAAAA
provides:
  AAAAAAAAA:
    file: aaa/AAAAAAAAA.pm
    version: 1.00
resources:
  license: http://dev.perl.org/licenses/
version: 1.00
END

subtest repository_index => sub {
   my $dir= File::Temp->newdir;
   my $repo= CPAN::InGit->new(repo => Git::Raw::Repository->init($dir, 1));
   my $hidden= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($hidden->app->routes->any('/'), $repo, app => $hidden->app);
   $hidden->get_ok('/~static/archive_tree_index.js')->status_is(200);
   $hidden->get_ok('/')->status_is(200)->text_is('h1', 'CPAN::InGit repository')
      ->element_exists('a[href="https://metacpan.org/pod/CPAN::InGit"]')
      ->element_count_is('#branch-index', 0);
   $hidden->get_ok('/?index_branches=1')->status_is(200)->element_count_is('#branch-index', 0);

   my $listed= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($listed->app->routes->any('/pan'), $repo, app => $listed->app, index_branches => 1);
   $listed->get_ok('/pan/')->status_is(200)->element_exists('#branch-index')
      ->text_like('#branch-index p', qr/No CPAN archive branches/);
   $repo->create_archive_tree('zeta');
   $repo->create_archive_tree('alpha');
   $repo->create_archive_tree('feature/demo');
   my $ordinary= CPAN::InGit::MutableTree->new(parent => $repo);
   $ordinary->set_path('README', \'An ordinary Git branch');
   $ordinary->commit('Non-archive branch', create_branch => 'ordinary');
   $listed->get_ok('/pan')->status_is(200)->element_count_is('#branch-index li', 3)
      ->element_exists('#branch-index a[href="/pan/~branch/alpha/"]')
      ->element_exists('#branch-index a[href="/pan/~branch/feature~demo/"]');
   is( [map $_->text, $listed->tx->res->dom->find('#branch-index a')->each],
      [qw(alpha feature/demo zeta)], 'local archive branches sorted by name' );
   $listed->get_ok('/pan/feature%2Fdemo/')->status_is(200)->text_is('h1', 'feature/demo');
   $listed->get_ok('/pan/feature/demo/modules/')->status_is(200)->json_is('/complete', JSON::PP::true);
   $listed->get_ok('/pan/feature/demo/modules/02packages.details.txt')->status_is(200);
   $hidden->get_ok('/')->status_is(200)->element_count_is('#branch-index', 0)->content_unlike(qr/zeta/);

   # Single-tree mounts keep their archive index even when branch listing is enabled.
   my $fixed= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($fixed->app->routes->any('/'), $repo, app => $fixed->app,
      archive_tree => $repo->get_archive_tree('alpha'), index_branches => 1);
   $fixed->get_ok('/')->status_is(200)->text_is('h1', 'alpha')->element_count_is('#branch-index', 0);

   for my $enabled (0, 1) {
      local $ENV{MOJO_LOG_LEVEL}= 'fatal';
      my @args= ($^X, "-I$FindBin::Bin/../lib", "$FindBin::Bin/../bin/cpangit-server",
         "--git-dir=$dir", '--path-base=/pan', ($enabled? ('--index-branches') : ()), 'get', '/pan/');
      open my $pipe, '-|', @args or die "start cpangit-server: $!";
      my $html= do { local $/; <$pipe> };
      close $pipe;
      is( $?, 0, "cpangit-server get succeeds (index_branches=$enabled)" );
      my $dom= Mojo::DOM->new($html);
      is( $dom->find('#branch-index li')->size, $enabled? 3 : 0,
         'command-line option controls branch listing' );
   }
};

subtest all_branches => sub {
   my $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   $mtree->set_path('modules/02packages.details.txt', \$package_details_txt);
   $mtree->set_path('cpan_ingit.json', \q{{"corelist_perl_version":"5.016","default_import_sources":[]}});
   $mtree->set_path('authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.meta', \$AAAAAAAAA_meta);
   $mtree->set_path('authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01/META.yml', \$AAAAAAAAA_meta);
   $mtree->set_path('authors/id/LOCAL/Example-0.001.meta', \q{{"name":"Example"}});
   $mtree->set_path('authors/id/LOCAL/modules', \'A real file named modules');
   my $initial_commit= $mtree->commit("Initial Commit", create_branch => 'test');

   my $t= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($t->app->routes->get('/'), $cpan_repo, app => $t->app);

   $t->get_ok('/test/')->status_is(200)
      ->element_exists('input[name="filter"]')
      ->element_exists('.filter-controls input#module-filter')
      ->element_exists('.filter-controls button#check-cves[type="button"]')
      ->element_exists('.filter-controls #only-cves-label[hidden] input#only-cves[checked]')
      ->element_exists('.filter-controls #cve-state[hidden] #cve-spinner')
      ->element_exists('script[src="/~static/cpan_cves.js"][defer]')
      ->element_exists('thead th:nth-child(3)#cve-column[hidden]')
      ->element_exists('.module-progress #module-status')
      ->element_exists('.module-progress #load-more[hidden]')
      ->element_exists('.module-progress #load-all[hidden]')
      ->element_count_is('#module-rows td.cve-reports[hidden]', 9)
      ->text_is('#commit-date', gmtime($initial_commit->time)->strftime('%a, %d %b %Y %H:%M:%S GMT'))
      ->text_is('#index-updated', 'Wed, 19 Nov 2025 23:29:01 GMT')
      ->element_count_is('#module-rows tr', 9)
      ->element_exists('a[href="/~branch/test/authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz"]');
   $t->get_ok('/test/modules/')->status_is(200)->json_is('/complete', JSON::PP::true)
      ->json_is('/next_after', undef)->json_is('/previous_before', undef);
   for my $filter ('a1Z', 'cEeJaY', '0.04', '[.*', 'not-present') {
      $t->get_ok(Mojo::URL->new('/test/modules/')->query(filter => $filter))->status_is(200)
         ->json_is('/filter', $filter)->json_is('/complete', JSON::PP::true);
      my @expected= sort grep index(lc $_, lc $filter) >= 0,
         grep /^\S+\s+\S+\s+\S+$/, split /\n/, (split /\n\n/, $package_details_txt, 2)[1];
      is( [map $_->{text}, $t->tx->res->json->{modules}->@*], \@expected, "literal row filter: $filter" );
   }
   $t->get_ok('/test/?filter=ceeJAY')->status_is(200)->element_count_is('#module-rows tr', 2);
   $t->get_ok('/~static/archive_tree_index.js')->status_is(200)->content_type_like(qr/javascript/);
   is( $t->tx->res->body, slurp("$FindBin::Bin/../share/public/archive_tree_index.js"), 'JavaScript served verbatim' );
   my $etag= $t->tx->res->headers->etag;
   $t->get_ok('/~static/archive_tree_index.js' => {'If-None-Match' => $etag})->status_is(304);
   $t->get_ok('/~static/cpan_cves.js')->status_is(200)->content_type_like(qr/javascript/);
   is( $t->tx->res->body, slurp("$FindBin::Bin/../share/public/cpan_cves.js"), 'CVE library served verbatim' );
   $t->get_ok('/~static/archive_tree_index.html.ep')->status_is(404);
   $t->get_ok('/missing/')->status_is(404);
   $t->get_ok('/missing/modules/')->status_is(404);

   $t->get_ok('/test/modules/02packages.details.txt')->status_is(200)->content_is($package_details_txt);
   $t->get_ok('/test/modules/02packages.details.txt.gz')->status_is(200);
   $t->get_ok('/test/authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.meta')->status_is(200)->content_is($AAAAAAAAA_meta);
   $t->get_ok('/test/authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz')->status_is(200);
   $t->get_ok('/test/authors/id/LOCAL/Example-0.001.meta')->status_is(200)->json_is('/name' => "Example");
   $t->get_ok('/test/authors/id/LOCAL/modules')->status_is(200)->content_is('A real file named modules');
   
   # Test cache invalidation
   $mtree->set_path('authors/id/LOCAL/Example-0.002.meta', \q{{"name":"Example"}});
   $mtree->commit("Upgrade Example to 0.002");
   $t->get_ok('/test/authors/id/LOCAL/Example-0.002.meta')->status_is(200)->json_is('/name' => "Example");

   # Refresh the cached rows when the branch's package index changes.
   $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo, branch => 'test');
   my $updated= $package_details_txt =~ s/AAAAAAAAA\s+1\.01/AAAAAAAAA                          1.02/r;
   $mtree->set_path('modules/02packages.details.txt', \$updated);
   $mtree->commit('Update package index');
   $t->get_ok('/test/modules/?filter=AAAAAAAAA')->status_is(200)
      ->json_is('/modules/0/version', '1.02');
};

subtest source_versions => sub {
   my $older= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   my $newer= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   my $pinned= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   my $release= 'A/AU/AUTHOR/Example-2.00.tar.gz';
   $older->set_path('cpan_ingit.json', \'{}');
   my $old_index= <<'END';
Last-Updated: Wed, 19 Nov 2025 23:29:01 GMT

Example 1.90 A/AU/AUTHOR/Example-1.90.tar.gz
Uncached 3.10 A/AU/AUTHOR/Uncached-3.10.tar.gz
END
   $older->set_path('modules/02packages.details.txt', \$old_index);
   $older->commit('Older source', create_branch => 'source/older');

   # A stale mirror index still supplies source versions without contacting its upstream.
   $newer->set_path('cpan_ingit.json', \q{{"upstream_url":"http://127.0.0.1:1/","autofetch":1,"package_details_max_age":1,"canonical_url":"https://example.test/source/"}});
   my $new_index= <<"END";
Last-Updated: Thu, 20 Nov 2025 11:00:00 GMT

Example 2.00 $release
Same 1.000 A/AU/AUTHOR/Same-1.00.tar.gz
Uncached 3.00 A/AU/AUTHOR/Uncached-3.00.tar.gz
Unpacked 2.00 L/LO/LOCAL/Unpacked-2.00.tar.gz
END
   $newer->set_path('modules/02packages.details.txt', \$new_index);
   my $tar= Archive::Tar->new;
   $tar->add_data('Example-2.00/ChangeLog', "<changes>example</changes>\n");
   $tar->add_data('Example-2.00/lib/Example.pm', "package Example;\n");
   $tar->add_data('Example-2.00/lib/with # space.txt', "notes\n");
   $tar->add_data('Example-2.00/empty/', '', {type => Archive::Tar::Constant::DIR});
   my $raw= $tar->write;
   gzip \$raw => \my $archive or die $GzipError;
   $newer->set_path("authors/id/$release", \$archive);
   zip \"\0\x01" => \my $zip, Name => 'data/test.bin' or die $ZipError;
   $newer->set_path('authors/id/A/AU/AUTHOR/Example-2.00.zip', \$zip);
   $newer->set_path('authors/id/L/LO/LOCAL/Unpacked-2.00.meta', \'{}');
   $newer->set_path('authors/id/L/LO/LOCAL/Unpacked-2.00/ChangeLog.md', \"Unpacked changes\n");
   $newer->commit('Newer source', create_branch => 'source/newer');

   $pinned->set_path('cpan_ingit.json', \q{{"default_import_sources":["source/older","source/newer","missing"]}});
   my $pinned_index= <<'END';
Last-Updated: Wed, 19 Nov 2025 23:29:01 GMT

Example 1.00 A/AU/AUTHOR/Example-1.00.tar.gz
Missing 1.00 L/LO/LOCAL/Missing-1.00.tar.gz
Same 1.00 A/AU/AUTHOR/Same-1.00.tar.gz
Uncached 4.00 A/AU/AUTHOR/Uncached-4.00.tar.gz
Unpacked 1.00 L/LO/LOCAL/Unpacked-1.00.tar.gz
END
   $pinned->set_path('modules/02packages.details.txt', \$pinned_index);
   my $old_tar= Archive::Tar->new;
   $old_tar->add_data('Example-1.00/ChangeLog', "first release\n");
   $old_tar->add_data('Example-1.00/lib/Example.pm', "package Example;\nour \$VERSION= 1;\n");
   $old_tar->add_data('Example-1.00/META.json', JSON::PP->new->encode({
      'meta-spec' => { version => 2 }, name => 'Example', version => '1.00', abstract => 'Example',
      author => ['A'], license => ['perl_5'], dynamic_config => 0, generated_by => 'test',
      release_status => 'stable',
      prereqs => { runtime => { requires => { 'Foo' => '1' } } },
   }));
   my $old_raw= $old_tar->write;
   gzip \$old_raw => \my $old_archive or die $GzipError;
   my $pinned_release= 'A/AU/AUTHOR/Example-1.00.tar.gz';
   $pinned->set_path("authors/id/$pinned_release", \$old_archive);
   $pinned->commit('Pinned branch', create_branch => 'pinned');

   my $t= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($t->app->routes->any('/pan'), $cpan_repo, app => $t->app, module_index_max_rows => 3);
   $t->get_ok('/pan/pinned/')->status_is(200)->text_is('thead th:nth-child(3)', 'Src. Ver.')
      ->text_is('.source-branch a[href="/pan/~branch/source~newer/"]', 'source/newer')
      ->element_exists('.source-branch a[href="/pan/~branch/source~older/"]')
      ->text_like('.source-branch a[href="/pan/~branch/source~newer/"] + .source-index-updated',
         qr/20 Nov 2025 11:00:00 GMT/)
      ->text_is('tbody tr:nth-child(1) .source-version a[target="_blank"][rel="noopener"]', '2.00')
      ->text_like('tbody tr:nth-child(2) .source-version', qr/\A\s*\z/)
      ->text_like('tbody tr:nth-child(3) .source-version', qr/\A\s*1\.000\s*\z/)
      ->element_count_is('tbody tr:nth-child(3) .source-version a', 0);
   my $review= Mojo::URL->new($t->tx->res->dom->at('.source-version a')->attr('href'));
   is($review->path->to_string, "/pan/~branch/pinned/authors/id/$pinned_release/~diff",
      'review link is a diff from the pinned distribution');
   is($review->query->to_hash, { to => $release, to_source => 'source/newer' },
      'review link compares with the distribution of the source');

   # Upgrade review, in each format
   $t->get_ok($review)->status_is(200)->content_type_like(qr{^text/html})
      ->text_is('#from-dist', $pinned_release)->text_is('#to-dist', $release)
      ->element_exists(qq{#to-dist[href="/pan/~branch/pinned/authors/id/$release/?source=source%2Fnewer"]})
      ->text_like('.note', qr/Example-2\.00 has no usable META/)
      ->text_is('#prereq-changes tbody tr td:nth-child(3)', 'Foo')
      ->text_is('#changes-added', "<changes>example</changes>\n")
      ->element_count_is('#files-changed tbody tr', 4)
      ->text_like('pre.patch .del', qr/^-our \$VERSION= 1;$/);
   $t->get_ok($review->clone->query({ as => 'json' }))->status_is(200)
      ->json_is('/from/name', 'Example-1.00')->json_is('/from/meta_source', 'META.json')
      ->json_is('/to/name', 'Example-2.00')->json_is('/to/meta_source', 'synthesized')
      ->json_is('/prereqs', { runtime => { requires => { Foo => [ '1', undef ] } } })
      ->json_is('/changes/path', 'ChangeLog')->json_is('/changes/added', "<changes>example</changes>\n")
      ->json_is('/stats', { files => 4, additions => 2, deletions => 3 });
   is( { map +($_->{path} => [ $_->{status}, $_->{skipped} ]), $t->tx->res->json->{files}->@* },
      {
         'ChangeLog'               => [ 'modified', 'changes' ],
         'META.json'               => [ 'deleted', 'generated' ],
         'lib/Example.pm'          => [ 'modified', undef ],
         'lib/with # space.txt'    => [ 'added', undef ],
      },
      'files of the comparison' );
   $t->get_ok($review->clone->query({ as => 'text' }))->status_is(200)->content_type_like(qr{^text/plain})
      ->content_like(qr/^From: +\Q$pinned_release\E \(version 1\.00\)$/m)
      ->content_like(qr/^- runtime requires Foo 1$/m)
      ->content_like(qr/^M lib\/Example\.pm  \+0 -1$/m)
      ->content_like(qr/^D META\.json  \+0 -1  \[patch omitted: generated\]$/m)
      ->content_like(qr/^-our \$VERSION= 1;$/m);
   $t->get_ok($review->clone->query({ as => 'text', patch => 0 }))->status_is(200)
      ->content_unlike(qr/^== Patches ==$/m);
   $t->get_ok($review->clone->query({ as => 'json', path => 'lib/Example.pm' }))->status_is(200)
      ->json_is('/stats/files', 1)->json_is('/files/0/path', 'lib/Example.pm');
   $t->get_ok($review->clone->query({ to => undef }))->status_is(400);
   $t->get_ok($review->clone->query({ to => '../x.tar.gz' }))->status_is(400);
   $t->get_ok($review->clone->query({ to_source => 'test' }))->status_is(404);
   $t->get_ok($review->clone->query({ to => 'L/LO/LOCAL/Missing-9.tar.gz', as => 'json' }))->status_is(404);

   # Special views of a distribution
   my $source_archive= "/pan/~branch/source~newer/authors/id/$release";
   $t->get_ok("$source_archive/~changes")->status_is(200)->content_type_like(qr{^text/plain})
      ->header_is('X-Content-Type-Options', 'nosniff')->content_is("<changes>example</changes>\n");
   $t->get_ok("/pan/~branch/pinned/authors/id/$release/~changes?source=source/newer")
      ->status_is(200)->content_is("<changes>example</changes>\n");
   $t->get_ok("$source_archive/~meta")->status_is(200)
      ->header_is('X-CPAN-InGit-Meta-Source', 'synthesized')->json_is('/name', 'Example');
   $t->get_ok("/pan/~branch/pinned/authors/id/$pinned_release/~meta")->status_is(200)
      ->header_is('X-CPAN-InGit-Meta-Source', 'META.json')->json_is('/prereqs/runtime/requires/Foo', '1');
   $t->get_ok("$source_archive/~unknown")->status_is(404);
   $t->get_ok($source_archive)->status_is(200)->header_like('Content-Disposition', qr/^attachment/)
      ->content_is($archive);

   # Browsing the files of a distribution, which are found without the wrapper directory
   {
      no warnings 'redefine';
      local *CPAN::InGit::DistTree::_read_tar= sub { die 'Unexpected archive re-extraction' };
      $t->get_ok("$source_archive/lib/Example.pm")->status_is(200)->content_is("package Example;\n");
      $t->get_ok("$source_archive/")->status_is(200);
   }
   is( [ $t->tx->res->dom->find('li a')->map('text')->each ], [ 'ChangeLog', 'lib/' ], 'root of distribution' );
   is( [ $t->tx->res->dom->find('.dist-views a')->map('text')->each ], [ 'Change log', 'Metadata', 'Download' ],
      'views of distribution' );
   $t->get_ok("$source_archive/lib/")->status_is(200)
      ->element_exists(qq{a[href="$source_archive/"]})
      ->element_exists(qq{a[href="$source_archive/lib/with%20%23%20space.txt"]});
   $t->get_ok("$source_archive/lib/with%20%23%20space.txt")->status_is(200)->content_is("notes\n");
   $t->get_ok("$source_archive/missing.txt")->status_is(404);
   $t->get_ok("$source_archive/Example-2.00/lib/Example.pm")->status_is(404);
   my $zip_path= '/pan/~branch/source~newer/authors/id/A/AU/AUTHOR/Example-2.00.zip';
   $t->get_ok("$zip_path/")->status_is(200)->text_is('li a', 'test.bin');
   $t->get_ok("$zip_path/test.bin")->status_is(200)->header_is('Content-Disposition', 'attachment')
      ->content_type_is('application/octet-stream')->content_is("\0\x01");

   # Distributions which aren't available
   $t->get_ok('/pan/pinned/modules/?after=Same')->status_is(200)
      ->json_is('/modules/0/source_version', '3.10')->json_is('/modules/1/source_version', '2.00');
   my ($uncached, $unpacked)= $t->tx->res->json->{modules}->@*;
   # The branch is ahead of its sources, which is not an upgrade (same rule as cpangit-audit)
   is($uncached->{review_url}, undef, 'no review link when the source is older');
   $t->get_ok('/pan/pinned/authors/id/A/AU/AUTHOR/Uncached-4.00.tar.gz/~diff?to=A/AU/AUTHOR/Uncached-3.10.tar.gz&to_source=source/older')
      ->status_is(302)
      ->header_is(Location => 'https://metacpan.org/release/AUTHOR/Uncached-3.10/changes');
   $t->get_ok('/pan/pinned/authors/id/A/AU/AUTHOR/Uncached-3.10.tar.gz/~changes?source=source/older')
      ->status_is(302)->header_is(Location => 'https://metacpan.org/release/AUTHOR/Uncached-3.10/changes');
   $t->get_ok('/pan/pinned/authors/id/A/AU/AUTHOR/Uncached-3.10.tar.gz/lib/Uncached.pm')
      ->status_is(302)->header_is(Location => 'https://metacpan.org/release/AUTHOR/Uncached-3.10/source/lib/Uncached.pm');
   is(Mojo::URL->new($unpacked->{review_url})->query->to_hash,
      { to => 'L/LO/LOCAL/Unpacked-2.00.tar.gz', to_source => 'source/newer' }, 'review link of a LOCAL distribution');
   $t->get_ok($unpacked->{review_url})->status_is(404);

   # A distribution stored unpacked in an import source
   my $unpacked_url= Mojo::URL->new('/pan/~branch/pinned/authors/id/L/LO/LOCAL/Unpacked-2.00.tar.gz/')
      ->query(source => 'source/newer');
   $t->get_ok($unpacked_url)->status_is(200)->text_is('li a', 'ChangeLog.md');
   my $child= Mojo::URL->new($t->tx->res->dom->at('li a')->attr('href'));
   is($child->query->param('source'), 'source/newer', 'file links retain the selected source');
   $t->get_ok($child)->status_is(200)->content_is("Unpacked changes\n");
   $t->get_ok('/pan/~branch/source~newer/authors/id/L/LO/LOCAL/Unpacked-2.00.tar.gz/~changes')
      ->status_is(200)->content_is("Unpacked changes\n");
   $t->get_ok('/pan/~branch/pinned/authors/id/L/LO/LOCAL/Unpacked-2.00.tar.gz/')->status_is(404);

   # The cache follows the content of the archive
   $new_index =~ s/Example 2\.00/Example 2.01/;
   $newer->set_path('modules/02packages.details.txt', \$new_index);
   $tar->add_data('Example-2.00/Changes', "Replacement changes\n");
   $raw= $tar->write;
   gzip \$raw => \my $replacement or die $GzipError;
   $newer->set_path("authors/id/$release", \$replacement);
   $newer->commit('Update source index');
   $t->get_ok('/pan/pinned/modules/?filter=Example')->status_is(200)
      ->json_is('/modules/0/source_version', '2.01');
   $t->get_ok("$source_archive/~changes")->status_is(200)->content_is("Replacement changes\n");

   my $fixed= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($fixed->app->routes->any('/mirror'), $cpan_repo,
      archive_tree => $cpan_repo->get_archive_tree('pinned'));
   $fixed->get_ok('/mirror/')->status_is(200)
      ->element_exists('.source-branch a[href="https://example.test/source/"]');
   $fixed->get_ok($fixed->tx->res->dom->at('.source-version a')->attr('href'))->status_is(200)
      ->text_is('#to-dist', $release);
};

subtest module_pagination => sub {
   my $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   my $large= "Last-Updated: Wed, 19 Nov 2025 23:29:01 GMT\n\n";
   $large .= join '', map sprintf("Example::M%04d 1.00 L/LO/LOCAL/Example-%d.tar.gz\n", $_, $_), 1..1001;
   $mtree->set_path('modules/02packages.details.txt', \$large);
   $mtree->set_path('cpan_ingit.json', \'{}');
   $mtree->commit('Large package index', create_branch => 'large');
   my $t= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($t->app->routes->any('/pan'), $cpan_repo, app => $t->app, module_index_max_rows => 500);

   $t->get_ok('/pan/large')->status_is(200)->element_count_is('#module-rows tr', 500)
      ->element_exists('.module-progress #load-more:not([hidden])')
      ->element_exists('.module-progress #load-all:not([hidden])')
      ->element_exists('main[data-json-url="/pan/~branch/large/modules/"]')
      ->element_exists('script[src="/pan/~static/archive_tree_index.js"]');
   $t->get_ok('/pan/large/modules/')->status_is(200)
      ->json_is('/complete', JSON::PP::false)->json_is('/next_after', 'Example::M0500')
      ->json_is('/previous_before', undef);
   my @names= map $_->{name}, $t->tx->res->json->{modules}->@*;
   is( scalar @names, 500, 'first JSON page capped at 500 modules' );
   $t->get_ok('/pan/large/modules/?after=Example::M0500')->status_is(200)
      ->json_is('/modules/0/name', 'Example::M0501')->json_is('/next_after', 'Example::M1000')
      ->json_is('/previous_before', 'Example::M0501')->json_is('/complete', JSON::PP::false);
   push @names, map $_->{name}, $t->tx->res->json->{modules}->@*;
   $t->get_ok('/pan/large/modules/?after=Example::M1000')->status_is(200)
      ->json_is('/modules/0/name', 'Example::M1001')->json_is('/next_after', undef)
      ->json_is('/complete', JSON::PP::false);
   push @names, map $_->{name}, $t->tx->res->json->{modules}->@*;
   is( \@names, [map sprintf('Example::M%04d', $_), 1..1001], 'paging has no gaps or duplicate modules' );
   $t->get_ok('/pan/large/modules/?before=Example::M1001')->status_is(200)
      ->json_is('/modules/0/name', 'Example::M0501')->json_is('/modules/499/name', 'Example::M1000');
   $t->get_ok('/pan/large/modules/?before=Example::M0501')->status_is(200)
      ->json_is('/modules/0/name', 'Example::M0001')->json_is('/modules/499/name', 'Example::M0500');
   $t->get_ok('/pan/large/modules/?after=Example::M1001')->status_is(200)->json_is('/modules', [])
      ->json_is('/complete', JSON::PP::false);
   $t->get_ok('/pan/large/modules/?before=Example::M0001')->status_is(200)->json_is('/modules', []);
   $t->get_ok('/pan/large/modules/?after=A&before=Z')->status_is(400);
   $t->get_ok('/pan/large/modules/?filter=eXaMpLe::m000')->status_is(200)
      ->json_is('/complete', JSON::PP::true);
   is( scalar $t->tx->res->json->{modules}->@*, 9, 'filter applied before pagination' );
   # A boundary need not name an existing module, and remains exclusive when filtering.
   $t->get_ok('/pan/large/modules/?filter=EXAMPLE::M000&after=Example::M0004z')->status_is(200)
      ->json_is('/modules/0/name', 'Example::M0005')->json_is('/complete', JSON::PP::false);

   my $fixed= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($fixed->app->routes->any('/mirror'), $cpan_repo, app => $fixed->app,
      archive_tree => $cpan_repo->get_archive_tree('large'), module_index_max_rows => 500);
   $fixed->get_ok('/mirror/')->status_is(200)->element_count_is('#module-rows tr', 500)
      ->element_exists('main[data-json-url="/mirror/modules/"]');
   $fixed->get_ok('/mirror/modules/?filter=m1001')->status_is(200)
      ->json_is('/modules/0/name', 'Example::M1001')->json_is('/complete', JSON::PP::true);
};

subtest index_variants => sub {
   my $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   my $content= "Last-Updated: Wed, 19 Nov 2025 23:29:01 GMT\n\n";
   $content .= join '', map sprintf("Exact::M%04d 1.00 L/LO/LOCAL/Exact-%d.tar.gz\n", $_, $_), 1..500;
   $mtree->set_path('modules/02packages.details.txt', \$content);
   $mtree->set_path('cpan_ingit.json', \'{}');
   my $commit= $mtree->commit('Exactly 500 modules', create_branch => 'exact');
   my $t= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($t->app->routes->any('/'), $cpan_repo, app => $t->app);
   $t->get_ok('/exact/modules/')->status_is(200)->json_is('/complete', JSON::PP::true)
      ->json_is('/next_after', undef)->json_is('/modules/499/name', 'Exact::M0500');
   $t->get_ok('/exact/')->status_is(200)->element_exists('#load-more[hidden]');
   $t->get_ok('/'.$commit->id.'/')->status_is(200)
      ->text_is('#commit-date', gmtime($commit->time)->strftime('%a, %d %b %Y %H:%M:%S GMT'));

   # A fixed commit mount retains its reference for commit metadata as well.
   my $fixed= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($fixed->app->routes->any('/'), $cpan_repo, app => $fixed->app,
      archive_tree => $cpan_repo->get_archive_tree($commit->id));
   $fixed->get_ok('/')->status_is(200)
      ->text_is('#commit-date', gmtime($commit->time)->strftime('%a, %d %b %Y %H:%M:%S GMT'))
      ->attr_is('main', 'data-json-url', '/modules/');
   $fixed->get_ok('/modules/')->status_is(200)->json_is('/complete', JSON::PP::true);

   my $empty= $cpan_repo->create_archive_tree('empty');
   $t->get_ok('/empty/')->status_is(200)->element_count_is('#module-rows tr', 0);
   $t->get_ok('/empty/modules/')->status_is(200)->json_is('/modules', [])
      ->json_is('/complete', JSON::PP::true);
   my $missing= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   $missing->set_path('cpan_ingit.json', \'{}');
   $missing->commit('No package index', create_branch => 'noindex');
   $t->get_ok('/noindex/')->status_is(404);
   $t->get_ok('/noindex/modules/')->status_is(404);

   my $unsafe= "Last-Updated: unknown\n\nExample::<b> undef L/LO/LOCAL/Example-<b>&\".tar.gz\n";
   my $escape= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   $escape->set_path('cpan_ingit.json', \'{}');
   $escape->set_path('modules/02packages.details.txt', \$unsafe);
   $escape->commit('Untrusted index content', create_branch => 'escape');
   $t->get_ok(Mojo::URL->new('/escape/')->query(filter => '<b>'))->status_is(200)
      ->element_count_is('#module-rows tr', 1)->element_count_is('#module-rows b', 0)
      ->text_is('#module-rows tr td span', 'Example::<b>')
      ->element_exists('input[value="<b>"]');
};

subtest endpoint_names => sub {
   my $dir= File::Temp->newdir;
   my $repo= CPAN::InGit->new(repo => Git::Raw::Repository->init($dir, 1));
   $repo->create_archive_tree($_) for qw(other feature/modules.json feature/index.js public);
   my $t= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($t->app->routes->any('/pan'), $repo, app => $t->app);
   $t->get_ok('/pan/other/modules/')->status_is(200)->json_is('/modules', []);
   $t->get_ok('/pan/feature/modules.json/')->status_is(200)->text_is('h1', 'feature/modules.json');
   $t->get_ok('/pan/feature/index.js/')->status_is(200)->text_is('h1', 'feature/index.js');
   $t->get_ok('/pan/~static/archive_tree_index.js')->status_is(200);
   my $root= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($root->app->routes->any('/'), $repo, app => $root->app);
   $root->get_ok('/public/')->status_is(200)->text_is('h1', 'public')
      ->element_exists('script[src="/~static/archive_tree_index.js"]');
   $root->get_ok('/public/modules/')->status_is(200)->json_is('/modules', []);
   $root->get_ok('/~static/archive_tree_index.js')->status_is(200);
};

subtest branch_path_prefixes => sub {
   my $dir= File::Temp->newdir;
   my $repo= CPAN::InGit->new(repo => Git::Raw::Repository->init($dir, 1));
   my $tree= CPAN::InGit::MutableTree->new(parent => $repo);
   $tree->set_path('cpan_ingit.json', \'{}');
   $tree->set_path('modules/02packages.details.txt', \$package_details_txt);
   $tree->set_path('authors/id/LOCAL/nested/authors/id/file.txt', \'Nested author path');
   my $commit= $tree->commit('Archive with slash in branch name', create_branch => 'feature/modules');
   my $t= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($t->app->routes->any('/pan'), $repo, app => $t->app);
   $t->get_ok('/pan/feature/modules/')->status_is(200)->text_is('h1', 'feature/modules')
      ->attr_is('main', 'data-json-url', '/pan/~branch/feature~modules/modules/');
   $t->get_ok('/pan/feature%2Fmodules/')->status_is(200)->text_is('h1', 'feature/modules');
   $t->get_ok('/pan/feature/modules/modules/')->status_is(200)->json_is('/modules/0/name', 'A1z::HTML5::Template');
   $t->get_ok('/pan/feature/modules/modules/02packages.details.txt')->status_is(200)->content_is($package_details_txt);
   $t->get_ok('/pan/feature/modules/authors/id/LOCAL/nested/authors/id/file.txt')
      ->status_is(200)->content_is('Nested author path');
   $t->get_ok('/pan/feature/modules/not-a-resource')->status_is(404);
   $t->get_ok('/pan/not/a/branch/modules/')->status_is(404);

   for my $branch ('deep/authors/id/release', 'other/modules/02packages.details.txt') {
      $repo->git_repo->branch($branch, $commit);
      $t->get_ok("/pan/$branch/")->status_is(200)->text_is('h1', $branch);
      $t->get_ok("/pan/$branch/modules/")->status_is(200)->json_is('/complete', JSON::PP::true);
   }

   # A new reference can change the shortest matching prefix of a previously
   # requested URL. Both the route resolution and branch cache must stay fresh.
   my $branch= $repo->git_repo->branch('cached/modules', $commit);
   $t->get_ok('/pan/cached/modules/')->status_is(200)->text_is('h1', 'cached/modules');
   $branch->delete;
   $branch= $repo->git_repo->branch('cached', $commit);
   $t->get_ok('/pan/cached/modules/')->status_is(200)->json_is('/complete', JSON::PP::true);
   $branch->delete;
   $repo->git_repo->branch('cached/modules', $commit);
   $t->get_ok('/pan/cached/modules/')->status_is(200)->text_is('h1', 'cached/modules');

   # An unborn HEAD does not hide HEAD/modules, but a resolved HEAD does.
   $repo->git_repo->branch('HEAD/modules', $commit);
   $t->get_ok('/pan/HEAD/modules/')->status_is(200)->text_is('h1', 'HEAD/modules');
   $repo->git_repo->head(Git::Raw::Branch->lookup($repo->git_repo, 'feature/modules', 1));
   $t->get_ok('/pan/HEAD/modules/')->status_is(200)->json_is('/complete', JSON::PP::true);
   $t->get_ok('/pan/~branch/HEAD~modules/')->status_is(200)->text_is('h1', 'HEAD/modules');
   $t->get_ok('/pan/HEAD/not-a-resource/')->status_is(404);
};

subtest explicit_tree_names => sub {
   my $dir= File::Temp->newdir;
   my $repo= CPAN::InGit->new(repo => Git::Raw::Repository->init($dir, 1));
   my $tree= CPAN::InGit::MutableTree->new(parent => $repo);
   $tree->set_path('cpan_ingit.json', \'{}');
   $tree->set_path('modules/02packages.details.txt', \"Last-Updated: unknown\n\nExample 1.00 L/LO/LOCAL/Example-1.00.tar.gz\n");
   my $first= $tree->commit('Branch version', create_branch => 'release/v1.0');
   $tree->set_path('modules/02packages.details.txt', \"Last-Updated: unknown\n\nExample 2.00 L/LO/LOCAL/Example-2.00.tar.gz\n");
   my $second= $tree->commit('Tag version');
   # Restore the branch to the first commit; give both namespaces the same name.
   Git::Raw::Reference->create('refs/heads/release/v1.0', $repo->git_repo, $first, 1);
   Git::Raw::Reference->create('refs/tags/release/v1.0', $repo->git_repo, $second);
   $repo->git_repo->tag('annotated/v1.0', 'Annotated release', Git::Raw::Signature->now('Test', 'test@example.com'), $second);
   my $cache= {};
   my $t= Test::Mojo->new('Mojolicious');
   $t->app->routes->get('/other')->to(cb => sub($c) { $c->render(text => 'Other route') });
   CPAN::InGit::Server->mount($t->app->routes->any('/pan'), $repo, app => $t->app, branch_cache => $cache);
   $t->get_ok('/other')->status_is(200);
   my $routing_cache= $t->app->routes->cache;
   my $other_match= $routing_cache->get('GET:/other:0');
   ok($routing_cache->max_keys > 0, 'routing cache remains enabled');
   ok($other_match, 'unrelated route is cached');

   $t->get_ok('/pan/release/v1.0/modules/?filter=example')->status_is(200)
      ->json_is('/modules/0/version', '1.00')->json_is('/filter', 'example');
   ok(!$routing_cache->get('GET:/pan/release/v1.0/modules/:0'), 'friendly path is not cached');
   ok($routing_cache->get('GET:/pan/~branch/release~v1.0/modules/:0'), 'rewritten explicit path is cached');
   $t->get_ok('/pan/~branch/release~v1.0/')->status_is(200)->text_is('h1', 'release/v1.0')
      ->attr_is('main', 'data-json-url', '/pan/~branch/release~v1.0/modules/');
   $t->get_ok('/pan/~tag/release~v1.0/')->status_is(200)->text_is('h1', 'release/v1.0')
      ->attr_is('main', 'data-json-url', '/pan/~tag/release~v1.0/modules/')
      ->text_is('#commit-date', gmtime($second->time)->strftime('%a, %d %b %Y %H:%M:%S GMT'));
   $t->get_ok('/pan/~tag/release~v1.0/modules/')->status_is(200)->json_is('/modules/0/version', '2.00');
   $t->get_ok('/pan/annotated/v1.0/modules/')->status_is(200)->json_is('/modules/0/version', '2.00');
   $t->get_ok('/pan/~tag/annotated~v1.0/modules/')->status_is(200)->json_is('/modules/0/version', '2.00');
   ok(exists $cache->{'~branch/release~v1.0'} && exists $cache->{'~tag/release~v1.0'},
      'ArchiveTree cache uses both tree_name components to separate namespaces');

   # A branch named after a commit ID must not affect explicit commit selection.
   $repo->git_repo->branch($second->id, $first);
   $t->get_ok('/pan/'.$second->id.'/modules/')->status_is(200)->json_is('/modules/0/version', '1.00');
   $t->get_ok('/pan/~commit/'.$second->id.'/modules/')->status_is(200)->json_is('/modules/0/version', '2.00');
   $t->get_ok('/pan/'.substr($second->id, 0, 12).'/')->status_is(200)
      ->text_is('#commit-date', gmtime($second->time)->strftime('%a, %d %b %Y %H:%M:%S GMT'));
   $t->get_ok('/pan/~commit/'.$first->tree->id.'/')->status_is(404);
   $t->get_ok('/pan/~branch/annotated~v1.0/')->status_is(404);
   $t->get_ok('/pan/~tag/missing/')->status_is(404);
   $t->get_ok('/pan/~branch/release/v1.0/')->status_is(404);

   # Deleting a branch immediately exposes the same-named tag, without a stale 404.
   Git::Raw::Branch->lookup($repo->git_repo, 'release/v1.0', 1)->delete;
   $t->get_ok('/pan/release/v1.0/modules/')->status_is(200)->json_is('/modules/0/version', '2.00');
   $t->get_ok('/pan/~branch/release~v1.0/modules/')->status_is(404);
   $repo->git_repo->branch('release/v1.0', $first);
   $t->get_ok('/pan/release/v1.0/modules/')->status_is(200)->json_is('/modules/0/version', '1.00');
   # Retargeting a tag refreshes its ArchiveTree even with a cached route match.
   Git::Raw::Reference->create('refs/tags/release/v1.0', $repo->git_repo, $first, 1);
   $t->get_ok('/pan/~tag/release~v1.0/modules/')->status_is(200)->json_is('/modules/0/version', '1.00');
   ok($routing_cache->get('GET:/other:0') == $other_match, 'ref changes preserve unrelated cached matches');

   $t->get_ok('/pan/new/branch/')->status_is(404);
   $repo->git_repo->branch('new/branch', $first);
   $t->get_ok('/pan/new/branch/')->status_is(200);

   my $restricted= Test::Mojo->new('Mojolicious');
   CPAN::InGit::Server->mount($restricted->app->routes->any('/pan'), $repo,
      app => $restricted->app, branch_head_only => 1);
   $restricted->get_ok('/pan/release/v1.0/modules/')->status_is(200)->json_is('/modules/0/version', '1.00');
   $restricted->get_ok('/pan/~branch/release~v1.0/modules/')->status_is(200);
   $restricted->get_ok('/pan/annotated/v1.0/')->status_is(404);
   $restricted->get_ok('/pan/~tag/release~v1.0/')->status_is(404);
   $restricted->get_ok('/pan/~commit/'.$second->id.'/')->status_is(404);
};

subtest mounted_urls => sub {
   my $dir= File::Temp->newdir;
   my $repo= CPAN::InGit->new(repo => Git::Raw::Repository->init($dir, 1));
   my $tree= CPAN::InGit::MutableTree->new(parent => $repo);
   my $dist= 'C/CE/CEEJAY/A1z-Html-0.04.tar.gz';
   $tree->set_path('cpan_ingit.json', \'{}');
   $tree->set_path('modules/02packages.details.txt', \$package_details_txt);
   $tree->set_path("authors/id/$dist", \'Mock distribution');
   $tree->commit('Mounted archive', create_branch => 'demo');

   for my $fixed (0, 1) {
      for my $base ('', '/pan') {
         for my $mount ('', '/service') {
            for my $proxy (0, 1) {
               subtest "fixed=$fixed base=$base mount=$mount proxy=$proxy" => sub {
                  # Test::Mojo creates its own server lazily on the first request.
                  local $ENV{MOJO_REVERSE_PROXY}= $proxy;
                  local $ENV{MOJO_TRUSTED_PROXIES}= '';
                  my $app= Mojolicious->new;
                  CPAN::InGit::Server->mount($app->routes->any($base || '/'), $repo, app => $app,
                     $fixed? (archive_tree => $repo->get_archive_tree('demo')) : ());
                  if (length $mount) {
                     my $outer= Mojolicious->new;
                     $outer->routes->any($mount)->partial(1)->to(app => $app);
                     $app= $outer;
                  }
                  my $seen;
                  $app->hook(before_dispatch => sub($c) {
                     $seen= [ $c->tx->remote_address, $c->req->url->base->scheme ];
                  });
                  my $t= Test::Mojo->new($app);
                  $t->ua->on(start => sub($ua, $tx) {
                     $tx->req->headers->header('X-Forwarded-For' => '203.0.113.42');
                     $tx->req->headers->header('X-Forwarded-Proto' => 'https');
                  });
                  my $root= "$mount$base";
                  my $tree_url= $root.($fixed? '' : '/~branch/demo');
                  my $friendly_url= $root.($fixed? '' : '/demo');
                  $t->get_ok("$friendly_url/")->status_is(200)
                     ->attr_is('main', 'data-json-url', "$tree_url/modules/")
                     ->attr_is('main', 'data-authors-url', "$tree_url/authors/id/");
                  is( $seen, $proxy? ['203.0.113.42', 'https'] : ['127.0.0.1', 'http'],
                     'forwarded address and scheme are honored only in reverse-proxy mode' );
                  my @scripts= $t->tx->res->dom->find('script[src]')->map(attr => 'src')->each;
                  is( \@scripts, ["$root/~static/cpan_cves.js", "$root/~static/archive_tree_index.js"],
                     'asset URLs include application and CPAN route prefixes exactly once' );
                  my $json= $t->tx->res->dom->at('main')->attr('data-json-url');
                  my $download= $t->tx->res->dom->at('#module-rows a[href$="A1z-Html-0.04.tar.gz"]')->attr('href');
                  for my $script (@scripts) {
                     $t->get_ok($script)->status_is(200)->content_type_like(qr/javascript/);
                  }
                  $t->get_ok($json.'?filter=A1z-Html-0.04.tar.gz')->status_is(200)
                     ->json_is('/modules/0/name', 'A1z::Html');
                  $t->get_ok($download)->status_is(200)->content_is('Mock distribution');
               };
            }
         }
      }
   }

   # A non-Mojo frontend can supply a stripped prefix through standard PSGI
   # SCRIPT_NAME. Exercise the real adapter rather than rewriting request URLs.
   for my $fixed (0, 1) {
      subtest "PSGI SCRIPT_NAME fixed=$fixed" => sub {
         my $app= Mojolicious->new;
         CPAN::InGit::Server->mount($app->routes->any('/pan'), $repo, app => $app,
            $fixed? (archive_tree => $repo->get_archive_tree('demo')) : ());
         my $psgi= Mojo::Server::PSGI->new(app => $app, reverse_proxy => 1)->to_psgi_app;
         my $script_name= '/gateway/cpan';
         my $get= sub($public_url) {
            my $url= Mojo::URL->new($public_url);
            my $path= $url->path->to_string;
            $path =~ s{^\Q$script_name\E(?=/|$)}{} or die "URL escaped SCRIPT_NAME: $path";
            my $empty= '';
            open my $input, '<', \$empty or die $!;
            my $response= $psgi->({
               REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SERVER_PORT => 80,
               HTTP_HOST => 'cpan.example', REMOTE_ADDR => '127.0.0.1',
               HTTP_X_FORWARDED_FOR => '203.0.113.42', HTTP_X_FORWARDED_PROTO => 'https',
               SCRIPT_NAME => $script_name, PATH_INFO => $path, QUERY_STRING => $url->query->to_string,
               'psgi.input' => $input,
            });
            my $body= '';
            while (defined(my $chunk= $response->[2]->getline)) {
               last unless length $chunk;
               $body .= $chunk;
            }
            $response->[2]->close;
            is( $response->[0], 200, "GET $public_url through PSGI" );
            return $body;
         };
         my $root= "$script_name/pan";
         my $tree_url= $root.($fixed? '' : '/~branch/demo');
         my $friendly_url= $root.($fixed? '' : '/demo');
         my $dom= Mojo::DOM->new($get->("$friendly_url/"));
         my @scripts= $dom->find('script[src]')->map(attr => 'src')->each;
         is( \@scripts, ["$root/~static/cpan_cves.js", "$root/~static/archive_tree_index.js"],
            'SCRIPT_NAME is included exactly once in asset URLs' );
         for my $script (@scripts) {
            like( $get->($script), qr/'use strict'/, 'generated script URL serves JavaScript' );
         }
         is( $dom->at('main')->attr('data-json-url'), "$tree_url/modules/", 'JSON URL retains SCRIPT_NAME' );
         my $json= JSON::PP::decode_json($get->($dom->at('main')->attr('data-json-url').'?filter=A1z-Html-0.04.tar.gz'));
         is( $json->{modules}[0]{name}, 'A1z::Html', 'generated JSON URL serves filtered modules' );
         my $download= $dom->at('#module-rows a[href$="A1z-Html-0.04.tar.gz"]')->attr('href');
         is( $get->($download), 'Mock distribution', 'generated download URL works through PSGI' );
      };
   }

   my $t= Test::Mojo->new('Mojolicious');
   for my $base ('/one', '/two') {
      CPAN::InGit::Server->mount($t->app->routes->any($base), $repo, app => $t->app,
         archive_tree => $repo->get_archive_tree('demo'));
   }
   for my $base ('/one', '/two') {
      $t->get_ok("$base/")->status_is(200)
         ->element_exists(qq{script[src="$base/~static/archive_tree_index.js"]});
      $t->get_ok("$base/~static/archive_tree_index.js")->status_is(200);
   }
   $t->get_ok('/~static/archive_tree_index.js')->status_is(404);

   # Multiple dynamic mounts install independent rewrite hooks and named routes.
   my $dynamic= Test::Mojo->new('Mojolicious');
   for my $base ('/one', '/two') {
      CPAN::InGit::Server->mount($dynamic->app->routes->any($base), $repo,
         app => $dynamic->app, index_branches => 1);
   }
   for my $base ('/one', '/two') {
      $dynamic->get_ok("$base/")->status_is(200)
         ->element_exists(qq{#branch-index a[href="$base/~branch/demo/"]});
      $dynamic->get_ok("$base/demo/")->status_is(200)
         ->attr_is('main', 'data-json-url', "$base/~branch/demo/modules/")
         ->element_exists(qq{script[src="$base/~static/archive_tree_index.js"]});
      $dynamic->get_ok("$base/~branch/demo/modules/")->status_is(200);
   }
};

done_testing;
