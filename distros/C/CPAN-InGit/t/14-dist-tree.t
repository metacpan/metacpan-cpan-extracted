use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Archive::Tar;
use File::Temp;
use Git::Raw;
use IO::Compress::Gzip 'gzip';
use JSON::PP;
use POSIX 'strftime';
use CPAN::InGit;
use CPAN::InGit::DistTree;
use v5.36;

# Build a .tar.gz from  path => $content | [ $content, $mode ] | { link => $target }
sub make_archive(%files) {
   my $tar= Archive::Tar->new;
   for my $path (sort keys %files) {
      my $spec= $files{$path};
      if (ref $spec eq 'HASH') {
         $tar->add_data($path, '', { type => Archive::Tar::Constant::SYMLINK, linkname => $spec->{link} });
      } else {
         my ($content, $mode)= ref $spec? @$spec : ($spec, 0644);
         $tar->add_data($path, $content, { mode => $mode });
      }
   }
   my $raw= $tar->write;
   gzip \$raw => \my $gz or die 'gzip failed';
   return $gz;
}

sub meta_json($version, %prereqs) {
   JSON::PP->new->canonical->encode({
      'meta-spec' => { version => 2 }, name => 'Example', version => $version, abstract => 'Example',
      author => ['A'], license => ['perl_5'], dynamic_config => 0, generated_by => 'test',
      release_status => 'stable', prereqs => \%prereqs,
   });
}

my $old_path= 'A/AU/AUTHOR/Example-1.00.tar.gz';
my $new_path= 'A/AU/AUTHOR/Example-1.02.tar.gz';
my $old_archive= make_archive(
   'Example-1.00/Changes'        => "1.00\n  - First release\n",
   'Example-1.00/META.json'      => meta_json('1.00', runtime => { requires => { 'Foo' => '1', 'Gone' => '0' } }),
   'Example-1.00/MANIFEST'       => "Changes\nMETA.json\nMANIFEST\nlib/Example.pm\n",
   'Example-1.00/lib/Example.pm' => "package Example;\nour \$VERSION= '1.00';\nsub hello { 'hello' }\n1;\n",
   'Example-1.00/bin/example'    => [ "#!perl\n", 0755 ],
   'Example-1.00/logo.png'       => "\x89PNG\0\0\1",
);
my $new_archive= make_archive(
   'Example-1.02/Changes'        => "1.02\n  - Na\x{C3}\x{AF}ve fix\n1.00\n  - First release\n",
   'Example-1.02/META.json'      => meta_json('1.02',
      runtime => { requires => { 'Foo' => '1.5', 'Bar' => '2' } }, test => { requires => { 'Test::More' => '0.98' } }),
   'Example-1.02/MANIFEST'       => "Changes\nMETA.json\nMANIFEST\nlib/Example.pm\nlib/Example/Util.pm\n",
   'Example-1.02/lib/Example.pm' => "package Example;\nour \$VERSION= '1.02';\nsub hello { 'hello world' }\n1;\n",
   'Example-1.02/lib/Example/Util.pm' => "package Example::Util;\n1;\n",
   'Example-1.02/bin/example'    => [ "#!perl\n", 0755 ],
   'Example-1.02/logo.png'       => "\x89PNG\0\0\2",
   'Example-1.02/latest'         => { link => 'lib/Example.pm' },
);

my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
my $git_repo= Git::Raw::Repository->init($repodir, 1);
my $cpan_repo= CPAN::InGit->new(repo => $git_repo);

