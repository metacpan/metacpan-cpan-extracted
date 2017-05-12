# NAME

Bot::BasicBot::Pluggable::FromConfig - Create a bot from a config file.

# SYNOPSIS

    use Bot::BasicBot::Pluggable::FromConfig;

    my $bot = Bot::BasicBot::Pluggable::FromConfig->new_with_config(
        config => {name => 'my_bot', path => 'some/path'},
    );

# DESCRIPTION

`Bot::BasicBot::Pluggable::FromConfig` is a config loader for [Bot::BasicBot::Pluggable](https://metacpan.org/pod/Bot::BasicBot::Pluggable) allowing all of your Bot configuration to be declared in its own file. It is largely based on [Bot::BasicBot::Pluggable::WithConfig](https://metacpan.org/pod/Bot::BasicBot::Pluggable::WithConfig). It's designed to allow for a wider degree of flexibility with its range of accepted config files.

FromConfig uses Config::JFDI to load a config based on the name supplied to the config argument. This allows pretty much any config style you want and also allows for a '\_local' file to override on a per-instance bases if you need.

# Running a Bot

This library provides a command line script called [run_bot](https://metacpan.org/pod/run_bot). This provides a complete implementation of this module. Documentation can be found there.

Alternatively you can create your own implementation of this in your own scripts. The simplest method is to call new\_with\_config() and pass it a config name and then call run on the returned Bot object.

# METHODS

## new\_with\_config( config => 'my\_bot' )

This is the only method provided in this module beyond those described in [Bot::BasicBot::Pluggable](https://metacpan.org/pod/Bot::BasicBot::Pluggable). It accepts a hash as its arguments which must contain a config key. This key can either be the name of the config sans extension (which will be passed as the name param to Config::JFDI) or a hashref of params to pass through to Config::JFDI.

A new Bot::BasicBot::Pluggable::FromConfig object which inherits from [Bot::BasicBot::Pluggable](https://metacpan.org/pod/Bot::BasicBot::Pluggable) is returned.

# Config Keys

All attributes accepted by the constructor of [Bot::BasicBot::Pluggable](https://metacpan.org/pod/Bot::BasicBot::Pluggable) and thus [Bot::BasicBot](https://metacpan.org/pod/Bot::BasicBot) are valid configuration items.

## plugins

An arrayref of plugins are also accepted:

    {
        "channels": ["#perl"],
        "plugins": [
            {
                "module": 'Karma',
                "config": {
                    "karma_change_reponse": 0
                },
            },
            {
                "module": "Bot::BasicBot::Pluggable::Module::Auth",
            },
    }

Each should provide at minimum the name of the Module that implements the plugin. This can either be the full qualified name (Bot::BasicBot::Pluggable::Module::Name) or just the qualifying module name.

A config hashref can also be specified and these items will be passed to the plugin objects set() method.

# KNOW ISSUES

There is known issue in Bot::BasicBot::Pluggable when using more recent version of Perl and POD::Checker. This will cause it to fail its t/release-pod-syntax test (https://rt.cpan.org/Public/Bug/Display.html?id=89806). Users should --force install B::BB::P before installing this module.

# SEE ALSO

[Config::JFDI](https://metacpan.org/pod/Config::JFDI)

[Bot::BasicBot::Pluggable](https://metacpan.org/pod/Bot::BasicBot::Pluggable)

# LICENSE

Copyright (C) Mike Francis.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Mike Francis <ungrim97@gmail.com>
