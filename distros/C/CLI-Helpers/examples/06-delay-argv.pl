use strict;
use warnings;
use CLI::Helpers qw(:output delay_argv);

my @copy = @ARGV;
output({color=>'cyan'}, sprintf '@ARGV was %s',
    join(', ', map { "'$_'" } @copy)
);

output({color=>'yellow'}, sprintf '@ARGV is %s',
    join(', ', map { "'$_'" } @ARGV)
);
