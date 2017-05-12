#!/usr/bin/perl -l
$ARGV[0] ||= "$ENV{HOME}/Code/redis/src/redis.c";
1 until <> =~ /^struct redisCommand .*\[\] = \{/;
print $1 while <> =~ /\{"(\w+)"/;
