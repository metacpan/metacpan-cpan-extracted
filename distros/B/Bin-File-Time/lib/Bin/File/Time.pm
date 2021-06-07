package Bin::File::Time ; 

our $VERSION = "0.210" ; 
our $DATE = "2021-05-29T01:30+09:00" ; 

=encoding utf8

=head1 NAME

Bin::File::Time

=head1 SYNOPSIS

This module "Bin::File::Time" provides scripts for specific functionalities that deals about time information about files.

=head1 DESCRIPTION

The included commands are as follows.

(1) madeafter  :
      This is for considering the atime, mtime, ctime at once for each file given.
      Try `madeafter *'.

(2) lastaccess :
      This command lists up and sort in the order when each file last accessed
      among all the descendant files under the current directory.
      First try `last access' on a directroy where `find .' would show less than 100 or 1000 files or less.

(3) timeput :
      Try `for i in $( seq 10 ) ; do echo $i ; sleep 1 ; done | timeput'. Then you will understand how it works.
      This commad get the input from STDIN then put the current time on the head of the each line and push to STDOUT.

More details about how to use those commands above can be seen by:
    madeafter --help
    perldocjp madeafter # You need `cpanm Pod::PerldocJp' beforehand.
    man madeafter

    lastaccess --help
    timeput --help

=cut

1 ; 


