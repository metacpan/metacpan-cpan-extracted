package Data::RecordStore::PopSilo;

#
# I am a really simple silo. I live in a directory
# and have a single file that I work on.
#
# I may be changed by async processes, so a lot
# of my coordination and state is on the file system.
#
# You can init me by giving me a directory, a template and/or a size
#   I will figure out the record size based on what you give me
#   I will 
#
# You can open me by giving a directory, then
#   push data to me and I return its id
#   get data from me after giving me its id
#   pop data from me
#   ask how many records I have
#

use strict;
use warnings;

use Fcntl qw( :flock SEEK_SET );
use File::Path qw(make_path remove_tree);
