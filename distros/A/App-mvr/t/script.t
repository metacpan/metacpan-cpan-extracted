use strict;
use warnings;
use Test::More tests => 7;
use Test::Script::Run;
use Path::Tiny;

my $wd = path( 'corpus', path(__FILE__)->basename );
END { path($wd)->remove_tree }

subtest plain => sub {
    plan tests => 8;

    path($wd)->remove_tree;
    path($wd, "$_.txt")->touchpath for qw( one two three d/three );

    run_ok( 'mvr', ['--no-deduplicate', path($wd, "$_.txt"), path($wd, 'd') ], 'renames OK' )
        for (qw/ one two three /);

    ok path($wd, 'd', "$_.txt")->exists, "d/$_.txt exists"
        for (qw/ one two three /);

    my @files = grep {
        defined
        and $_->basename !~ qr/^(?:one|two|three)\.txt$/
    } path($wd, 'd')->children;
    is scalar @files => 1;
    like $files[0] => qr{three-.{6}\.txt$} or diag $files[0];
    note "found $files[0]";
};

subtest 'file ext' => sub {
    plan tests => 8;

    path($wd)->remove_tree;
    path($wd, $_)->touchpath for qw( one two three d/three );

    run_ok( 'mvr', ['--no-deduplicate', path($wd, $_), path($wd, 'd') ], 'renames OK' )
        for (qw/ one two three /);

    ok path($wd, 'd', $_)->exists, "d/$_ exists"
        for (qw/ one two three /);

    my @files = grep {
        defined
        and $_->basename !~ qr/^(?:one|two|three)$/
    } path($wd, 'd')->children;
    is scalar @files => 1;
    like $files[0] => qr{three-.{6}};
    note "found $files[0]";
};

subtest verbose => sub {
    plan tests => 2;

    path($wd)->remove_tree;
    path($wd, $_)->touchpath for qw( verbose d/verbose );

    run_script( 'mvr',
        ['--no-deduplicate', '-v', path($wd, 'verbose'), path($wd, 'd', 'verbose') ],
        \my $out, \my $err
    );
    is $out => '', 'no stdout';
    like $err => qr{\QFile already exists}, 'name conflict detected';
};

subtest quiet => sub {
    plan tests => 2;

    path($wd)->remove_tree;
    path($wd, $_)->touchpath for qw( quiet d/quiet );

    run_script( 'mvr',
        ['--no-deduplicate', '--quiet', path($wd, 'quiet'), path($wd, 'd')],
        \my $out, \my $err
    );
    is $out => '', 'no stdout';
    is $err => '', 'non stderr';
};

subtest dupes => sub {
    plan tests => 5;

    path($wd)->remove_tree;
    for (qw/ 1 2 /) {
        path($wd, $_)->touchpath;
        path($wd, $_)->spew(qw/test/);
    }

    {
        run_script( mvr =>
            [ '-v', path($wd, 1), path($wd, 2) ],
            \my $out, \my $err
        );
        is $out => '', 'no stdout';
        like $err => qr{\QFile already exists}, 'name conflict detected';
        like $err => qr{\Qchecking for duplication}, 'checking for duplication';
        like $err => qr{\Qare duplicates}, 'files correctly detected to be duplicates';
        is_deeply [path($wd)->children], [path($wd, 2)], 'only one file is left';
    }
};

subtest 'no dupes' => sub {
    plan tests => 7;

    path($wd)->remove_tree;
    for (qw/ 1 2 /) {
        path($wd, $_)->touchpath;
        path($wd, $_)->spew(qw/test/, $_);
    }

    run_script( 'mvr',
        ['--deduplicate', '-v', path($wd, 1), path($wd, 2) ],
        \my $out, \my $err
    );
    is $out => '', 'no stdout';
    like $err => qr{\QFile already exists}, 'name conflict detected';
    like $err => qr{\Qchecking for duplication}, 'checking for duplication';
    like $err => qr{\Qare not duplicates}, 'files correctly detected to be different';

    my @children = map { $_->basename } path($wd)->children;
    is @children, 2, 'file was actually moved' or diag explain \@children;
    like $_ => qr{^2(?:-.{6})?$}, 'filenames look right' for @children;
};

subtest version => sub {
    plan tests => 3;

    run_script( mvr => [qw/ --version /], \my $out, \my $err );
    is $? >> 8, 0, 'zero exit code';
    like $out => qr{^mvr version}, 'version reported OK';
    is $err => '', 'no stderr when reporting version';
};
