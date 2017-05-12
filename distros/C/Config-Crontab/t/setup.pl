use strict;
use warnings;

sub have_crontab {
    eval 'system("crontab -l 2>/dev/null")';
    return ($? >> 8 == 1);
}

1;
