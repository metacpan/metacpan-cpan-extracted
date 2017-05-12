use strict;
use ORLite::Migrate::Patch;

# Create the author_weight table
do(<<'END_SQL');
create table author_weight (
	id         integer      not null primary key,
	pauseid    varchar(255) not null unique
)
END_SQL

# Create the dist_weight table
do(<<'END_SQL');
create table dist_weight (
	id               integer      not null primary key,
	dist             varchar(255) not null unique,
	author           integer      not null,
	weight           integer          null,
	volatility       integer          null,
	enemy_downstream integer      not null,
	debian_candidate integer      not null
)
END_SQL
