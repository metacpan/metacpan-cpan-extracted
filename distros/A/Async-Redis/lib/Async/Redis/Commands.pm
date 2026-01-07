# lib/Future/IO/Redis/Commands.pm
# AUTO-GENERATED - DO NOT EDIT
# Generated from redis-doc commands.json
#
# This module provides async method wrappers for all Redis commands.
# Consume this role in Async::Redis.

package Async::Redis::Commands;

use strict;
use warnings;
use 5.018;

use Future::AsyncAwait;

async sub acl {
    my $self = shift;
    return await $self->command('ACL', @_);
}


async sub acl_cat {
    my $self = shift;
    return await $self->command('ACL', 'CAT', @_);
}


async sub acl_deluser {
    my $self = shift;
    return await $self->command('ACL', 'DELUSER', @_);
}


async sub acl_dryrun {
    my $self = shift;
    return await $self->command('ACL', 'DRYRUN', @_);
}


async sub acl_genpass {
    my $self = shift;
    return await $self->command('ACL', 'GENPASS', @_);
}


async sub acl_getuser {
    my $self = shift;
    return await $self->command('ACL', 'GETUSER', @_);
}


async sub acl_help {
    my $self = shift;
    return await $self->command('ACL', 'HELP', @_);
}


async sub acl_list {
    my $self = shift;
    return await $self->command('ACL', 'LIST', @_);
}


async sub acl_load {
    my $self = shift;
    return await $self->command('ACL', 'LOAD', @_);
}


async sub acl_log {
    my $self = shift;
    return await $self->command('ACL', 'LOG', @_);
}


async sub acl_save {
    my $self = shift;
    return await $self->command('ACL', 'SAVE', @_);
}


async sub acl_setuser {
    my $self = shift;
    return await $self->command('ACL', 'SETUSER', @_);
}


async sub acl_users {
    my $self = shift;
    return await $self->command('ACL', 'USERS', @_);
}


async sub acl_whoami {
    my $self = shift;
    return await $self->command('ACL', 'WHOAMI', @_);
}


async sub append {
    my $self = shift;
    return await $self->command('APPEND', @_);
}


async sub asking {
    my $self = shift;
    return await $self->command('ASKING', @_);
}


async sub auth {
    my $self = shift;
    return await $self->command('AUTH', @_);
}


async sub bgrewriteaof {
    my $self = shift;
    return await $self->command('BGREWRITEAOF', @_);
}


async sub bgsave {
    my $self = shift;
    return await $self->command('BGSAVE', @_);
}


async sub bitcount {
    my $self = shift;
    return await $self->command('BITCOUNT', @_);
}


async sub bitfield {
    my $self = shift;
    return await $self->command('BITFIELD', @_);
}


async sub bitfield_ro {
    my $self = shift;
    return await $self->command('BITFIELD_RO', @_);
}


async sub bitop {
    my $self = shift;
    return await $self->command('BITOP', @_);
}


async sub bitpos {
    my $self = shift;
    return await $self->command('BITPOS', @_);
}


async sub blmove {
    my $self = shift;
    return await $self->command('BLMOVE', @_);
}


async sub blmpop {
    my $self = shift;
    return await $self->command('BLMPOP', @_);
}


async sub blpop {
    my $self = shift;
    return await $self->command('BLPOP', @_);
}


async sub brpop {
    my $self = shift;
    return await $self->command('BRPOP', @_);
}


async sub brpoplpush {
    my $self = shift;
    return await $self->command('BRPOPLPUSH', @_);
}


async sub bzmpop {
    my $self = shift;
    return await $self->command('BZMPOP', @_);
}


async sub bzpopmax {
    my $self = shift;
    return await $self->command('BZPOPMAX', @_);
}


async sub bzpopmin {
    my $self = shift;
    return await $self->command('BZPOPMIN', @_);
}


async sub client {
    my $self = shift;
    return await $self->command('CLIENT', @_);
}


async sub client_caching {
    my $self = shift;
    return await $self->command('CLIENT', 'CACHING', @_);
}


async sub client_getname {
    my $self = shift;
    return await $self->command('CLIENT', 'GETNAME', @_);
}


async sub client_getredir {
    my $self = shift;
    return await $self->command('CLIENT', 'GETREDIR', @_);
}


async sub client_help {
    my $self = shift;
    return await $self->command('CLIENT', 'HELP', @_);
}


async sub client_id {
    my $self = shift;
    return await $self->command('CLIENT', 'ID', @_);
}


async sub client_info {
    my $self = shift;
    return await $self->command('CLIENT', 'INFO', @_);
}


async sub client_kill {
    my $self = shift;
    return await $self->command('CLIENT', 'KILL', @_);
}


async sub client_list {
    my $self = shift;
    return await $self->command('CLIENT', 'LIST', @_);
}


async sub client_no_evict {
    my $self = shift;
    return await $self->command('CLIENT', 'NO-EVICT', @_);
}


async sub client_no_touch {
    my $self = shift;
    return await $self->command('CLIENT', 'NO-TOUCH', @_);
}


