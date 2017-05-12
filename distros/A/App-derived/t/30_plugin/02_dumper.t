use strict;
use warnings;
use File::Temp;
use Test::More;
use Test::Requires {
    'Capture::Tiny' => '0.21'
};

my $stdout = Capture::Tiny::capture_stdout {
    my $pid = fork();
    if ( $pid == 0 ) {
        exec $^X, '-I./lib','./bin/derived', '-i', 1, '-M', "Dumper,interval=1", './t/CmdsFile';
        exit;
    }
    sleep 3;
    kill 'TERM', $pid;
    waitpid($pid,0);
};

my @line = split /\n/, $stdout;
ok(@line >= 2);
like( $line[0], qr/w[12]/);
like( $line[1], qr/w[12]/);

done_testing;

