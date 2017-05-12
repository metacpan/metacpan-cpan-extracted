use Test::Modern;
use FindBin;

use aliased "Bot::BasicBot::Pluggable::FromConfig";


chdir("$FindBin::Bin/json");
subtest 'Config - Name only' => sub {
    # Bot::BasicBot::Pluggable spits out all sorts of weird and unexpected warnings
    # Well supress them
    my $bot;
    warnings( sub { $bot = FromConfig->new_with_config(config => \'test') } );

    object_ok(
        $bot,
        "Bot::BasicBot::Pluggable::FromConfig",
        isa     => "Bot::BasicBot::Pluggable",
        can     => ["new_with_config", "load", "module"],
        more    => sub {
            my ($object) = @_;
            my $module = $object->module('Karma');
            object_ok(
                $module,
                "Bot::BasicBot::Pluggable::Module::Karma",
                isa     => "Bot::BasicBot::Pluggable::Module",
                can     => ['add_karma', 'get_karma'],
                more    => sub {
                    my ($object) = @_;

                    is($object->get('karma_change_response') => 0, 'Karma config item set correctly');
                    is($object->get('user_num_comments') => 5, 'Second Karma config item set correctly');
                },
            );
        },
    );
};
chdir("$FindBin::Bin/..");

subtest 'Config - Config::JFDI args' => sub {
    # Bot::BasicBot::Pluggable spits out all sorts of weird and unexpected warnings
    # Well supress them
    my $bot;
    warnings( sub { $bot = FromConfig->new_with_config(config => {name => \"test", path => "$FindBin::Bin/json"}) } );

    object_ok(
        $bot,
        "Bot::BasicBot::Pluggable::FromConfig",
        isa     => "Bot::BasicBot::Pluggable",
        can     => ["new_with_config", "load", "module"],
        more    => sub {
            my ($object) = @_;
            my $module = $object->module('Karma');
            object_ok(
                $module,
                "Bot::BasicBot::Pluggable::Module::Karma",
                isa     => "Bot::BasicBot::Pluggable::Module",
                can     => ['add_karma', 'get_karma'],
                more    => sub {
                    my ($object) = @_;

                    is($object->get('karma_change_response') => 0, 'Karma config item set correctly');
                    is($object->get('user_num_comments') => 5, 'Second Karma config item set correctly');
                },
            );
        },
    );
};
done_testing;