async sub client_pause {
    my $self = shift;
    return await $self->command('CLIENT', 'PAUSE', @_);
}


async sub client_reply {
    my $self = shift;
    return await $self->command('CLIENT', 'REPLY', @_);
}


async sub client_setinfo {
    my $self = shift;
    return await $self->command('CLIENT', 'SETINFO', @_);
}


async sub client_setname {
    my $self = shift;
    return await $self->command('CLIENT', 'SETNAME', @_);
}


async sub client_tracking {
    my $self = shift;
    return await $self->command('CLIENT', 'TRACKING', @_);
}


async sub client_trackinginfo {
    my $self = shift;
    return await $self->command('CLIENT', 'TRACKINGINFO', @_);
}


async sub client_unblock {
    my $self = shift;
    return await $self->command('CLIENT', 'UNBLOCK', @_);
}


async sub client_unpause {
    my $self = shift;
    return await $self->command('CLIENT', 'UNPAUSE', @_);
}


async sub cluster {
    my $self = shift;
    return await $self->command('CLUSTER', @_);
}


async sub cluster_addslots {
    my $self = shift;
    return await $self->command('CLUSTER', 'ADDSLOTS', @_);
}


async sub cluster_addslotsrange {
    my $self = shift;
    return await $self->command('CLUSTER', 'ADDSLOTSRANGE', @_);
}


async sub cluster_bumpepoch {
    my $self = shift;
    return await $self->command('CLUSTER', 'BUMPEPOCH', @_);
}


async sub cluster_count_failure_reports {
    my $self = shift;
    return await $self->command('CLUSTER', 'COUNT-FAILURE-REPORTS', @_);
}


async sub cluster_countkeysinslot {
    my $self = shift;
    return await $self->command('CLUSTER', 'COUNTKEYSINSLOT', @_);
}


async sub cluster_delslots {
    my $self = shift;
    return await $self->command('CLUSTER', 'DELSLOTS', @_);
}


async sub cluster_delslotsrange {
    my $self = shift;
    return await $self->command('CLUSTER', 'DELSLOTSRANGE', @_);
}


async sub cluster_failover {
    my $self = shift;
    return await $self->command('CLUSTER', 'FAILOVER', @_);
}


async sub cluster_flushslots {
    my $self = shift;
    return await $self->command('CLUSTER', 'FLUSHSLOTS', @_);
}


async sub cluster_forget {
    my $self = shift;
    return await $self->command('CLUSTER', 'FORGET', @_);
}


async sub cluster_getkeysinslot {
    my $self = shift;
    return await $self->command('CLUSTER', 'GETKEYSINSLOT', @_);
}


async sub cluster_help {
    my $self = shift;
    return await $self->command('CLUSTER', 'HELP', @_);
}


async sub cluster_info {
    my $self = shift;
    return await $self->command('CLUSTER', 'INFO', @_);
}


async sub cluster_keyslot {
    my $self = shift;
    return await $self->command('CLUSTER', 'KEYSLOT', @_);
}


async sub cluster_links {
    my $self = shift;
    return await $self->command('CLUSTER', 'LINKS', @_);
}


async sub cluster_meet {
    my $self = shift;
    return await $self->command('CLUSTER', 'MEET', @_);
}


async sub cluster_myid {
    my $self = shift;
    return await $self->command('CLUSTER', 'MYID', @_);
}


async sub cluster_myshardid {
    my $self = shift;
    return await $self->command('CLUSTER', 'MYSHARDID', @_);
}


async sub cluster_nodes {
    my $self = shift;
    return await $self->command('CLUSTER', 'NODES', @_);
}


async sub cluster_replicas {
    my $self = shift;
    return await $self->command('CLUSTER', 'REPLICAS', @_);
}


async sub cluster_replicate {
    my $self = shift;
    return await $self->command('CLUSTER', 'REPLICATE', @_);
}


async sub cluster_reset {
    my $self = shift;
    return await $self->command('CLUSTER', 'RESET', @_);
}


async sub cluster_saveconfig {
    my $self = shift;
    return await $self->command('CLUSTER', 'SAVECONFIG', @_);
}


async sub cluster_set_config_epoch {
    my $self = shift;
    return await $self->command('CLUSTER', 'SET-CONFIG-EPOCH', @_);
}


async sub cluster_setslot {
    my $self = shift;
    return await $self->command('CLUSTER', 'SETSLOT', @_);
}


async sub cluster_shards {
    my $self = shift;
    return await $self->command('CLUSTER', 'SHARDS', @_);
}


async sub cluster_slaves {
    my $self = shift;
    return await $self->command('CLUSTER', 'SLAVES', @_);
}


async sub cluster_slots {
    my $self = shift;
    return await $self->command('CLUSTER', 'SLOTS', @_);
}


async sub command {
    my $self = shift;
    return await $self->command('COMMAND', @_);
}


async sub command_count {
    my $self = shift;
    return await $self->command('COMMAND', 'COUNT', @_);
}


async sub command_docs {
    my $self = shift;
    return await $self->command('COMMAND', 'DOCS', @_);
}


