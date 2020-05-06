#!perl

use 5.010001;
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 0.98;

# list of minicpans test data:
#
# - minicpan1: 4 authors, only contains 1 release (BUDI)

# list of releases test data:
#
# - Foo-Bar-0.01.tar.gz: META.json
#
# todo:
# - distro with META.yml
# - distro with no metadata
# - distro that cannot be extracted
# - distro with no enclosing folder (naked)
# - distro in zip format
# - distro in tar.bz2 format
# - release file in subdir
# - new module
# - updated module
# - removed module
# - removed distro
# - new author
# - changed author
# - removed author
# - two versions of distro (with some unindexed module)
# - different module versions in a distro
# - scripts
# - option: skipped files
# - option: skipped files from sub indexing
# - pod:
# - mentions
# - deps

use File::Copy::Recursive qw(dircopy);
use File::Temp qw(tempdir tempfile);
use IPC::System::Options qw(system);
use JSON::MaybeXS;

subtest minicpan1 => sub {
    my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
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
        is_deeply($res->{stdout}, [qw/Foo::Bar Foo::Bar::Baz/]);

        $res = run_lcpan_json("mods", "--cpan", "$tempdir/minicpan1", "-l");
        is($res->{stdout}[0]{module}, 'Foo::Bar');
        is($res->{stdout}[0]{dist}, 'Foo-Bar');
        is($res->{stdout}[0]{author}, 'BUDI');
        is($res->{stdout}[0]{version}, '0.01');
        # XXX why is abstract blank?

        is($res->{stdout}[1]{module}, 'Foo::Bar::Baz');
        is($res->{stdout}[1]{dist}, 'Foo-Bar');
        is($res->{stdout}[1]{author}, 'BUDI');
        is($res->{stdout}[1]{version}, '0.01');
        # XXX why is abstract blank?

        # XXX test options
    };

    subtest "dists" => sub {

        $res = run_lcpan_json("dists", "--cpan", "$tempdir/minicpan1");
        is_deeply($res->{stdout}, [qw/Foo-Bar/]);

        $res = run_lcpan_json("dists", "--cpan", "$tempdir/minicpan1", "-l");
        is($res->{stdout}[0]{dist}, 'Foo-Bar');
        is($res->{stdout}[0]{author}, 'BUDI');
        is($res->{stdout}[0]{version}, '0.01');
        is($res->{stdout}[0]{release}, 'Foo-Bar-0.01.tar.gz');
        is($res->{stdout}[0]{abstract}, 'A Foo::Bar module for testing');

        # XXX test options
    };

    subtest "dists" => sub {
        # XXX why is Foo-Bar-0.01.tar.gz not indexed?

        ok 1;
    };

    subtest "contents" => sub {

        $res = run_lcpan_json("contents", "--cpan", "$tempdir/minicpan1");
        ok(scalar(@{ $res->{stdout} }));

        # XXX test contents detail
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
    warn if $@;
    $res;
}

sub run_lcpan_ok {
    my $res = run_lcpan(@_);
    is($res->{exit_code}, 0);
    $res;
}
