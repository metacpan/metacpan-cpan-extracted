# Test the die_usage() functionality

use English;
use Test::More;
use Test::Trap;

eval "use CLI::Startup 'startup'";
plan skip_all => "Can't load CLI::Startup" if $@;

# Simulate an invocation with --help
{
    local @ARGV = ('--help');

    # Pretend to invoke the script
    trap { startup({ x => 'dummy option' }) };

    # Confirm the basic behaviors of --help
    ok $trap->exit == 0, "Normal exit";
    ok $trap->stdout, "Error message printed";
    like $trap->stdout, qr/usage:/, "Usage message printed";
    like $trap->stderr, qr/^$/, "Nothing printed to stderr";

    # Confirm that the output has some default options
    for my $opt (qw{ help manpage rcfile version write-rcfile })
    {
        like $trap->stdout, qr/^ \s+ $opt \s+ -/xms, "Default option $opt is present";
    }

    # Confirm that the options are sorted
    my @opts = $trap->stdout =~ /^ \s+ ([^\s]+) \s+ -/xmsg;
    is join("\n", @opts), join("\n", sort @opts), "Options are sorted alphanumerically";
}

done_testing();

__END__
