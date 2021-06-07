#!perl

use 5.010001;
use strict;
use warnings;
use FindBin '$Bin';
use Test::Deep;
use Test::More 0.98;

# list of minicpans test data:
#
# - minicpan1:
#   + 4 authors, 4 releases (1 BUDI's, 3 TONO's)
# - minicpan2:
#   + author changes
#     - 1 unchanged (WATI)
#     - 1 new author (KADAL)
#     - 1 removed author (NINA)
#     - 1 changed author (BUDI, email)
#   + distro changes
#     - 1 unchanged distro: Simpel-Banget-0.001.tar.gz
#     - 1 new distro: Kadal-Busuk-1.00.tar.bz2
#       + extract naked, no containing folder
#       + no changes, manifest, license, readme
#       + modules: Kadal::Busuk, Kadal::Busuk::Sekali (no pod, no abstract, no version)
#       + dep: runtime-requires to Foo::Bar
#       + dep: test-requires to Foo::Bar::Baz
#     - 1 new distro: Kadal-Rusak-1.00.tar.gz
#       + not a tar.gz, cannot be extracted
#     - 1 new distro: Kadal-Hilang-1.00.tar.gz
#       + indexed but does not exist (assumed not downloaded)
#     - 1 new distro: Kadal-Jelek-1.00.tar.bz2
#       + modules: Kadal::Jelek, Kadal::Jelek::Sekali (all put in top-level dir)
#       + no distro metadata, but has Makefile.PL which can be run to produce MYMETA.*
#       + 2 new scripts (in bin/, script/)
#     - 1 updated distro (Foo-Bar-0.02)
#       + release file now in subdir subdir1/
#       + format changed to zip
#       + has META.yml now instead of META.json
#       + add a module: Foo::Bar::Qux (different version: 3.10)
#       + removed a module: Foo::Bar::Baz
#       + update module: Foo::Bar (abstract, add subs)
#       + add, remove some deps, update some deps (version)
#     - 1 removed distro (Simpel-0.001)
#       + 1 removed module and 1 removed script
#     - 1 updated distro + change maintainership (TONO -> BUDI): Sederhana-v2.0.2
#       + 1 updated script: sederhana (abstract)
#       + 1 update module: Sederhana (abstract)
# - TODO minicpan3:
# - TODO minicpan4:
#
# todo:
# - distro that use Build.PL
# - distro that has META.yml as well as META.json
# - dep that change phase/rel
# - option: skipped files
# - option: skipped files from sub indexing
# - pod:
# - mentions:

use File::Copy::Recursive qw(dircopy fcopy);
use File::Temp qw(tempdir tempfile);
use IPC::System::Options qw(system);
use JSON::MaybeXS;

my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});