async sub command_getkeys {
    my $self = shift;
    return await $self->command('COMMAND', 'GETKEYS', @_);
}


async sub command_getkeysandflags {
    my $self = shift;
    return await $self->command('COMMAND', 'GETKEYSANDFLAGS', @_);
}


async sub command_help {
    my $self = shift;
    return await $self->command('COMMAND', 'HELP', @_);
}


async sub command_info {
    my $self = shift;
    return await $self->command('COMMAND', 'INFO', @_);
}


async sub command_list {
    my $self = shift;
    return await $self->command('COMMAND', 'LIST', @_);
}


async sub config {
    my $self = shift;
    return await $self->command('CONFIG', @_);
}


async sub config_get {
    my $self = shift;
    return await $self->command('CONFIG', 'GET', @_);
}


async sub config_help {
    my $self = shift;
    return await $self->command('CONFIG', 'HELP', @_);
}


async sub config_resetstat {
    my $self = shift;
    return await $self->command('CONFIG', 'RESETSTAT', @_);
}


async sub config_rewrite {
    my $self = shift;
    return await $self->command('CONFIG', 'REWRITE', @_);
}


async sub config_set {
    my $self = shift;
    return await $self->command('CONFIG', 'SET', @_);
}


async sub copy {
    my $self = shift;
    return await $self->command('COPY', @_);
}


async sub dbsize {
    my $self = shift;
    return await $self->command('DBSIZE', @_);
}


async sub debug {
    my $self = shift;
    return await $self->command('DEBUG', @_);
}


async sub decr {
    my $self = shift;
    return await $self->command('DECR', @_);
}


async sub decrby {
    my $self = shift;
    return await $self->command('DECRBY', @_);
}


async sub del {
    my $self = shift;
    return await $self->command('DEL', @_);
}


async sub discard {
    my $self = shift;
    return await $self->command('DISCARD', @_);
}


async sub dump {
    my $self = shift;
    return await $self->command('DUMP', @_);
}


async sub echo {
    my $self = shift;
    return await $self->command('ECHO', @_);
}


async sub eval {
    my $self = shift;
    return await $self->command('EVAL', @_);
}


async sub evalsha {
    my $self = shift;
    return await $self->command('EVALSHA', @_);
}


async sub evalsha_ro {
    my $self = shift;
    return await $self->command('EVALSHA_RO', @_);
}


async sub eval_ro {
    my $self = shift;
    return await $self->command('EVAL_RO', @_);
}


async sub exec {
    my $self = shift;
    return await $self->command('EXEC', @_);
}


async sub exists {
    my $self = shift;
    return await $self->command('EXISTS', @_);
}


async sub expire {
    my $self = shift;
    return await $self->command('EXPIRE', @_);
}


async sub expireat {
    my $self = shift;
    return await $self->command('EXPIREAT', @_);
}


async sub expiretime {
    my $self = shift;
    return await $self->command('EXPIRETIME', @_);
}


async sub failover {
    my $self = shift;
    return await $self->command('FAILOVER', @_);
}


async sub fcall {
    my $self = shift;
    return await $self->command('FCALL', @_);
}


async sub fcall_ro {
    my $self = shift;
    return await $self->command('FCALL_RO', @_);
}


async sub flushall {
    my $self = shift;
    return await $self->command('FLUSHALL', @_);
}


async sub flushdb {
    my $self = shift;
    return await $self->command('FLUSHDB', @_);
}


async sub function {
    my $self = shift;
    return await $self->command('FUNCTION', @_);
}


async sub function_delete {
    my $self = shift;
    return await $self->command('FUNCTION', 'DELETE', @_);
}


async sub function_dump {
    my $self = shift;
    return await $self->command('FUNCTION', 'DUMP', @_);
}


async sub function_flush {
    my $self = shift;
    return await $self->command('FUNCTION', 'FLUSH', @_);
}


async sub function_help {
    my $self = shift;
    return await $self->command('FUNCTION', 'HELP', @_);
}


async sub function_kill {
    my $self = shift;
    return await $self->command('FUNCTION', 'KILL', @_);
}


async sub function_list {
    my $self = shift;
    return await $self->command('FUNCTION', 'LIST', @_);
}


async sub function_load {
    my $self = shift;
    return await $self->command('FUNCTION', 'LOAD', @_);
}


async sub function_restore {
    my $self = shift;
    return await $self->command('FUNCTION', 'RESTORE', @_);
}


async sub function_stats {
    my $self = shift;
    return await $self->command('FUNCTION', 'STATS', @_);
}


async sub geoadd {
    my $self = shift;
    return await $self->command('GEOADD', @_);
}


async sub geodist {
    my $self = shift;
    return await $self->command('GEODIST', @_);
}


async sub geohash {
    my $self = shift;
    return await $self->command('GEOHASH', @_);
}


async sub geopos {
    my $self = shift;
    return await $self->command('GEOPOS', @_);
}


async sub georadius {
    my $self = shift;
    return await $self->command('GEORADIUS', @_);
}


