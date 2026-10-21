use strict;
use warnings;
use Test::More;
use POSIX ();
use Data::Buffer::Shared;

for my $type (qw(I8 U8 I16 U16 I32 U32 I64 U64 F32 F64 Str)) {
    my $class = "Data::Buffer::Shared::$type";
    my $buf = $class->new_anon(2, $type eq 'Str' ? (16) : ());
    is($buf->set_slice(0), 1, "$type empty set_slice returns true");
    is($buf->add_slice(0), 1, "$type empty add_slice returns true") if $type =~ /^[IU]/;
    my $empty = $buf->get_raw(0, 0);
    is($empty, '', "$type empty get_raw returns an empty string");
    ok(!-e $empty, "$type empty get_raw is safe as a pathname");

    my $efd = $buf->create_eventfd;
    $buf->notify;
    $buf->attach_eventfd($efd);
    is($buf->wait_notify, 1, "$type reattaching its own eventfd preserves notifications");
    ok($buf->notify, "$type reattached eventfd remains usable");
    undef $buf;
    ok(!defined POSIX::close($efd), "$type reattached eventfd is closed on destruction");
}

done_testing;
