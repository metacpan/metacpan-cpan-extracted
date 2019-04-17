use strict;
use warnings;
use Test::More;
use AnyEvent::Open3::Simple::Process;

my $proc = eval { no warnings 'once'; AnyEvent::Open3::Simple::Process->new(42, \*foo) };
diag $@ if $@;
isa_ok $proc, 'AnyEvent::Open3::Simple::Process';

done_testing;
