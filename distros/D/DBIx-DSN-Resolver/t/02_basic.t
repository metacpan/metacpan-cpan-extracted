use strict;
use Test::More;
use DBIx::DSN::Resolver;

my $CAN_INET = system($^X,'-MSocket','-e','my $r = Socket::inet_aton("google.com");exit($r ? 0 : 1)');
if ( $CAN_INET != 0 && $^O eq 'solaris') {
    warn 'DBIx::DSN::Resolver uses Socket::inet_aton for hostname resolution, please recompile Socket with "LIBS=-lresolve"'
}
my $NONE_EXIST = system($^X,'-MSocket','-e','my $r = Socket::inet_aton("foo.nonexistent");exit($r ? 1 : 0)');

my $r = DBIx::DSN::Resolver->new();
ok($r);

if ( $CAN_INET == 0 ) {
    like $r->resolv("dbi:mysql:database=mytbl;host=google.com"),
        qr/^dbi:mysql:database=mytbl;host=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/,
        'online';
}
is $r->resolv("dbi:mysql:database=mytbl;host=127.0.0.1"),
    'dbi:mysql:database=mytbl;host=127.0.0.1';
is $r->resolv("dbi:mysql:database=mytbl"),
    'dbi:mysql:database=mytbl';

if ( $NONE_EXIST == 0 ) {
    eval {
        $r->resolv("dbi:mysql:database=mytbl;host=foo.nonexistent"),
    };
    ok($@,'nonexistent');
}

eval {
    $r->resolv("bi:mysql:database=mytbl"),
};
ok($@);

if ( $CAN_INET == 0 ) {
    like $r->resolv("dbi:mysql:database=mytbl;host=google.com;port=3306"),
        qr/^dbi:mysql:database=mytbl;host=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+;port=3306$/,
        "online_and_port";
}
is $r->resolv("dbi:mysql(RaiseError=>1,PrintError=>0):database=mytbl;host=127.0.0.1"),
    'dbi:mysql(RaiseError=>1,PrintError=>0):database=mytbl;host=127.0.0.1';
is $r->resolv("dbi:mysql():database=mytbl;host=127.0.0.1"),
    'dbi:mysql():database=mytbl;host=127.0.0.1';


my $r2 = DBIx::DSN::Resolver->new(
    resolver => sub { "10.9.4.1" }
);
ok($r2);
is $r2->resolv("dbi:mysql:database=mytbl;host=foo.bar.baz"),
    'dbi:mysql:database=mytbl;host=10.9.4.1';

done_testing;

