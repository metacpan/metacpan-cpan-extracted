# NAME

Config::ENV - Various config determined by %ENV

# SYNOPSIS

    package MyConfig;
    
    use Config::ENV 'PLACK_ENV'; # use $ENV{PLACK_ENV} to determine config
    
    common +{
      name => 'foobar',
    };
    
    config development => +{
      dsn_user => 'dbi:mysql:dbname=user;host=localhost',
    };
    
    config test => +{
      dsn_user => 'dbi:mysql:dbname=user;host=localhost',
    };
    
    config production => +{
      dsn_user => 'dbi:mysql:dbname=user;host=127.0.0.254',
    };
    
    config production_bot => +{
      parent('production'),
      bot => 1,
    };

    # Use it

    use MyConfig;
    MyConfig->param('dsn_user'); #=> ...

# DESCRIPTION

Config::ENV is for switching various configurations by environment variable.

# CONFIG DEFINITION

use this module in your config package:

    package MyConfig;
    use Config::ENV 'FOO_ENV';

    common +{
      name => 'foobar',
    };

    config development => +{};
    config production  => +{};

    1;

- common($hash)

    Define common config. This $hash is merged with specific environment config.

- config($env, $hash);

    Define environment config. This $hash is just enabled in $env environment.

- parent($env);

    Expand $env configuration to inherit it.

- load($filename);

    \`do $filename\` and expand it. This can be used following:

        # MyConfig.pm
        common +{
          API_KEY => 'Set in config.pl',
          API_SECRET => 'Set in config.pl',
          load('config.pl),
        };

        # config.pl
        +{
          API_KEY => 'XFATEAFAFASG',
          API_SECRET => 'ced3a7927fcf22cba72c2559326be2b8e3f14a0f',
        }

## EXPORT

You can specify default export name in config class. If you specify 'export' option as following:

    package MyConfig;
    use Config::ENV 'FOO_ENV', export => 'config';

    ...;

and use it with 'config' function.

    package Foobar;
    use MyConfig; # exports 'config' function

    config->param('...');

# METHODS

- config->param($name)

    Returns config variable named $name.

- $guard = config->local(%hash)

    This is for scope limited config. You can use this when you use other values in temporary. Returns guard object.

        is config->param('name'), 'original value';
        {
          my $guard = config->local(name => 'localized');
          is config->param('name'), 'localized';
        };
        is config->param('name'), 'original value';

- config->env

    Returns current environment name.

- config->current

    Returns current configuration as HashRef.

# AUTHOR

cho45 <cho45@lowreal.net>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