async sub georadiusbymember {
    my $self = shift;
    return await $self->command('GEORADIUSBYMEMBER', @_);
}


async sub georadiusbymember_ro {
    my $self = shift;
    return await $self->command('GEORADIUSBYMEMBER_RO', @_);
}


async sub georadius_ro {
    my $self = shift;
    return await $self->command('GEORADIUS_RO', @_);
}


async sub geosearch {
    my $self = shift;
    return await $self->command('GEOSEARCH', @_);
}


async sub geosearchstore {
    my $self = shift;
    return await $self->command('GEOSEARCHSTORE', @_);
}


async sub get {
    my $self = shift;
    return await $self->command('GET', @_);
}


async sub getbit {
    my $self = shift;
    return await $self->command('GETBIT', @_);
}


async sub getdel {
    my $self = shift;
    return await $self->command('GETDEL', @_);
}


async sub getex {
    my $self = shift;
    return await $self->command('GETEX', @_);
}


async sub getrange {
    my $self = shift;
    return await $self->command('GETRANGE', @_);
}


async sub getset {
    my $self = shift;
    return await $self->command('GETSET', @_);
}


async sub hdel {
    my $self = shift;
    return await $self->command('HDEL', @_);
}


async sub hello {
    my $self = shift;
    return await $self->command('HELLO', @_);
}


async sub hexists {
    my $self = shift;
    return await $self->command('HEXISTS', @_);
}


async sub hget {
    my $self = shift;
    return await $self->command('HGET', @_);
}


async sub hgetall {
    my $self = shift;
    my $arr = await $self->command('HGETALL', @_);
    return {} unless $arr && ref($arr) eq 'ARRAY' && @$arr && @$arr % 2 == 0;
    return { @$arr };  # Convert array to hash
}


async sub hincrby {
    my $self = shift;
    return await $self->command('HINCRBY', @_);
}


async sub hincrbyfloat {
    my $self = shift;
    return await $self->command('HINCRBYFLOAT', @_);
}


async sub hkeys {
    my $self = shift;
    return await $self->command('HKEYS', @_);
}


async sub hlen {
    my $self = shift;
    return await $self->command('HLEN', @_);
}


async sub hmget {
    my $self = shift;
    return await $self->command('HMGET', @_);
}


async sub hmset {
    my $self = shift;
    return await $self->command('HMSET', @_);
}


async sub hrandfield {
    my $self = shift;
    return await $self->command('HRANDFIELD', @_);
}


async sub hscan {
    my $self = shift;
    return await $self->command('HSCAN', @_);
}


async sub hset {
    my $self = shift;
    return await $self->command('HSET', @_);
}


async sub hsetnx {
    my $self = shift;
    return await $self->command('HSETNX', @_);
}


async sub hstrlen {
    my $self = shift;
    return await $self->command('HSTRLEN', @_);
}


async sub hvals {
    my $self = shift;
    return await $self->command('HVALS', @_);
}


async sub incr {
    my $self = shift;
    return await $self->command('INCR', @_);
}


async sub incrby {
    my $self = shift;
    return await $self->command('INCRBY', @_);
}


async sub incrbyfloat {
    my $self = shift;
    return await $self->command('INCRBYFLOAT', @_);
}


async sub info {
    my $self = shift;
    my $raw = await $self->command('INFO', @_);
    return _parse_info($raw);
}

sub _parse_info {
    my ($raw) = @_;
    return {} unless defined $raw;

    my %info;
    my $section = 'default';

    for my $line (split /\r?\n/, $raw) {
        if ($line =~ /^# (\w+)/) {
            $section = lc($1);
            $info{$section} //= {};
        }
        elsif ($line =~ /^(\w+):(.*)$/) {
            $info{$section}{$1} = $2;
        }
    }

    return \%info;
}


async sub keys {
    my $self = shift;
    return await $self->command('KEYS', @_);
}


async sub lastsave {
    my $self = shift;
    return await $self->command('LASTSAVE', @_);
}


async sub latency {
    my $self = shift;
    return await $self->command('LATENCY', @_);
}


async sub latency_doctor {
    my $self = shift;
    return await $self->command('LATENCY', 'DOCTOR', @_);
}


async sub latency_graph {
    my $self = shift;
    return await $self->command('LATENCY', 'GRAPH', @_);
}


async sub latency_help {
    my $self = shift;
    return await $self->command('LATENCY', 'HELP', @_);
}


async sub latency_histogram {
    my $self = shift;
    return await $self->command('LATENCY', 'HISTOGRAM', @_);
}


async sub latency_history {
    my $self = shift;
    return await $self->command('LATENCY', 'HISTORY', @_);
}


async sub latency_latest {
    my $self = shift;
    return await $self->command('LATENCY', 'LATEST', @_);
}


async sub latency_reset {
    my $self = shift;
    return await $self->command('LATENCY', 'RESET', @_);
}


async sub lcs {
    my $self = shift;
    return await $self->command('LCS', @_);
}


async sub lindex {
    my $self = shift;
    return await $self->command('LINDEX', @_);
}


