#!perl
use strict;
use warnings;
use CLI::Helpers qw(:output);

my @TAGS = qw(
    red blue green
);

output("This line always shows up.");
foreach my $tag ( @TAGS ) {
    output({indent=>1,tag=>$tag}, "Tagging this line $tag");
}
