package App::redisp::Commands;
BEGIN {
  $App::redisp::Commands::VERSION = '0.11';
}
use strict;
use base "Exporter";

our @EXPORT = qw(@COMMANDS);

our @COMMANDS = qw(
  get
  set
  setnx
  setex
  append
  strlen
  del
  exists
  setbit
  getbit
  setrange
  getrange
  substr
  incr
  decr
  mget
  rpush
  lpush
  rpushx
  lpushx
  linsert
  rpop
  lpop
  brpop
  brpoplpush
  blpop
  llen
  lindex
  lset
  lrange
  ltrim
  lrem
  rpoplpush
  sadd
  srem
  smove
  sismember
  scard
  spop
  srandmember
  sinter
  sinterstore
  sunion
  sunionstore
  sdiff
  sdiffstore
  smembers
  zadd
  zincrby
  zrem
  zremrangebyscore
  zremrangebyrank
  zunionstore
  zinterstore
  zrange
  zrangebyscore
  zrevrangebyscore
  zcount
  zrevrange
  zcard
  zscore
  zrank
  zrevrank
  hset
  hsetnx
  hget
  hmset
  hmget
  hincrby
  hdel
  hlen
  hkeys
  hvals
  hgetall
  hexists
  incrby
  decrby
  getset
  mset
  msetnx
  randomkey
  select
  move
  rename
  renamenx
  expire
  expireat
  keys
  dbsize
  auth
  ping
  echo
  save
  bgsave
  bgrewriteaof
  shutdown
  lastsave
  type
  multi
  exec
  discard
  sync
  flushdb
  flushall
  sort
  info
  monitor
  ttl
  persist
  slaveof
  debug
  config
  subscribe
  unsubscribe
  psubscribe
  punsubscribe
  publish
  watch
  unwatch  
);

1;

__END__
=pod

=head1 NAME

App::redisp::Commands

=head1 VERSION

version 0.11

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the terms of the Beerware license.

=cut

