use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );

foreach my $symbol (qw( archive_match_new ))
{
  plan skip_all => "test requires $symbol"
    unless Archive::Libarchive::Any->can($symbol);
}

plan tests => 6;

my $m = archive_match_new();

is archive_match_path_unmatched_inclusions($m), 0, 'archive_match_path_unmatched_inclusions = 0';

is archive_match_include_pattern($m, "^a1*"), ARCHIVE_OK, "archive_match_include_pattern";

is archive_match_path_unmatched_inclusions($m), 1, 'archive_match_path_unmatched_inclusions = 1';

is archive_match_path_unmatched_inclusions_next($m, my $pattern), ARCHIVE_OK, 'archive_match_path_unmatched_inclusions_next = ARCHIVE_OK';

is $pattern, '^a1*', 'pattern = ^a1*';

is archive_match_path_unmatched_inclusions_next($m, $pattern), ARCHIVE_EOF, 'archive_match_path_unmatched_inclusions_next = ARCHIVE_OK';
