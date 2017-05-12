use strict;
use Sys::Filesystem ();
    
# Method 1
    my $fs = new Sys::Filesystem;
    my @filesystems = $fs->filesystems();
    for (@filesystems) {
        printf("%s is a %s filesystem mounted on %s\n",
                          $fs->mount_point($_),
                          $fs->format($_),
                          $fs->device($_)
               );
    }

