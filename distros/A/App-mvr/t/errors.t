use strict;
use warnings;
use Test::More tests => 2;
use Test::Fatal;
use Path::Tiny;
use App::mvr;

my $wd = path( 'corpus', path(__FILE__)->basename );
END { path($wd)->remove_tree }

subtest 'same file' => sub {
    plan tests => 1;

    path($wd)->remove_tree;
    path($wd, 1)->touchpath;

    like
        exception { mvr( source => path($wd, 1), dest => path($wd, 1) ) },
        qr{\Qare the same file};
};

subtest 'not a dir' => sub {
    plan tests => 1;

    path($wd)->remove_tree;
    my @files = map { path($wd, $_)->touchpath } (1..3);

    like exception {
        mvr( source => [@files[0..$#files-1]], dest => $files[-1] )
    } => qr{\Qis not a directory};

};
