use utf8;
use strict;
use warnings;

use feature 'state';
package DR::Tnt::Test;
use DR::Tnt::Test::TntInstance;
use IO::Socket::INET;
use Test::More;
use base qw(Exporter);
our @EXPORT = qw(
    free_port
    tarantool_version
    tarantool_version_check
    start_tarantool
);


sub tarantool_version() {

    local $SIG{__WARN__} = sub {  };
    if (open my $fh, '-|', 'tarantool', '-V') {
        my $v = <$fh>;
        return undef unless $v =~ /^Tarantool\s+(\S+)/;
        return $1;
    }
    return undef; 
}


sub tarantool_version_check($) {
    my ($version) = @_;
    $version ||= '1.6';

    my $v = tarantool_version;

    goto FAIL unless $v;
    my @p = split /\./, $version;
    $v =~ s/-.*//;
    my @v = split /\./, $v;

    for (my $i = 0; $i < @p; $i++) {
        last unless $i < @v;
        goto OK if $v[$i] > $p[$i];
        goto FAIL unless $v[$i] >= $p[$i];
    }

    goto FAIL unless @v >= @p;

    OK:
        return;

    FAIL: {
        my $tb = Test::More->builder; 
        my @passed = $tb->details;
        for (my $i = @passed; $i < $tb->expected_tests; $i++) {
            $tb->skip("tarantool $version is not found");
        }
        exit;
    }

}



sub free_port() {
    state $busy_ports = {};
    while( 1 ) {
        my $port = 10000 + int rand 30000;
        next if exists $busy_ports->{ $port };
        next unless IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        );
        return $busy_ports->{ $port } = $port;
    }
}

sub start_tarantool {
    my %opts = @_;
    $opts{-port} = free_port;
    DR::Tnt::Test::TntInstance->new(%opts);
}

1;