async sub linsert {
    my $self = shift;
    return await $self->command('LINSERT', @_);
}


async sub llen {
    my $self = shift;
    return await $self->command('LLEN', @_);
}


async sub lmove {
    my $self = shift;
    return await $self->command('LMOVE', @_);
}


async sub lmpop {
    my $self = shift;
    return await $self->command('LMPOP', @_);
}


async sub lolwut {
    my $self = shift;
    return await $self->command('LOLWUT', @_);
}


async sub lpop {
    my $self = shift;
    return await $self->command('LPOP', @_);
}


async sub lpos {
    my $self = shift;
    return await $self->command('LPOS', @_);
}


async sub lpush {
    my $self = shift;
    return await $self->command('LPUSH', @_);
}


async sub lpushx {
    my $self = shift;
    return await $self->command('LPUSHX', @_);
}


async sub lrange {
    my $self = shift;
    return await $self->command('LRANGE', @_);
}


async sub lrem {
    my $self = shift;
    return await $self->command('LREM', @_);
}


async sub lset {
    my $self = shift;
    return await $self->command('LSET', @_);
}


async sub ltrim {
    my $self = shift;
    return await $self->command('LTRIM', @_);
}


async sub memory {
    my $self = shift;
    return await $self->command('MEMORY', @_);
}


async sub memory_doctor {
    my $self = shift;
    return await $self->command('MEMORY', 'DOCTOR', @_);
}


async sub memory_help {
    my $self = shift;
    return await $self->command('MEMORY', 'HELP', @_);
}


async sub memory_malloc_stats {
    my $self = shift;
    return await $self->command('MEMORY', 'MALLOC-STATS', @_);
}


async sub memory_purge {
    my $self = shift;
    return await $self->command('MEMORY', 'PURGE', @_);
}


async sub memory_stats {
    my $self = shift;
    return await $self->command('MEMORY', 'STATS', @_);
}


async sub memory_usage {
    my $self = shift;
    return await $self->command('MEMORY', 'USAGE', @_);
}


async sub mget {
    my $self = shift;
    return await $self->command('MGET', @_);
}


async sub migrate {
    my $self = shift;
    return await $self->command('MIGRATE', @_);
}


async sub module {
    my $self = shift;
    return await $self->command('MODULE', @_);
}


async sub module_help {
    my $self = shift;
    return await $self->command('MODULE', 'HELP', @_);
}


async sub module_list {
    my $self = shift;
    return await $self->command('MODULE', 'LIST', @_);
}


async sub module_load {
    my $self = shift;
    return await $self->command('MODULE', 'LOAD', @_);
}


async sub module_loadex {
    my $self = shift;
    return await $self->command('MODULE', 'LOADEX', @_);
}


async sub module_unload {
    my $self = shift;
    return await $self->command('MODULE', 'UNLOAD', @_);
}


async sub monitor {
    my $self = shift;
    return await $self->command('MONITOR', @_);
}


async sub move {
    my $self = shift;
    return await $self->command('MOVE', @_);
}


async sub mset {
    my $self = shift;
    return await $self->command('MSET', @_);
}


async sub msetnx {
    my $self = shift;
    return await $self->command('MSETNX', @_);
}


async sub multi {
    my $self = shift;
    return await $self->command('MULTI', @_);
}


async sub object {
    my $self = shift;
    return await $self->command('OBJECT', @_);
}


async sub object_encoding {
    my $self = shift;
    return await $self->command('OBJECT', 'ENCODING', @_);
}


async sub object_freq {
    my $self = shift;
    return await $self->command('OBJECT', 'FREQ', @_);
}


async sub object_help {
    my $self = shift;
    return await $self->command('OBJECT', 'HELP', @_);
}


async sub object_idletime {
    my $self = shift;
    return await $self->command('OBJECT', 'IDLETIME', @_);
}


async sub object_refcount {
    my $self = shift;
    return await $self->command('OBJECT', 'REFCOUNT', @_);
}


async sub persist {
    my $self = shift;
    return await $self->command('PERSIST', @_);
}


async sub pexpire {
    my $self = shift;
    return await $self->command('PEXPIRE', @_);
}


async sub pexpireat {
    my $self = shift;
    return await $self->command('PEXPIREAT', @_);
}


async sub pexpiretime {
    my $self = shift;
    return await $self->command('PEXPIRETIME', @_);
}


async sub pfadd {
    my $self = shift;
    return await $self->command('PFADD', @_);
}


async sub pfcount {
    my $self = shift;
    return await $self->command('PFCOUNT', @_);
}


async sub pfdebug {
    my $self = shift;
    return await $self->command('PFDEBUG', @_);
}


async sub pfmerge {
    my $self = shift;
    return await $self->command('PFMERGE', @_);
}


async sub pfselftest {
    my $self = shift;
    return await $self->command('PFSELFTEST', @_);
}


async sub ping {
    my $self = shift;
    return await $self->command('PING', @_);
}


async sub psetex {
    my $self = shift;
    return await $self->command('PSETEX', @_);
}