subtest minicpan1 => sub {
    dircopy("$Bin/data/minicpan1", "$tempdir/minicpan1");

    my $res;

    run_lcpan_ok("update", "--cpan", "$tempdir/minicpan1", "--no-use-bootstrap", "--no-update-files");

    subtest "authors" => sub {

        $res = run_lcpan_json("authors", "--cpan", "$tempdir/minicpan1");
        is_deeply($res->{stdout}, [qw/BUDI NINA TONO WATI/]);

        $res = run_lcpan_json("authors", "--cpan", "$tempdir/minicpan1", "-l");
        is_deeply($res->{stdout}, [
            {id=>'BUDI', name=>'Budi Bahagia', email=>'CENSORED'},
            {id=>'NINA', name=>'Nina Nari', email=>'nina1993@example.org'},
            {id=>'TONO', name=>'Tono Tentram', email=>'CENSORED'},
            {id=>'WATI', name=>'Wati Legowo', email=>'wati@example.com'},
        ]);

        # XXX test options
    };

    subtest "modules, mods" => sub {

        $res = run_lcpan_json("modules", "--cpan", "$tempdir/minicpan1");
        is_deeply($res->{stdout}, [
            'Foo::Bar',
            'Foo::Bar::Baz',
            'Sederhana',
            'Sederhana::Juga',
            'Simpel',
            'Simpel::Banget',
        ]);

        $res = run_lcpan_json("mods", "--cpan", "$tempdir/minicpan1", "-l");
        cmp_deeply($res->{stdout}, [
            superhashof({
                module   => 'Foo::Bar',
                dist     => 'Foo-Bar',
                author   => 'BUDI',
                version  => '0.01',
                abstract => 'A Foo::Bar module for testing',
            }),
            superhashof({
                module   => 'Foo::Bar::Baz',
                dist     => 'Foo-Bar',
                author   => 'BUDI',
                version  => '0.01',
                abstract => 'A Foo::Bar::Baz module for testing',
            }),
            superhashof({
                module   => 'Sederhana',
                dist     => 'Sederhana',
                author   => 'TONO',
                version  => 'v2.0.1',
                abstract => 'A simple module',
            }),
            superhashof({
                module   => 'Sederhana::Juga',
                dist     => 'Sederhana',
                author   => 'TONO',
                version  => undef,
                abstract => 'Another simple module',
            }),
            superhashof({
                module   => 'Simpel',
                dist     => 'Simpel',
                author   => 'TONO',
                version  => '0.001',
                abstract => 'A modest module',
            }),
            superhashof({
                module   => 'Simpel::Banget',
                dist     => 'Simpel-Banget',
                author   => 'TONO',
                version  => '0.001',
                abstract => 'A very modest module',
            }),
        ]);

        # XXX test options
    };

    subtest "dists" => sub {

        $res = run_lcpan_json("dists", "--cpan", "$tempdir/minicpan1");
        is_deeply($res->{stdout}, [qw/Foo-Bar Sederhana Simpel Simpel-Banget/]);

        $res = run_lcpan_json("dists", "--cpan", "$tempdir/minicpan1", "-l");
        cmp_deeply($res->{stdout}, [
            superhashof({
                dist     => 'Foo-Bar',
                author   => 'BUDI',
                version  => '0.01',
                release  => 'Foo-Bar-0.01.tar.gz',
                abstract => 'A Foo::Bar module for testing',
                # XXX rel_size, rel_mtime > 0
            }),
            superhashof({
                dist     => 'Sederhana',
                author   => 'TONO',
                version  => '2.0.1',
                release  => 'Sederhana-v2.0.1.tar.gz',
                abstract => 'A simple distribution',
                # XXX rel_size, rel_mtime > 0
            }),
            superhashof({
                dist     => 'Simpel',
                author   => 'TONO',
                version  => '0.001',
                release  => 'Simpel-0.001.tar.gz',
                abstract => 'A modest distribution',
                # XXX rel_size, rel_mtime > 0
            }),
            superhashof({
                dist     => 'Simpel-Banget',
                author   => 'TONO',
                version  => '0.001',
                release  => 'Simpel-Banget-0.001.tar.gz',
                abstract => 'A very modest distribution',
                # XXX rel_size, rel_mtime > 0
            }),
        ]);

        # XXX test options
    };

    subtest "releases, rels" => sub {

        $res = run_lcpan_json("releases", "--cpan", "$tempdir/minicpan1");
        is_deeply($res->{stdout}, [
            'B/BU/BUDI/Foo-Bar-0.01.tar.gz',
            'T/TO/TONO/Sederhana-v2.0.1.tar.gz',
            'T/TO/TONO/Simpel-0.001.tar.gz',
            'T/TO/TONO/Simpel-Banget-0.001.tar.gz',
        ]);

        $res = run_lcpan_json("rels", "--cpan", "$tempdir/minicpan1", "-l");
        cmp_deeply($res->{stdout}, [
            superhashof({
                name => 'B/BU/BUDI/Foo-Bar-0.01.tar.gz',
                author   => 'BUDI',
                file_status => 'ok',
                file_error => undef,
                meta_status => 'ok',
                meta_error => undef,
                pod_status => 'ok',
                has_makefilepl => 1,
                has_buildpl => 0,
                has_metayml => 0,
                has_metajson => 1,
                # XXX size, mtime > 0
            }),
            superhashof({
                name => 'T/TO/TONO/Sederhana-v2.0.1.tar.gz',
                author   => 'TONO',
                has_metayml => 1,
                has_metajson => 0,
            }),
            superhashof({
                name => 'T/TO/TONO/Simpel-0.001.tar.gz',
                author   => 'TONO',
                has_metayml => 1,
                has_metajson => 0,
            }),
            superhashof({
                name => 'T/TO/TONO/Simpel-Banget-0.001.tar.gz',
                author   => 'TONO',
                has_metayml => 1,
                has_metajson => 0,
            }),
        ]);
    };

    subtest "deps" => sub {

        my $hoh;

        $res = run_lcpan_json("deps", "--cpan", "$tempdir/minicpan1", "--all", "Foo::Bar");
        $hoh = _deps2hoh($res->{stdout});
        is_deeply($hoh, {
            develop => { requires => {
                'Pod::Coverage::TrustPod' => 0,
                'Test::Perl::Critic' => 0,
                'Test::Pod' => '1.41',
                'Test::Pod::Coverage' => '1.08',
            }},
            configure => { requires => {
                'ExtUtils::MakeMaker' => 0,
            }},
            test => { requires => {
                'File::Spec' => 0,
                'IO::Handle' => 0,
                'IPC::Open3' => 0,
                'Test::More' => 0,
            }},
        }) or diag explain $hoh;

        # this dist will disappear later
        $res = run_lcpan_json("deps", "--cpan", "$tempdir/minicpan1", "--all", "Simpel");
        $hoh = _deps2hoh($res->{stdout});
        is_deeply($hoh, {
            runtime => { requires => {
                'Foo::Bar' => 0,
            }},
        }) or diag explain $hoh;

        $res = run_lcpan_json("deps", "--cpan", "$tempdir/minicpan1", "-l2", "Sederhana");
        cmp_deeply($res->{stdout}, [
            superhashof({module=>'Simpel'}),
            superhashof({module=>'  Foo::Bar'}),
            superhashof({module=>'Simpel::Banget'}),
        ]);

    };

    subtest "rdeps" => sub {
        $res = run_lcpan_json("rdeps", "--cpan", "$tempdir/minicpan1", "--all", "Foo::Bar");
        cmp_deeply($res->{stdout}, [
            superhashof({dist=>'Simpel'}),
        ]);

        $res = run_lcpan_json("rdeps", "--cpan", "$tempdir/minicpan1", "--all", "-l2", "Foo::Bar");
        cmp_deeply($res->{stdout}, [
            superhashof({dist=>'Simpel'}),
            superhashof({dist=>'  Sederhana'}),
            superhashof({dist=>'  Simpel-Banget'}),
        ]);
    };

    subtest "contents" => sub {

        $res = run_lcpan_json("contents", "--cpan", "$tempdir/minicpan1");
        ok(scalar(@{ $res->{stdout} }));

        # XXX test contents detail
    };

    subtest "scripts" => sub {

        $res = run_lcpan_json("scripts", "--cpan", "$tempdir/minicpan1");
        is_deeply($res->{stdout}, [
            'sederhana',            # [0]
            'simpel',               # [1]
            'simpel-banget',        # [2]
        ]);

        $res = run_lcpan_json("scripts", "--cpan", "$tempdir/minicpan1", "-l");
        cmp_deeply($res->{stdout}, [
            superhashof({
                name => 'sederhana',
                cpanid => 'TONO',
                abstract => 'A simple script',
                dist => 'Sederhana',
                dist_version => '2.0.1',
            }),
            superhashof({
                name => 'simpel',
                cpanid => 'TONO',
                abstract => 'A modest script',
                dist => 'Simpel',
                dist_version => '0.001',
            }),
            superhashof({
                name => 'simpel-banget',
                cpanid => 'TONO',
                abstract => 'A very modest script',
                dist => 'Simpel-Banget',
                dist_version => '0.001',
            }),
        ]);

        # XXX test options
    };

    # XXX mentions

    subtest "related-mods" => sub {
        $res = run_lcpan_json("related-mods", "--cpan", "$tempdir/minicpan1", "Sederhana");
        cmp_deeply($res->{stdout}, [
            superhashof({module=>'Simpel'}),
            superhashof({module=>'Simpel::Banget'}),
        ]);
    };

    subtest "changes" => sub {
        $res = run_lcpan_ok("changes", "--cpan", "$tempdir/minicpan1", "Foo-Bar");
        like($res->{stdout}, qr/First release/);
    };

    subtest "dist2rel" => sub {
        $res = run_lcpan_ok("dist2rel", "--cpan", "$tempdir/minicpan1", "Sederhana");
        cmp_deeply($res->{stdout}, "T/TO/TONO/Sederhana\n");
        # XXX option: --full-path
    };

    subtest "dist-meta" => sub {
        $res = run_lcpan_json("dist-meta", "--cpan", "$tempdir/minicpan1", "Sederhana");
        cmp_deeply($res->{stdout}, superhashof({
            name => 'Sederhana',
            license => 'perl',
            # ...
        }));
    };

    subtest "scripts-from-same-dist" => sub {
        $res = run_lcpan_json("scripts-from-same-dist", "--cpan", "$tempdir/minicpan1", "simpel");
        cmp_deeply($res->{stdout}, ["simpel"]); # XXX test dists with multiple scripts
    };
};