subtest new_from_archive => sub {
   my $dist= CPAN::InGit::DistTree->new_from_archive(parent => $cpan_repo, filename => $new_path, data => \$new_archive);
   is( $dist->name, 'Example-1.02', 'name' );
   is( [ $dist->file_list ],
      [qw( Changes MANIFEST META.json bin/example latest lib/Example.pm lib/Example/Util.pm logo.png )],
      'files, without the wrapper directory' );
   is( $dist->get_path('bin/example')->[1], 0100755, 'executable' );
   is( $dist->get_path('latest'), [ object { call content => 'lib/Example.pm' }, 0120000 ], 'symlink' );
   is( [ sort keys %{ $dist->list_dir('lib') } ], [ 'Example', 'Example.pm' ], 'list_dir' );
   is( $dist->files->{'lib/Example/Util.pm'}, [ \"package Example::Util;\n1;\n", 0100644 ], 'files' );
   ok( $dist->check_symlinks, 'symlinks are safe' );
   is( $dist->meta_source, 'META.json', 'meta_source' );
   is( $dist->meta->version, '1.02', 'meta version' );
   is( [ $dist->changes_file ], [ 'Changes', object { call content => match qr/^1\.02/ } ], 'changes_file' );
   is( $dist->provides,
      { 'Example' => { file => 'lib/Example.pm', version => '1.02' }, 'Example::Util' => { file => 'lib/Example/Util.pm' } },
      'provides, by scanning' );
   is( $dist->has_changes, F, 'no pending changes' );
   ok( !eval { Git::Raw::Tree->lookup($git_repo, $dist->tree->id) }, 'tree is not stored in the main repo' );
   like( $cpan_repo->dist_cache_repo->path, qr{/cpan-ingit-cache\.git/\z}, 'cache repo is inside the main repo' );

   my $bare= CPAN::InGit::DistTree->new_from_archive(parent => $cpan_repo, filename => 'Odd-0.1.tgz',
      data => \make_archive('lib/Odd.pm' => "package Odd 0.1;\n", 'NEWS.md' => "news\n"));
   is( [ $bare->file_list ], [ 'NEWS.md', 'lib/Odd.pm' ], 'archive without a wrapper directory' );
   is( $bare->meta_source, 'synthesized', 'no META' );
   is( [ $bare->meta->name, $bare->meta->version ], [ 'Odd', '0.1' ], 'meta from the file name' );
   is( $bare->provides, { Odd => { file => 'lib/Odd.pm', version => '0.1' } }, 'provides' );
   is( ($bare->changes_file)[0], 'NEWS.md', 'changes_file by another name' );

   my $unsafe= CPAN::InGit::DistTree->new_from_archive(parent => $cpan_repo, filename => 'Link-1.tar.gz',
      data => \make_archive('Link-1/a' => 'a', 'Link-1/out' => { link => '../../etc/passwd' }));
   like( dies { $unsafe->check_symlinks }, qr/Unsafe symlink 'out'/, 'symlink escaping the distribution' );
   for (
      [ 'Unsafe archive path'       => 'X-1/../../evil' => 'x' ],
      [ 'Unsafe archive path'       => 'X-1/.git/config' => 'x' ],
   ) {
      my ($err, @files)= @$_;
      like( dies { CPAN::InGit::DistTree->new_from_archive(parent => $cpan_repo, filename => 'X-1.tar.gz',
               data => \make_archive('X-1/ok' => 'ok', @files)) },
            qr/$err/, "$err: $files[0]" );
   }
   like( dies { CPAN::InGit::DistTree->new_from_archive(parent => $cpan_repo, filename => 'notes.txt', data => \'x') },
      qr/Unsupported distribution filename/, 'not an archive name' );
   local $Archive::Tar::WARN= 0;
   like( dies { CPAN::InGit::DistTree->new_from_archive(parent => $cpan_repo, filename => 'X-1.tar.gz', data => \'garbage') },
      qr/Cannot read X-1\.tar\.gz/, 'not an archive' );
};

