use strict;
use warnings;
use Test::More;
use DBIx::DSN::Resolver;

my @test = qw!
dbi:mysql:database=mytbl;host=127.0.0.1
dbi:mysql:mytbl;host=127.0.0.1
dbi:mysql:database=mytbl;hostname=127.0.0.1
dbi:mysql:mytbl;hostname=127.0.0.1
dbi:mysql:database=mytbl;hostname=127.0.0.1:3306
dbi:mysql:mytbl;hostname=127.0.0.1:3306
!;

my $r = DBIx::DSN::Resolver->new();
for ( @test ) {
    is($r->resolv($_), $_);
}

done_testing();


