# Test the constructor

use Test::More;
use Test::Trap;
use Test::Exception;

eval "use CLI::Startup";
plan skip_all => "Can't load CLI::Startup" if $@;

my $app;

# init() with basic option
{
    lives_ok { $app = CLI::Startup->new } "Default app object";
    lives_ok { $app->set_optspec({ foo => 'bar' }), $app->init } "with options";
    ok defined($app->get_optspec), "optspec is defined";
}

# init() with no options fails
{
    lives_ok { $app = CLI::Startup->new } "No-argument constructor";
    ok defined($app->get_optspec), "Default optspecs applied";
    lives_ok { $app->init }, "init() succeeds with no options";
}

# Setting usage string in initializer
{
    lives_ok { $app = CLI::Startup->new({ usage => "usage", options => undef }) }
        "Constructor with usage but no options";
    ok $app->get_usage eq 'usage', "Usage set correctly";
}

# Setting default args in initializer
{
    lives_ok { $app = CLI::Startup->new({ options => undef, default_settings => { a => 1 }}) }
        "Constructor with default settings";
    is_deeply $app->get_default_settings, { a => 1 }, "Settings are correct";
}

# Delete an auto-generated option
{
    lives_ok { $app = CLI::Startup->new({ options => { verbose => 0 } }) }
        "Constructor that deletes the verbose option";
}

# Exact match for an auto-generated option
{
    lives_ok { $app = CLI::Startup->new({ options => { 'verbose:1' => 'tell me everything' } }) }
        "Exact match for the verbose option";
}

# Collisions with the auto-generated options
{
    throws_ok { $app = CLI::Startup->new({ options => { verbose => 'tell me everything' } }) }
        qr/multiple definitions/i;
        #ok $app->get_usage eq 'usage', "Usage set correctly";
}

done_testing();