async sub psubscribe {
    my $self = shift;
    return await $self->command('PSUBSCRIBE', @_);
}


async sub psync {
    my $self = shift;
    return await $self->command('PSYNC', @_);
}


async sub pttl {
    my $self = shift;
    return await $self->command('PTTL', @_);
}


async sub publish {
    my $self = shift;
    return await $self->command('PUBLISH', @_);
}


async sub pubsub {
    my $self = shift;
    return await $self->command('PUBSUB', @_);
}


async sub pubsub_channels {
    my $self = shift;
    return await $self->command('PUBSUB', 'CHANNELS', @_);
}


async sub pubsub_help {
    my $self = shift;
    return await $self->command('PUBSUB', 'HELP', @_);
}


async sub pubsub_numpat {
    my $self = shift;
    return await $self->command('PUBSUB', 'NUMPAT', @_);
}


async sub pubsub_numsub {
    my $self = shift;
    return await $self->command('PUBSUB', 'NUMSUB', @_);
}


async sub pubsub_shardchannels {
    my $self = shift;
    return await $self->command('PUBSUB', 'SHARDCHANNELS', @_);
}


async sub pubsub_shardnumsub {
    my $self = shift;
    return await $self->command('PUBSUB', 'SHARDNUMSUB', @_);
}


async sub punsubscribe {
    my $self = shift;
    return await $self->command('PUNSUBSCRIBE', @_);
}


async sub quit {
    my $self = shift;
    return await $self->command('QUIT', @_);
}


async sub randomkey {
    my $self = shift;
    return await $self->command('RANDOMKEY', @_);
}


async sub readonly {
    my $self = shift;
    return await $self->command('READONLY', @_);
}


async sub readwrite {
    my $self = shift;
    return await $self->command('READWRITE', @_);
}


async sub rename {
    my $self = shift;
    return await $self->command('RENAME', @_);
}


async sub renamenx {
    my $self = shift;
    return await $self->command('RENAMENX', @_);
}


async sub replconf {
    my $self = shift;
    return await $self->command('REPLCONF', @_);
}


async sub replicaof {
    my $self = shift;
    return await $self->command('REPLICAOF', @_);
}


async sub reset {
    my $self = shift;
    return await $self->command('RESET', @_);
}


async sub restore {
    my $self = shift;
    return await $self->command('RESTORE', @_);
}


async sub restore_asking {
    my $self = shift;
    return await $self->command('RESTORE-ASKING', @_);
}


async sub role {
    my $self = shift;
    return await $self->command('ROLE', @_);
}


async sub rpop {
    my $self = shift;
    return await $self->command('RPOP', @_);
}


async sub rpoplpush {
    my $self = shift;
    return await $self->command('RPOPLPUSH', @_);
}


async sub rpush {
    my $self = shift;
    return await $self->command('RPUSH', @_);
}


async sub rpushx {
    my $self = shift;
    return await $self->command('RPUSHX', @_);
}


async sub sadd {
    my $self = shift;
    return await $self->command('SADD', @_);
}


async sub save {
    my $self = shift;
    return await $self->command('SAVE', @_);
}


async sub scan {
    my $self = shift;
    return await $self->command('SCAN', @_);
}


async sub scard {
    my $self = shift;
    return await $self->command('SCARD', @_);
}


async sub script {
    my $self = shift;
    return await $self->command('SCRIPT', @_);
}


async sub script_debug {
    my $self = shift;
    return await $self->command('SCRIPT', 'DEBUG', @_);
}


async sub script_exists {
    my $self = shift;
    return await $self->command('SCRIPT', 'EXISTS', @_);
}


async sub script_flush {
    my $self = shift;
    return await $self->command('SCRIPT', 'FLUSH', @_);
}


async sub script_help {
    my $self = shift;
    return await $self->command('SCRIPT', 'HELP', @_);
}


async sub script_kill {
    my $self = shift;
    return await $self->command('SCRIPT', 'KILL', @_);
}


async sub script_load {
    my $self = shift;
    return await $self->command('SCRIPT', 'LOAD', @_);
}


async sub sdiff {
    my $self = shift;
    return await $self->command('SDIFF', @_);
}


async sub sdiffstore {
    my $self = shift;
    return await $self->command('SDIFFSTORE', @_);
}


async sub select {
    my $self = shift;
    return await $self->command('SELECT', @_);
}


async sub set {
    my $self = shift;
    return await $self->command('SET', @_);
}


async sub setbit {
    my $self = shift;
    return await $self->command('SETBIT', @_);
}


async sub setex {
    my $self = shift;
    return await $self->command('SETEX', @_);
}


async sub setnx {
    my $self = shift;
    return await $self->command('SETNX', @_);
}


async sub setrange {
    my $self = shift;
    return await $self->command('SETRANGE', @_);
}


async sub shutdown {
    my $self = shift;
    return await $self->command('SHUTDOWN', @_);
}


async sub sinter {
    my $self = shift;
    return await $self->command('SINTER', @_);
}


async sub sintercard {
    my $self = shift;
    return await $self->command('SINTERCARD', @_);
}