subtest minicpan2 => sub {
    dircopy("$Bin/data/minicpan2", "$tempdir/minicpan2");
    fcopy  ("$tempdir/minicpan1/index.db", "$tempdir/minicpan2/index.db");

    my $res;

    run_lcpan_ok("update", "--cpan", "$tempdir/minicpan2", "--no-update-files");

    subtest "authors" => sub {

        $res = run_lcpan_json("authors", "--cpan", "$tempdir/minicpan2");
        is_deeply($res->{stdout}, [qw/BUDI KADAL TONO WATI/]);

        $res = run_lcpan_json("authors", "--cpan", "$tempdir/minicpan2", "-l");
        is_deeply($res->{stdout}, [
            {id=>'BUDI' , name=>'Budi Bahagia', email=>'budi@example.org'},
            {id=>'KADAL', name=>'Kadal', email=>'CENSORED'},
            {id=>'TONO' , name=>'Tono Tentram', email=>'CENSORED'},
            {id=>'WATI' , name=>'Wati Legowo', email=>'wati@example.com'},
        ]);

        # XXX test options
    };

    subtest "modules, mods" => sub {

        $res = run_lcpan_json("modules", "--cpan", "$tempdir/minicpan2");
        is_deeply($res->{stdout}, [
            'Foo::Bar',             # [0]
            'Foo::Bar::Baz',        # [1]
            'Foo::Bar::Qux',        # [2]
            'Kadal::Busuk',         # [3]
            'Kadal::Busuk::Sekali', # [4]
            'Kadal::Hilang',        # [5]
            'Kadal::Jelek',         # [6]
            'Kadal::Jelek::Sekali', # [7]
            'Kadal::Rusak',         # [8]
            'Sederhana',            # [9]
            'Sederhana::Juga',      # [10]
            'Simpel::Banget',       # [11]
        ]);

        $res = run_lcpan_json("mods", "--cpan", "$tempdir/minicpan2", "-l");
        is($res->{stdout}[0]{version}, '0.02', 'Foo::Bar version updated to 0.02');
        is($res->{stdout}[1]{version}, '0.01', 'Foo::Bar::Baz version still at 0.01, refers to old dist');
        is($res->{stdout}[2]{version}, '3.10', 'Foo::Bar::Qux version follows 02packages');
        cmp_deeply($res->{stdout}[5], superhashof({
            module => 'Kadal::Hilang',
            author => 'KADAL',
            version => '1.00',
            dist => 'Kadal-Hilang', # set by changing Kadal::Hilang -> Kadang-Hilang
        }), 'module with no release (Kadal-Hilang) file still indexed');
        cmp_deeply($res->{stdout}[8], superhashof({
            module => 'Kadal::Rusak',
            author => 'KADAL',
            version => '1.00',
            dist => 'Kadal-Rusak', # set by changing Kadal::Rusak -> Kadang-Rusak
        }), 'module with release file unextractable (Kadal-Rusak) file still indexed');
        cmp_deeply($res->{stdout}[9], superhashof({
            module => 'Sederhana',
            author => 'BUDI',
            version => 'v2.0.2',
            dist => 'Sederhana',
            abstract => 'A simple yet useful module',
        }), "Sederhana updated");
        cmp_deeply($res->{stdout}[11], superhashof({
            module => 'Simpel::Banget',
            author => 'TONO',
            version => '0.001',
            dist => 'Simpel-Banget',
            abstract => 'A very modest module',
        }), "Simpel::Banget unchanged");

        # XXX test options
    };

    subtest "dists" => sub {

        $res = run_lcpan_json("dists", "--cpan", "$tempdir/minicpan2");
        is_deeply($res->{stdout}, [
            'Foo-Bar',
            'Foo-Bar',
            'Kadal-Busuk',
            'Kadal-Hilang',
            'Kadal-Jelek',
            'Kadal-Rusak',
            'Sederhana',
            'Simpel-Banget',
        ]);
        $res = run_lcpan_json("dists", "--cpan", "$tempdir/minicpan2", "--latest");
        is_deeply($res->{stdout}, [
            'Foo-Bar',
            'Kadal-Busuk',
            'Kadal-Hilang',
            'Kadal-Jelek',
            'Kadal-Rusak',
            'Sederhana',
            'Simpel-Banget',
        ]);

        $res = run_lcpan_json("dists", "--cpan", "$tempdir/minicpan2", "-l");
        # XXX test more details
    };

    subtest "releases, rels" => sub {

        $res = run_lcpan_json("releases", "--cpan", "$tempdir/minicpan2");
        is_deeply($res->{stdout}, [
            'B/BU/BUDI/Foo-Bar-0.01.tar.gz',
            'K/KA/KADAL/Kadal-Busuk-1.00.tar.bz2',
            'K/KA/KADAL/Kadal-Hilang-1.00.tar.gz',
            'K/KA/KADAL/Kadal-Jelek-1.00.tgz',
            'K/KA/KADAL/Kadal-Rusak-1.00.tar.gz',
            'B/BU/BUDI/Sederhana-v2.0.2.tar.gz',
            'T/TO/TONO/Simpel-Banget-0.001.tar.gz',
            'B/BU/BUDI/subdir1/Foo-Bar-0.02.zip',
        ]);

        $res = run_lcpan_json("rels", "--cpan", "$tempdir/minicpan2", "-l");
        # XXX test more details
    };

    subtest "deps" => sub {

        $res = run_lcpan_json("deps", "--cpan", "$tempdir/minicpan2", "--all", "Foo::Bar");
        my $deps = {};
        for (@{ $res->{stdout} }) { $deps->{ $_->{phase} }{ $_->{rel} }{ $_->{module} } = $_->{version} }
        is_deeply($deps, {
            configure => { requires => {
                'ExtUtils::MakeMaker' => 0,
            }},
            build => { requires => {
                'File::Spec' => '0.01',
                'IO::HandleTest' => 0,
                'IPC::Open3' => 0,
                'Test::More' => 0,
            }},
        }, "deps shows the latest version of Foo-Bar") or diag explain $deps;

        $res = run_lcpan_json("deps", "--cpan", "$tempdir/minicpan2", "--all", 'Foo::Bar@0.01');
        my $hoh = _deps2hoh($res->{stdout});
        is_deeply($hoh, {
            develop => { requires => {
                'Pod::Coverage::TrustPod' => 0,
                'Test::Perl::Critic' => 0,
                'Test::Pod' => '1.41',
                'Test::Pod::Coverage' => '1.08',
            }},
            configure => { requires => {
                'ExtUtils::MakeMaker' => 0,
            }},
            test => { requires => {
                'File::Spec' => 0,
                'IO::Handle' => 0,
                'IPC::Open3' => 0,
                'Test::More' => 0,
            }},
        }, "deps can still show deps of older dists that are indexed") or diag explain $hoh;

        $res = run_lcpan_json("deps", "--cpan", "$tempdir/minicpan2", "--all", "Foo::Bar@9.9");
        $hoh = _deps2hoh($res->{stdout});
        is_deeply($hoh, {
        }, "deps of unknown dist version") or diag explain $hoh;

        $res = run_lcpan_json("deps", "--cpan", "$tempdir/minicpan2", "--all", "Sederhana");
        cmp_deeply($res->{stdout}, [
            superhashof({module=>'Simpel', author=>undef}),
            superhashof({module=>'Simpel::Banget', author=>'TONO'}),
        ], "a broken dependency (points to an unindexed module");
    };

    subtest "contents" => sub {

        $res = run_lcpan_json("contents", "--cpan", "$tempdir/minicpan2");
        ok(scalar(@{ $res->{stdout} }));

        # XXX test contents detail
    };

    subtest "scripts" => sub {

        $res = run_lcpan_json("scripts", "--cpan", "$tempdir/minicpan2");
        is_deeply($res->{stdout}, [
            'simpel-banget',
            'script2',
            'script1',
            'sederhana',
        ]);

        # XXX test more details
    };

};

