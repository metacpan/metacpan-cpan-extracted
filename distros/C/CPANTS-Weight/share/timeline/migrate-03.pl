use strict;
use ORLite::Migrate::Patch;

# Create the META.yml columns
do('alter table dist_weight add column fails integer not null default 0');
