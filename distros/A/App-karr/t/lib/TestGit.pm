package TestGit;
use strict;
use warnings;
use Test::More;
use Exporter 'import';

our @EXPORT_OK = qw( require_git_c );

# Call at the top of a test file (before use_ok / subtests).
# Emits plan skip_all and exits if git < 1.8.5 (no -C support).
sub require_git_c {
    my $raw = `git --version 2>/dev/null` || '';
    my ($maj, $min, $pat) = $raw =~ /(\d+)\.(\d+)\.(\d+)/;
    ($maj, $min, $pat) = (0, 0, 0) unless defined $maj;
    unless ($maj > 1 || ($maj == 1 && $min > 8)
         || ($maj == 1 && $min == 8 && $pat >= 5)) {
        plan skip_all => "git $maj.$min.$pat too old (need >= 1.8.5 for -C flag)";
    }
}

1;