subtest archive_tree => sub {
   my $source= $cpan_repo->create_archive_tree('source');
   $source->set_path("authors/id/$_->[0]", \$_->[1]) for [ $old_path, $old_archive ], [ $new_path, $new_archive ];
   $source->index_distribution($new_path, { 'Example' => '1.02', 'Example::Util' => undef });
   $source->commit('Add Example');
   $source= $cpan_repo->get_archive_tree('source');
   is( $source->dist_storage($new_path), 'archive', 'dist_storage' );
   is( $source->dist_storage('A/AU/AUTHOR/Example-9.tar.gz'), undef, 'dist_storage of missing dist' );
   is( $source->get_dist('A/AU/AUTHOR/Example-9.tar.gz'), undef, 'get_dist of missing dist' );
   is( $source->get_dist('modules/02packages.details.txt'), undef, 'get_dist of a non-archive' );

   my $dist= $source->get_dist($new_path);
   is( $dist, object {
         call name => 'Example-1.02'; call author_path => $new_path; call storage => 'archive';
      }, 'get_dist' );
   {
      no warnings 'redefine';
      local *CPAN::InGit::DistTree::_read_tar= sub { die 'unpacked again' };
      is( $source->get_dist($new_path)->tree->id, $dist->tree->id, 'second get_dist uses the cache' );
      # a different object, as another process would have
      my $again= CPAN::InGit->new(repo => "$repodir")->get_archive_tree('source')->get_dist($new_path);
      is( $again->tree->id, $dist->tree->id, 'cache is shared' );
   }
   is( $source->get_dist_meta($new_path), object { call version => '1.02' }, 'get_dist_meta from inside the archive' );

   my $app= $cpan_repo->create_archive_tree('app', default_import_sources => ['source']);
   $app->import_dist($source, $new_path);
   is( $app->get_dist_meta($new_path)->effective_prereqs->as_string_hash->{runtime}{requires},
      { Foo => '1.5', Bar => '2' }, 'import wrote a .meta file from the archive' );
   ok( $app->get_path("authors/id/A/AU/AUTHOR/Example-1.02.meta"), '.meta file is in the tree' );

   # A local copy, stored unpacked, and then patched
   my $local_path= $app->add_local_dist($new_path, \$new_archive);
   is( $local_path, 'L/LO/LOCAL/Example-1.02.tar.gz', 'add_local_dist' );
   $app->set_path('authors/id/L/LO/LOCAL/Example-1.02/lib/Example.pm', \"package Example;\nour \$VERSION= '1.02';\nsub hello { 'patched' }\n1;\n");
   is( $app->dist_storage($local_path), 'unpacked', 'dist_storage of pending local dist' );
   $app->commit('Local patch');
   my $local= $cpan_repo->get_archive_tree('app')->get_dist($local_path);
   is( $local->storage, 'unpacked', 'storage' );
   is( $dist->diff($local),
      [ { path => 'lib/Example.pm', status => 'modified', additions => 1, deletions => 1, binary => 0,
          old_id => T, new_id => T, old_mode => 0100644, new_mode => 0100644 } ],
      'diff between an archive and an unpacked dist of the main repo' );
};

