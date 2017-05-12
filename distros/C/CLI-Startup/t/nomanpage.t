# Test the print_manpage functionality with no POD

use Test::More;
use Test::Trap;

eval "use CLI::Startup 'startup'";
plan skip_all => "Can't load CLI::Startup" if $@;

# Simulate an invocation with --manpage
{
    local @ARGV = ('--manpage');

    trap { startup({ x => 'dummy option' }) };
    ok $trap->exit == 0, "Normal exit";
    ok $trap->stdout, "Error message printed";
    like $trap->stdout, qr/usage:/, "Usage message printed";
    like $trap->stderr, qr/^$/, "Nothing printed to stderr";
}

done_testing();

__END__
