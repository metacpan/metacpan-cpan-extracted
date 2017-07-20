use strict;
use warnings;
use autodie qw( :all );
use 5.010;
use Path::Tiny qw( path );

chdir(path(__FILE__)->absolute->parent->parent->child('corpus')->stringify);

system 'rm -rf Alien-Build-Git-Example1 example1.tar example1';
system 'git clone git@github.com:plicease/Alien-Build-Git-Example1.git Alien-Build-Git-Example1';
system 'mv Alien-Build-Git-Example1 example1';
system 'tar cvf example1.tar example1';
system 'rm -rf example1';