async sub sinterstore {
    my $self = shift;
    return await $self->command('SINTERSTORE', @_);
}


async sub sismember {
    my $self = shift;
    return await $self->command('SISMEMBER', @_);
}


async sub slaveof {
    my $self = shift;
    return await $self->command('SLAVEOF', @_);
}


async sub slowlog {
    my $self = shift;
    return await $self->command('SLOWLOG', @_);
}


async sub slowlog_get {
    my $self = shift;
    return await $self->command('SLOWLOG', 'GET', @_);
}


async sub slowlog_help {
    my $self = shift;
    return await $self->command('SLOWLOG', 'HELP', @_);
}


async sub slowlog_len {
    my $self = shift;
    return await $self->command('SLOWLOG', 'LEN', @_);
}


async sub slowlog_reset {
    my $self = shift;
    return await $self->command('SLOWLOG', 'RESET', @_);
}


async sub smembers {
    my $self = shift;
    return await $self->command('SMEMBERS', @_);
}


async sub smismember {
    my $self = shift;
    return await $self->command('SMISMEMBER', @_);
}


async sub smove {
    my $self = shift;
    return await $self->command('SMOVE', @_);
}


async sub sort {
    my $self = shift;
    return await $self->command('SORT', @_);
}


async sub sort_ro {
    my $self = shift;
    return await $self->command('SORT_RO', @_);
}


async sub spop {
    my $self = shift;
    return await $self->command('SPOP', @_);
}


async sub spublish {
    my $self = shift;
    return await $self->command('SPUBLISH', @_);
}


async sub srandmember {
    my $self = shift;
    return await $self->command('SRANDMEMBER', @_);
}


async sub srem {
    my $self = shift;
    return await $self->command('SREM', @_);
}


async sub sscan {
    my $self = shift;
    return await $self->command('SSCAN', @_);
}


async sub ssubscribe {
    my $self = shift;
    return await $self->command('SSUBSCRIBE', @_);
}


async sub strlen {
    my $self = shift;
    return await $self->command('STRLEN', @_);
}


async sub subscribe {
    my $self = shift;
    return await $self->command('SUBSCRIBE', @_);
}


async sub substr {
    my $self = shift;
    return await $self->command('SUBSTR', @_);
}


async sub sunion {
    my $self = shift;
    return await $self->command('SUNION', @_);
}


async sub sunionstore {
    my $self = shift;
    return await $self->command('SUNIONSTORE', @_);
}


async sub sunsubscribe {
    my $self = shift;
    return await $self->command('SUNSUBSCRIBE', @_);
}


async sub swapdb {
    my $self = shift;
    return await $self->command('SWAPDB', @_);
}


async sub sync {
    my $self = shift;
    return await $self->command('SYNC', @_);
}


async sub time {
    my $self = shift;
    my $arr = await $self->command('TIME', @_);
    return {
        seconds      => $arr->[0],
        microseconds => $arr->[1],
    };
}


async sub touch {
    my $self = shift;
    return await $self->command('TOUCH', @_);
}


async sub ttl {
    my $self = shift;
    return await $self->command('TTL', @_);
}


async sub type {
    my $self = shift;
    return await $self->command('TYPE', @_);
}


async sub unlink {
    my $self = shift;
    return await $self->command('UNLINK', @_);
}


async sub unsubscribe {
    my $self = shift;
    return await $self->command('UNSUBSCRIBE', @_);
}


async sub unwatch {
    my $self = shift;
    return await $self->command('UNWATCH', @_);
}


async sub wait {
    my $self = shift;
    return await $self->command('WAIT', @_);
}


async sub waitaof {
    my $self = shift;
    return await $self->command('WAITAOF', @_);
}


async sub watch {
    my $self = shift;
    return await $self->command('WATCH', @_);
}


async sub xack {
    my $self = shift;
    return await $self->command('XACK', @_);
}


async sub xadd {
    my $self = shift;
    return await $self->command('XADD', @_);
}


async sub xautoclaim {
    my $self = shift;
    return await $self->command('XAUTOCLAIM', @_);
}


async sub xclaim {
    my $self = shift;
    return await $self->command('XCLAIM', @_);
}


async sub xdel {
    my $self = shift;
    return await $self->command('XDEL', @_);
}


async sub xgroup {
    my $self = shift;
    return await $self->command('XGROUP', @_);
}


async sub xgroup_create {
    my $self = shift;
    return await $self->command('XGROUP', 'CREATE', @_);
}


async sub xgroup_createconsumer {
    my $self = shift;
    return await $self->command('XGROUP', 'CREATECONSUMER', @_);
}


async sub xgroup_delconsumer {
    my $self = shift;
    return await $self->command('XGROUP', 'DELCONSUMER', @_);
}


async sub xgroup_destroy {
    my $self = shift;
    return await $self->command('XGROUP', 'DESTROY', @_);
}


async sub xgroup_help {
    my $self = shift;
    return await $self->command('XGROUP', 'HELP', @_);
}


async sub xgroup_setid {
    my $self = shift;
    return await $self->command('XGROUP', 'SETID', @_);
}


