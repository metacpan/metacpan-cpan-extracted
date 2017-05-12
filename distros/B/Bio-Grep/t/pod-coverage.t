#!perl -T
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok({ trustme =>
[qr/(_isset|_reset|_clear|_count|_delete|_each|_index|_pop|_push|_set|_shift|_slice|_unshift|_exists|_get|_splice|_values|_keys|open|close|opendir|closedir|seek)$/,
qr/^(new2|generate_database|get_databases|get_sequences|search|next_res|filter|reset_filter)$/] });
