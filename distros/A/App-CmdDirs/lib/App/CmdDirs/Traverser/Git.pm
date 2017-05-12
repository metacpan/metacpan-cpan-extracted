package App::CmdDirs::Traverser::Git;
use base 'App::CmdDirs::Traverser::Base';
use strict;
use warnings;

# Return false if the passed directory does not have a .git subdirectory
sub test {
    my ($self, $dir) = @_;

    return (-d "$dir/.git");
}

1;
