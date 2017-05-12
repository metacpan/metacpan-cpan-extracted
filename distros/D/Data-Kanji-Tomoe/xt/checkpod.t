use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Perl::Build::Pod ':all';
for my $filepath ("$Bin/../lib/Data/Kanji/Tomoe.pod"){
    my $errors = pod_checker ($filepath);
    ok (@$errors == 0, "No errors");
    my $linkerrors = pod_link_checker ($filepath);
    ok (@$linkerrors == 0, "No link errors");
    if (@$linkerrors) {
	for my $le (@$linkerrors) {
	    note ($le);
	}
    }
}

done_testing ();
