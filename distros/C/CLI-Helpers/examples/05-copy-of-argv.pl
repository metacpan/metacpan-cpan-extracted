use strict;
use warnings;
use CLI::Helpers qw(:output preprocess_argv copy_argv);

output({color=>'cyan'}, sprintf '@ARGV contains: %s',
    join(', ', map { "'$_'" } @ARGV)
);
