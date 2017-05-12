package App::CmdDirs::Traverser::Subversion;
use base 'App::CmdDirs::Traverser::Base';
use strict;
use warnings;

# Return false if the passed directory does not have a .svn subdirectory
sub test {
    my ($self, $dir) = @_;

    return (-d "$dir/.svn");
}

1;
