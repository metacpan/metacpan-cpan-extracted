#!/usr/bin/env perl
# Cache service: key-value store over req/rep (get/set/del operations)
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 256, 32, 8192);

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Cache server
    my %cache;
    while (my ($req, $id) = $srv->recv_wait(5.0)) {
        my ($op, $key, $val) = split /\t/, $req, 3;
        if ($op eq 'get') {
            $srv->reply($id, exists $cache{$key} ? $cache{$key} : '');
        } elsif ($op eq 'set') {
            $cache{$key} = $val;
            $srv->reply($id, 'OK');
        } elsif ($op eq 'del') {
            delete $cache{$key};
            $srv->reply($id, 'OK');
        } elsif ($op eq 'keys') {
            $srv->reply($id, join("\t", sort keys %cache));
        } else {
            $srv->reply($id, "ERR:unknown op $op");
        }
    }
    exit 0;
}

my $cli = Data::ReqRep::Shared::Client->new($path);

# Helper subs
sub cache_set { $cli->req("set\t$_[0]\t$_[1]") }
sub cache_get { $cli->req("get\t$_[0]") }
sub cache_del { $cli->req("del\t$_[0]") }
sub cache_keys { split /\t/, $cli->req("keys") }

cache_set("name", "Alice");
cache_set("age", "30");
cache_set("city", "Portland");

printf "name = %s\n", cache_get("name");
printf "age  = %s\n", cache_get("age");
printf "keys = %s\n", join(", ", cache_keys());

cache_del("age");
printf "after del: keys = %s\n", join(", ", cache_keys());

waitpid $pid, 0;
$srv->unlink;
