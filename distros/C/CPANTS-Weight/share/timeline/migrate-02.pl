use strict;
use ORLite::Migrate::Patch;

# Create the META.yml columns
do('alter table dist_weight add column meta1 integer not null default 0');
do('alter table dist_weight add column meta2 integer not null default 0');
do('alter table dist_weight add column meta3 integer not null default 0');
