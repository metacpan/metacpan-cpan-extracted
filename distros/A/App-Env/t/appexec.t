#!perl

use Test2::V0;
use Test::Lib;

use File::Temp;
use File::Spec::Functions qw[ catfile ];


my $exe    = catfile( qw[ blib script appexec ] );
my $lib    = catfile( qw[ t lib ] );
my $script = catfile( qw [ t bin appexec.pl ] );

{
    my $fh = File::Temp->new;

  SKIP: {
        ok(
            system( $^X, '-Mblib', "-I${lib}", $exe,
                'App1', $^X, $script, $fh->filename
              ) == 0,
            'run appexec for App1'
        ) or skip( "error running appexec", 1 );

        chomp( my $res = <$fh> );
        is( $res, '1', 'direct' );
    }
}

{
    my $fh = File::Temp->new;

  SKIP: {

        ok(
            system( $^X, '-Mblib', "-I${lib}", $exe,
                'App3', $^X, $script, $fh->filename
              ) == 0,
            'run appexec for App3'
        ) or skip( "error running appexec", 1 );

        chomp( my $res = <$fh> );
        is( $res, '1', 'alias' );
    }
}

done_testing;
