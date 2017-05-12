use strict;
use warnings;
use Test::More tests => 8;
use Clustericious::Config;

# Check for issues with autoload conflicts code imported
# from required modules.

my %tests = (
    home => 'dir',
    first => 'base',
    Load => 'me',
    Dump => 'me',
    dclone => 'you',
    getcwd => 'foo',
    abs_path => 'bar',
    prompt => 'hi',
);

my $c = Clustericious::Config->new({%tests});

for my $k (sort keys %tests) {
    is $c->$k, $tests{$k}, "$k works";
}

