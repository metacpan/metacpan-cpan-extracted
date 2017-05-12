package t::dbix::aurora::Test::DBIx::Aurora;
use strict;
use warnings;
use Test::Docker::MySQL;
use Exporter 'import';
our @EXPORT = qw( connect_info writer reader );

sub connect_info($) {
    my $port = shift;
    [ "dbi:mysql:database=mysql;host=127.0.0.1;port=$port", "root", "", { } ]
}

sub writer { Test::Docker::MySQL->new(tag => 'punytan/p5-test-docker-mysql-5.6') }
sub reader { Test::Docker::MySQL->new(tag => 'punytan/p5-test-docker-mysql-5.6-readonly') }

1;
__END__
