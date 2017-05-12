use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use_ok('App::War');

my $war = App::War->new();

# override methods "init" and "rank"
my @methods = qw/ init rank /;
my %count;
for my $m (@methods) {
    no strict 'refs';
    no warnings 'redefine';
    *{"App::War::$m"} = sub { $count{$m}++; q(); };
}
$war->run;
is_deeply(\%count,{ map { $_ => 1 } @methods });
