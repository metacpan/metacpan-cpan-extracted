#!perl

use Test2::V0;
use Test::Lib;

use File::Temp 'tempfile';
use File::Spec::Functions qw[ catfile ];

use App::Env;

my $script = catfile( qw [ t bin capture.pl ] );

subtest '($stdout, $stderr, $exit)' => sub {
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );

    my ( $stdout, $stderr, $exit ) = $app1->capture( $^X, $script );
    is( $exit, 0, 'exit' );

    is( $stdout, "STDOUT\n", 'STDOUT' );
    is( $stderr, "STDERR\n", 'STDERR' );
};

subtest 'redirect' => sub {

    subtest 'filehandles' => sub {
        my $app1 = App::Env->new( 'App1', { Cache => 0 } );
        my ( $out_fh, $out_fname ) = tempfile();
        my ( $err_fh, $err_fname ) = tempfile();
        my $exit = $app1->capture(
            $^X, $script,
            {
                stdout => $out_fh,
                stderr => $err_fh,
            },
        );
        is( $exit, 0, 'exit' );
        $out_fh->flush;
        $out_fh->seek( 0, 0 );
        $err_fh->flush;
        $err_fh->seek( 0, 0 );

        is( $out_fh->getline, "STDOUT\n", 'STDOUT' );
        is( $err_fh->getline, "STDERR\n", 'STDERR' );

    };

    subtest 'file names' => sub {
        my $app1 = App::Env->new( 'App1', { Cache => 0 } );
        my ( $out_fh, $out_fname ) = tempfile;
        my ( $err_fh, $err_fname ) = tempfile;
        my $exit = $app1->capture(
            $^X, $script,
            {
                stdout => $out_fname,
                stderr => $err_fname,
            },
        );
        is( $exit, 0, 'exit' );

        is( $out_fh->getline, "STDOUT\n", 'STDOUT' );
        is( $err_fh->getline, "STDERR\n", 'STDERR' );

    };

};

subtest '$?' => sub {
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );

    $app1->capture( $^X, $script, 'exit' );
    isnt( $?, 0, 'unsuccessful system call' );
};


subtest 'SysFatal' => sub {
    my $app1 = App::Env->new( 'App1', { Cache => 0, SysFatal => 1 } );

    ok( dies { $app1->capture( $^X, $script, 'exit' ); }, 'unsuccessful system call', );
};

subtest qexec => sub {
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );

    my $stdout = $app1->qexec( $^X, $script, 'a', 'b' );

    is( $stdout, "a\nb\n", 'scalar' );

    my @stdout = $app1->qexec( $^X, $script, 'a', 'b' );

    is( \@stdout, [ "a\n", "b\n" ], 'list' );

};

done_testing;
