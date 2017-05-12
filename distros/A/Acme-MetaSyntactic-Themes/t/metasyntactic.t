use Test::More;
use Test::MetaSyntactic;

# allow passing themes on the command-line
if (@ARGV) {
    plan tests => scalar @ARGV;
    theme_ok($_) for @ARGV;
}
else {
    all_themes_ok();
}