subtest compare => sub {
   my $source= $cpan_repo->get_archive_tree('source');
   my ($old, $new)= map $source->get_dist($_), $old_path, $new_path;
   is( $old->diff_prereqs($new),
      {
         runtime => { requires => { Foo => [ '1', '1.5' ], Bar => [ undef, '2' ], Gone => [ '0', undef ] } },
         test    => { requires => { 'Test::More' => [ undef, '0.98' ] } },
      },
      'diff_prereqs' );
   is( CPAN::InGit::DistTree->diff_prereqs($new->meta, $new->meta), {}, 'diff_prereqs as class method' );

   my $report= $old->compare($new);
   is( $report,
      {
         from    => { name => 'Example-1.00', author_path => $old_path, version => '1.00', storage => 'archive',
                      meta_source => 'META.json', tree => $old->tree->id },
         to      => { name => 'Example-1.02', author_path => $new_path, version => '1.02', storage => 'archive',
                      meta_source => 'META.json', tree => $new->tree->id },
         prereqs => { runtime => T, test => T },
         changes => { path => 'Changes', added => "1.02\n  - Na\x{EF}ve fix\n", patch => match qr/^\@\@/m },
         stats   => { files => 7, additions => 9, deletions => 3 },
         files   => [
            { path => 'Changes',     status => 'modified', skipped => 'changes',   additions => 2, deletions => 0, binary => 0,
              old_id => T, new_id => T, old_mode => 0100644, new_mode => 0100644 },
            { path => 'MANIFEST',    status => 'modified', skipped => 'generated', additions => 1, deletions => 0, binary => 0,
              old_id => T, new_id => T, old_mode => 0100644, new_mode => 0100644 },
            { path => 'META.json',   status => 'modified', skipped => 'generated', additions => 1, deletions => 1, binary => 0,
              old_id => T, new_id => T, old_mode => 0100644, new_mode => 0100644 },
            { path => 'latest',      status => 'added', additions => 1, deletions => 0, binary => 0,
              old_id => undef, new_id => T, old_mode => undef, new_mode => 0120000, patch => T },
            { path => 'lib/Example.pm', status => 'modified', additions => 2, deletions => 2, binary => 0,
              old_id => T, new_id => T, old_mode => 0100644, new_mode => 0100644,
              patch => match qr/^-sub hello \{ 'hello' \}\n.*^\+sub hello \{ 'hello world' \}$/ms },
            { path => 'lib/Example/Util.pm', status => 'added', additions => 2, deletions => 0, binary => 0,
              old_id => undef, new_id => T, old_mode => undef, new_mode => 0100644, patch => T },
            { path => 'logo.png',    status => 'modified', skipped => 'binary', additions => 0, deletions => 0, binary => 1,
              old_id => T, new_id => T, old_mode => 0100644, new_mode => 0100644 },
         ],
      },
      'compare' );
   is( $old->compare($new, patch => 0)->{files}[4], hash { field patch => DNE; field skipped => DNE; etc }, 'patch => 0' );
   is( $old->compare($new, include_generated => 1)->{files}[2], hash { field patch => T; etc }, 'include_generated' );
   is( $old->compare($new, max_patch_size => 20)->{files}[4], hash { field skipped => 'too large'; etc }, 'max_patch_size' );
   is( $old->compare($new, paths => ['META.json']),
      hash { field files => [ hash { field path => 'META.json'; field patch => T; etc } ]; field changes => undef; etc },
      'paths' );
   is( $new->compare($new), hash { field files => []; field changes => undef; field prereqs => {}; etc }, 'compare to itself' );

   my $text= CPAN::InGit::DistTree->format_comparison($report);
   my $expected_head= <<~END;
      From: $old_path (version 1.00)
      To:   $new_path (version 1.02)

      == Prereq changes ==
      + runtime requires Bar 2
      ~ runtime requires Foo 1 -> 1.5
      - runtime requires Gone 0
      + test requires Test::More 0.98

      == Change log ==
      (Changes, added lines)
      1.02
        - Na\x{EF}ve fix

      == Files changed: 7 (+9 -3) ==
      M Changes  +2 -0
      M MANIFEST  +1 -0  [patch omitted: generated]
      M META.json  +1 -1  [patch omitted: generated]
      A latest  +1 -0
      M lib/Example.pm  +2 -2
      A lib/Example/Util.pm  +2 -0
      M logo.png  +0 -0  [patch omitted: binary]

      == Patches ==
      diff --git a/latest b/latest
      END
   is( substr($text, 0, length $expected_head), $expected_head, 'format_comparison' );
   unlike( CPAN::InGit::DistTree->format_comparison($report, patch => 0), qr/== Patches ==/, 'format_comparison without patches' );
};