DONE_TESTING:
done_testing;

sub run_lcpan {
    my ($stdout, $stderr);
    system(
        {
            env => {PERL5OPT=>"-I$Bin/../lib"},
            log => 1,
            ($ENV{DEBUG} ? (tee_stdout => \$stdout) : (capture_stdout => \$stdout)),
            ($ENV{DEBUG} ? (tee_stderr => \$stderr) : (capture_stderr => \$stderr)),
        },
        $^X, "$Bin/../script/lcpan",
        "--no-config",
        ($ENV{DEBUG} ? ("--trace") : ()),
        @_,
    );

    my ($exit_code, $signal, $core_dump) = ($? < 0 ? $? : $? >> 8, $? & 127, $? & 128);
    return {
        exit_code => $exit_code,
        signal    => $signal,
        core_dump => $core_dump,
        stdout    => $stdout,
        stderr    => $stderr,
    };
}

sub run_lcpan_json {
    my $res = run_lcpan(@_, "--format=json");
    eval {
        $res->{stdout} = JSON::MaybeXS::decode_json($res->{stdout});
    };
    if ($@) {
        diag "stdout is <<$res->{stdout}>>";
        warn;
    }
    $res;
}

sub run_lcpan_ok {
    my $res = run_lcpan(@_);
    is($res->{exit_code}, 0);
    $res;
}

sub _deps2hoh {
    my $deps = shift;
    my $hoh = {};
    for (@{ $deps }) {
        $hoh->{ $_->{phase} }{ $_->{rel} }{ $_->{module} } = $_->{version};
    }
    $hoh;
}
