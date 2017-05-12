use strict;
use warnings;
use Test::More tests => 4;
use Capture::Tiny qw(capture);
use Test::Fatal qw(lives_ok);
use Path::Tiny;
use App::mvr;

my $wd = path( 'corpus', path(__FILE__)->basename );
END { path($wd)->remove_tree }

subtest main => sub {
    plan tests => 6;

    path($wd)->remove_tree;
    path($wd, "$_.jpg.tar.gz.txt")->touchpath for qw( one two three d/three );

    lives_ok {
        mvr(
            source => [map { path($wd, "$_.jpg.tar.gz.txt") } qw/ one two three /],
            dest => path($wd, 'd'),
        );
    } "mvr call didn't die";

    ok path($wd, 'd', "$_.jpg.tar.gz.txt")->exists, "corpus/d/$_.jpg.tar.gz.txt exists"
        for (qw/ one two three /);

    my @files = grep {
        defined
        and $_->basename !~ qr/^(?:one|two|three)\Q.jpg.tar.gz.txt\E$/
    } path($wd, 'd')->children;
    is scalar @files => 1;
    like $files[0] => qr{three\Q.jpg.tar.gz\E-.{6}\.txt$};
    note "found $files[0]";
};

subtest verbosity => sub {
    plan tests => 4;

    path($wd)->remove_tree;
    path($wd, $_)->touchpath for qw( verbose d/verbose );
    {
        my ($out, $err) = capture {
            local $App::mvr::VERBOSE = 2;
            mvr(
                source => path($wd, 'verbose'),
                dest => path($wd, 'd', 'verbose')
            );
        };
        is $out => '';
        like $err => qr{\QFile already exists};
    }

    path($wd)->remove_tree;
    path($wd, $_)->touchpath for qw( quiet d/quiet );
    {
        my ($out, $err) = capture {
            local $App::mvr::VERBOSE = 0;
            mvr(
                source => path($wd, 'quiet'),
                dest =>path($wd, 'd', 'quiet' )
            );
        };
        is $out => '', 'no stdout';
        is $err => '', 'no stderr';
    }
};

subtest dupes => sub {
    plan tests => 5;

    path($wd)->remove_tree;
    for (qw/ 1 2 /) {
        path($wd, $_)->touchpath;
        path($wd, $_)->spew(qw/test/);
    }

    my ($out, $err) = capture {
        local $App::mvr::VERBOSE = 2;
        mvr(
            deduplicate => 1,
            source => path($wd, 1),
            dest => path($wd, 2),
        );
    };
    is $out => '', 'no stdout';
    like $err => qr{\QFile already exists}, 'name conflict detected';
    like $err => qr{\Qchecking for duplication}, 'checking for duplication';
    like $err => qr{\Qare duplicates}, 'files correctly detected to be duplicates';
    my @remaining_files = map { $_->basename } path($wd)->children;
    is_deeply \@remaining_files, [qw( 2 )], 'only one file is left'
        or diag explain \@remaining_files;
};

subtest 'no dupes' => sub {
    plan tests => 7;

    path($wd)->remove_tree;
    for (qw/ 1 2 /) {
        path($wd, $_)->touchpath;
        path($wd, $_)->spew(qw/test/, $_);
    }

    my ($out, $err) = capture {
        local $App::mvr::VERBOSE = 2;
        mvr(
            deduplicate => 1,
            source => path($wd, 1),
            dest => path($wd, 2),
        );
    };
    is $out => '', 'no stdout';
    like $err => qr{\QFile already exists}, 'name conflict detected';
    like $err => qr{\Qchecking for duplication}, 'checking for duplication';
    like $err => qr{\Qare not duplicates}, 'files correctly detected to be different';

    my @children = map { $_->basename } path($wd)->children;
    is @children, 2, 'file was actually moved' or diag explain \@children;
    like $_ => qr{^2(?:-.{6})?$}, 'filenames look right' for @children;
};