async sub xinfo {
    my $self = shift;
    return await $self->command('XINFO', @_);
}


async sub xinfo_consumers {
    my $self = shift;
    return await $self->command('XINFO', 'CONSUMERS', @_);
}


async sub xinfo_groups {
    my $self = shift;
    return await $self->command('XINFO', 'GROUPS', @_);
}


async sub xinfo_help {
    my $self = shift;
    return await $self->command('XINFO', 'HELP', @_);
}


async sub xinfo_stream {
    my $self = shift;
    return await $self->command('XINFO', 'STREAM', @_);
}


async sub xlen {
    my $self = shift;
    return await $self->command('XLEN', @_);
}


async sub xpending {
    my $self = shift;
    return await $self->command('XPENDING', @_);
}


async sub xrange {
    my $self = shift;
    return await $self->command('XRANGE', @_);
}


async sub xread {
    my $self = shift;
    return await $self->command('XREAD', @_);
}


async sub xreadgroup {
    my $self = shift;
    return await $self->command('XREADGROUP', @_);
}


async sub xrevrange {
    my $self = shift;
    return await $self->command('XREVRANGE', @_);
}


async sub xsetid {
    my $self = shift;
    return await $self->command('XSETID', @_);
}


async sub xtrim {
    my $self = shift;
    return await $self->command('XTRIM', @_);
}


async sub zadd {
    my $self = shift;
    return await $self->command('ZADD', @_);
}


async sub zcard {
    my $self = shift;
    return await $self->command('ZCARD', @_);
}


async sub zcount {
    my $self = shift;
    return await $self->command('ZCOUNT', @_);
}


async sub zdiff {
    my $self = shift;
    return await $self->command('ZDIFF', @_);
}


async sub zdiffstore {
    my $self = shift;
    return await $self->command('ZDIFFSTORE', @_);
}


async sub zincrby {
    my $self = shift;
    return await $self->command('ZINCRBY', @_);
}


async sub zinter {
    my $self = shift;
    return await $self->command('ZINTER', @_);
}


async sub zintercard {
    my $self = shift;
    return await $self->command('ZINTERCARD', @_);
}


async sub zinterstore {
    my $self = shift;
    return await $self->command('ZINTERSTORE', @_);
}


async sub zlexcount {
    my $self = shift;
    return await $self->command('ZLEXCOUNT', @_);
}


async sub zmpop {
    my $self = shift;
    return await $self->command('ZMPOP', @_);
}


async sub zmscore {
    my $self = shift;
    return await $self->command('ZMSCORE', @_);
}


async sub zpopmax {
    my $self = shift;
    return await $self->command('ZPOPMAX', @_);
}


async sub zpopmin {
    my $self = shift;
    return await $self->command('ZPOPMIN', @_);
}


async sub zrandmember {
    my $self = shift;
    return await $self->command('ZRANDMEMBER', @_);
}


async sub zrange {
    my $self = shift;
    return await $self->command('ZRANGE', @_);
}


async sub zrangebylex {
    my $self = shift;
    return await $self->command('ZRANGEBYLEX', @_);
}


async sub zrangebyscore {
    my $self = shift;
    return await $self->command('ZRANGEBYSCORE', @_);
}


async sub zrangestore {
    my $self = shift;
    return await $self->command('ZRANGESTORE', @_);
}


async sub zrank {
    my $self = shift;
    return await $self->command('ZRANK', @_);
}


async sub zrem {
    my $self = shift;
    return await $self->command('ZREM', @_);
}


async sub zremrangebylex {
    my $self = shift;
    return await $self->command('ZREMRANGEBYLEX', @_);
}


async sub zremrangebyrank {
    my $self = shift;
    return await $self->command('ZREMRANGEBYRANK', @_);
}


async sub zremrangebyscore {
    my $self = shift;
    return await $self->command('ZREMRANGEBYSCORE', @_);
}


async sub zrevrange {
    my $self = shift;
    return await $self->command('ZREVRANGE', @_);
}


async sub zrevrangebylex {
    my $self = shift;
    return await $self->command('ZREVRANGEBYLEX', @_);
}


async sub zrevrangebyscore {
    my $self = shift;
    return await $self->command('ZREVRANGEBYSCORE', @_);
}


async sub zrevrank {
    my $self = shift;
    return await $self->command('ZREVRANK', @_);
}


async sub zscan {
    my $self = shift;
    return await $self->command('ZSCAN', @_);
}


async sub zscore {
    my $self = shift;
    return await $self->command('ZSCORE', @_);
}


async sub zunion {
    my $self = shift;
    return await $self->command('ZUNION', @_);
}


async sub zunionstore {
    my $self = shift;
    return await $self->command('ZUNIONSTORE', @_);
}


1;

__END__

=head1 NAME

Async::Redis::Commands - Auto-generated Redis command methods

=head1 DESCRIPTION

This module is auto-generated from the Redis command documentation.
It provides async method wrappers for all Redis commands.

Do not edit this file directly. Regenerate with:

  perl bin/generate-commands

=cut
