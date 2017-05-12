use strict;
use warnings;
use utf8;

use Test::More;
use Encode;

binmode(Test::More->builder->$_, ':utf8') for qw/failure_output output todo_output/;

sub is_output(&$$) {
    my ($func, $expected, $comment) = @_;

    my $output;
    open my $OUT, '>', \$output;
    local *STDOUT = $OUT;
    $func->();
    close($OUT);
    $output =~ s/\e\[([34]8;5;[0-9]+?|0)m//g; # strip color
    is decode_utf8($output), $expected, $comment;
}

1;
