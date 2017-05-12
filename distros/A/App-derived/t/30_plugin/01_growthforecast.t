use strict;
use warnings;
use File::Temp;
use Test::More;
use Test::Requires {
    'Test::TCP' => '1.18',
    'Plack' => '1.0013',
};

require Plack::Loader;
require Test::TCP;

my ($fh, $tmpfile) = File::Temp::tempfile( UNLINK => 0, EXLOCK => 0 );
close($fh);

my $app = sub {
    my $env = shift;
    open(my $afh, '>>:unix', $tmpfile) or die $!;
    print $afh $env->{PATH_INFO}."\n";
    close($afh);
    [200,["Content-Type"=>"text/html"],["OK"]];
};

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $pid = fork();
        if ( $pid ) {
            for ( 1..20 ) {
                open(my $afh, $tmpfile);
                my @line = <$afh>;
                last if @line >= 2;
                sleep 1;
            }
        }
        elsif ( defined $pid ) {
            #child
            exec $^X, '-I./lib','./bin/derived', '-i', 1, '-M', 
                "GrowthForecast,api_url=http://localhost:$port/api/,service=foo,section=bar,interval=3", 
                './t/CmdsFile';
            exit;
        }
        kill 'TERM', $pid;
        waitpid($pid,0);
    },
    server => sub {
        my $port = shift;
        Plack::Loader->load(
            'Standalone',
            port => $port
        )->run($app);
        exit;
    }
);

open(my $afh, $tmpfile);
my @line = <$afh>;
ok(@line >= 2);
like( $line[0], qr/w[12]/);
like( $line[1], qr/w[12]/);
unlink($tmpfile);

done_testing();