subtest hide_version_diff => sub {
   my $filler= join '', map "# line $_\n", 1..12;
   my $make= sub ($v, $prev_v, $greeting) {
      CPAN::InGit::DistTree->new_from_archive(
         parent => $cpan_repo, filename => "Bump-$v.tar.gz", storage => 'file',
         data => \make_archive(
            "Bump-$v/META.json"       => meta_json($v),
            # nothing but the version
            "Bump-$v/lib/Only.pm"     => "package Only;\nour \$VERSION = '$v';\n${filler}=head1 VERSION\n\nversion $v.\n",
            # the version, and a real change far enough away to be a separate hunk
            "Bump-$v/lib/Both.pm"     => "package Both;\nour \$VERSION = 'v$v'; # VERSION\n${filler}sub hi { '$greeting' }\n",
            # the version changes right next to a real change
            "Bump-$v/lib/Adjacent.pm" => "package Adjacent;\nour \$VERSION = '$v';\nsub hi { '$greeting' }\n",
            # the right number, but not called a version
            "Bump-$v/lib/Unnamed.pm"  => "package Unnamed;\nmy \$x= '$v';\n",
            # called a version, but more than the number changes
            "Bump-$v/lib/More.pm"     => "package More;\nmy \$version= '$v'; # $greeting\n",
            # called a version, but not the versions of these dists
            "Bump-$v/lib/Wrong.pm"    => "package Wrong;\nmy \$min_version= '$prev_v';\n",
            # a longer number that contains the version
            "Bump-$v/lib/Longer.pm"   => "package Longer;\nmy \$version= '$v.1';\n",
         ),
      );
   };
   my ($old, $new)= ($make->('1.2.3', '1.2.2', 'hello'), $make->('1.2.4', '1.2.3', 'world'));
   my $report= $old->compare($new);
   my %files= map +( $_->{path} => $_ ), @{ $report->{files} };
   is( $files{'lib/Only.pm'}, hash { field skipped => 'version'; field patch => DNE;
         field additions => 2; field deletions => 2; etc }, 'file with only version bumps has no patch' );
   is( $files{'lib/Both.pm'}, hash { field hidden_version_hunks => 1; field skipped => DNE;
         field patch => match qr/^\+sub hi \{ 'world' \}$/m; etc }, 'version hunk removed from a patch' );
   unlike( $files{'lib/Both.pm'}{patch}, qr/^[-+].*VERSION/m, 'no version line in remaining patch' );
   like( $files{'lib/Both.pm'}{patch}, qr/\Adiff --git .*\n(?:.*\n)*?\+\+\+ .*\n\@\@ [^\n]*\n(?:[ +\\-].*\n)+\z/, 'remaining patch is well-formed' );
   for (qw( Adjacent Unnamed More Wrong Longer )) {
      is( $files{"lib/$_.pm"}, hash { field patch => match qr/^\+.*1\.2\./m; field skipped => DNE;
            field hidden_version_hunks => DNE; etc }, "$_ is not hidden" );
   }
   like( CPAN::InGit::DistTree->format_comparison($report),
      qr/^M lib\/Both\.pm  \+2 -2  \[version-only hunks hidden: 1\]\n.*^M lib\/Only\.pm  \+2 -2  \[patch omitted: version\]$/ms,
      'format_comparison' );

   %files= map +( $_->{path} => $_ ), @{ $old->compare($new, hide_version_diff => 0)->{files} };
   is( $files{'lib/Only.pm'}, hash { field patch => match qr/^\+version 1\.2\.4\.$/m; field skipped => DNE; etc },
      'hide_version_diff => 0' );
   is( $files{'lib/Both.pm'}, hash { field patch => match qr/VERSION/; field hidden_version_hunks => DNE; etc },
      'hide_version_diff => 0, partial' );
};

subtest mirror_fetch => sub {
   my $now= strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime);
   my $index_text= "Last-Updated: $now\n\nExample 1.02 $new_path\n";
   gzip \$index_text => \my $index_gz or die 'gzip failed';
   my @fetched;
   no warnings 'redefine';
   local *CPAN::InGit::MirrorTree::fetch_upstream_file= sub ($tree, $path, %options) {
      push @fetched, $path;
      return \$index_gz if $path eq 'modules/02packages.details.txt.gz';
      return \$new_archive if $path eq "authors/id/$new_path";
      return undef;
   };
   $cpan_repo->create_archive_tree('mirror', upstream_url => 'http://upstream.invalid');
   my $mirror= $cpan_repo->get_archive_tree('mirror');
   @fetched= ();
   is( $mirror->get_dist($new_path), undef, 'no fetch unless requested' );
   is( $mirror->get_dist($new_path, fetch => 1), object { call storage => 'upstream'; call name => 'Example-1.02' }, 'fetch' );
   ok( $mirror->get_dist($new_path, fetch => 1), 'again' );
   is( $mirror->get_dist('A/AU/AUTHOR/Example-9.tar.gz', fetch => 1), undef, 'not found upstream' );
   is( \@fetched, [ "authors/id/$new_path", 'authors/id/A/AU/AUTHOR/Example-9.tar.gz' ], 'downloaded once' );
   is( $mirror->has_changes, F, 'nothing added to the mirror' );
   is( $mirror->dist_storage($new_path), undef, 'archive not stored in the mirror' );
};

