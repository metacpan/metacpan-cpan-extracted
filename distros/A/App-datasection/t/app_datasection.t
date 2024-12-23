use Test2::V0 -no_srand => 1;
use App::datasection;
use Path::Tiny qw( path );
use App::Cmd::Tester;

my $dir = Path::Tiny->tempdir;
my $perl = $dir->child('foo.t');
$perl->spew_utf8(path(__FILE__)->slurp_utf8);

subtest 'extract' => sub {

    my $result = test_app 'App::datasection' => [ extract => "$perl" ];

    note "+datasection extract $perl";
    note $result->output;

    like($result->output, qr/foo.t$/, 'output');

    is(
        $dir,
        object {
            call [ child => 'foo.t.data/etc/config.yml' ] => object {
                call slurp_raw => "---\na: b\n";
            };
            call [ child => 'foo.t.data/foo.txt' ] => object {
                call slurp_raw => "hello world\n";
            };
        },
        'files',
    );

};

subtest 'diff' => sub {

    my $result = test_app 'App::datasection' => [ diff => "$perl" ];

    note "+datasection diff $perl";
    note $result->output;

    is(
        [split /\n/, $result->output],
        array {
            item match qr!^--- a/.*/foo.t$!;
            item match qr!^\+\+\+ b/.*/foo.t$!;
            etc;
        },
        'output',
    );

};

subtest 'insert' => sub {

    my $result = test_app 'App::datasection' => [ insert => "$perl" ];
    note "+datasection insert $perl";
    note $result->output;
    like($result->output, qr/foo.t$/, 'output');

};

subtest 'diff (same)' => sub {

    my $result = test_app 'App::datasection' => [ diff => "$perl" ];

    note "+datasection diff $perl";
    note $result->output;

    is(
        [split /\n/, $result->output],
        array {
            end;
        },
        'output',
    );

};

done_testing;

__DATA__

@@ etc/config.yml
---
a: b
@@ foo.txt
hello world
