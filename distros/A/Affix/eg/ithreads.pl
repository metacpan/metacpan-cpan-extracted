use v5.40;
use blib;
use threads;
use Affix qw[:all];
#
affix libc, [ 'abs' => 'absolute' ], [Int] => Int;
typedef Fun => Double;
#
say 'Main:     absolute(-420) -> ' . absolute(-420);
my @threads = map {
    threads->create( sub { say sprintf 'Thread %d: absolute(-100) -> %d', threads->tid, absolute(-100) } )
} 1 .. 2;
#
$_->join() for @threads;