subtest cpangit_diff => sub {
   my @cmd= ($^X, "-I$FindBin::Bin/../lib", "$FindBin::Bin/../bin/cpangit-diff", "--git-dir=$repodir");
   my $run= sub (@args) {
      my $pid= open my $fh, '-|', @cmd, @args or die "fork: $!";
      my $out= do { local $/; <$fh> };
      close $fh;
      return ($out, $? >> 8);
   };
   # 'app' has the LOCAL patched 1.02, and source has 1.00 and 1.02
   my ($out, $exit)= $run->('--branch=source', $old_path, $new_path);
   is( $exit, 0, 'exit status' );
   like( $out, qr/\AFrom: \Q$old_path\E \(version 1\.00\)\nTo:   \Q$new_path\E/, 'header' );
   like( $out, qr/^~ runtime requires Foo 1 -> 1\.5$/m, 'prereqs' );
   like( $out, qr/^  - Na\x{C3}\x{AF}ve fix$/m, 'change log, as UTF-8' );
   like( $out, qr/^\+sub hello \{ 'hello world' \}$/m, 'patch' );

   ($out, $exit)= $run->('--branch=source', '--stat', $old_path, $new_path);
   unlike( $out, qr/^diff --git/m, '--stat omits patches' );
   like( $out, qr/^M lib\/Example\.pm  \+2 -2$/m, '--stat keeps the file summary' );

   ($out, $exit)= $run->('--branch=source', '--format=json', '--path=lib', $old_path, $new_path);
   my $json= JSON::PP->new->utf8->decode($out);
   is( [ map $_->{path}, @{ $json->{files} } ], [ 'lib/Example.pm', 'lib/Example/Util.pm' ], 'json, limited by --path' );

   unlike( ($run->('--branch=source', $old_path, $new_path))[0], qr/^diff --git a\/META\.json/m, 'generated files omitted by default' );
   ($out, $exit)= $run->('--branch=source', '--full', $old_path, $new_path);
   like( $out, qr/^M META\.json  \+1 -1\n/m, '--full has no omitted note for generated files' );
   like( $out, qr/^diff --git a\/META\.json/m, '--full shows generated files' );
   ($out, $exit)= $run->('--branch=source', '--full', '--no-include-generated', '--max-patch-size=20', $old_path, $new_path);
   like( $out, qr/^M META\.json  \+1 -1  \[patch omitted: generated\]\n/m, 'explicit option overrides --full' );
   like( $out, qr/^M lib\/Example\.pm  \+2 -2  \[patch omitted: too large\]\n/m, 'explicit size overrides --full' );

   # module name, compared between a branch and its import source
   ($out, $exit)= $run->('--branch=app', 'Example');
   is( $exit, 0, 'module form' );
   like( $out, qr/\AFrom: L\/LO\/LOCAL\/Example-1\.02\.tar\.gz .*\nTo:   \Q$new_path\E/, 'module resolved in branch and source' );
   like( $out, qr/^-sub hello \{ 'patched' \}$/m, 'local patch is visible' );

   # a file on disk
   my $file= "$repodir/Example-1.00.tar.gz";
   mkfile($file, $old_archive);
   ($out, $exit)= $run->('--branch=app', $file, 'Example');
   like( $out, qr/\AFrom: Example-1\.00 \(version 1\.00\)\nTo:   L\/LO\/LOCAL/, 'archive file compared to a module' );

   # capture STDERR of the child in a file
   my $errfile= File::Temp->new;
   open my $saved_err, '>&', \*STDERR or die "dup: $!";
   open STDERR, '>', "$errfile" or die "reopen: $!";
   ($out, $exit)= $run->('--branch=source', $old_path, 'A/AU/AUTHOR/Example-9.tar.gz');
   open STDERR, '>&', $saved_err or die "restore: $!";
   isnt( $exit, 0, 'failure for missing dist' );
   is( $out, '', 'no output for missing dist' );
   like( slurp("$errfile"), qr{\ACan't find distribution 'A/AU/AUTHOR/Example-9\.tar\.gz' in branch 'source'\n\z},
      'message for missing dist' );
};

done_testing;
