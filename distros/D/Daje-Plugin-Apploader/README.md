[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Apploader/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Plugin-Apploader/actions?workflow=test)
# NAME

Daje::Plugin::Apploader - Loads stuff from a config file
during starup of the Daje server

# SYNOPSIS

    load_ables => {
              namespaces => {
                  plugins => [
                      {
                          name => ''
                     }
                  ],
                  routes => [
                      {
                          name => ''
                     }
                  ]
              },
           plugin => [
                  {
                     name => '',
                     options => [
                         {
                             name => '',
                            option => ''
                        }
                    ]
                }
            ],
            helper => [
                {
                    name => '',
                    class => '',
                    options => ''
                }
            ],
            routes => [
                {
                    route => '',
                    target => '',
                    method => ''
                }
            ]
      }
      use Daje::Plugin::Apploader;

      sub register ($self, $app)

# DESCRIPTION

Daje::Plugin::Apploader is a simple apploader for the Daje server.
It automatically installs missing / installs newer versions of
modules from cpan if told to

# REQUIRES

[Daje::Database::Migrator](https://metacpan.org/pod/Daje%3A%3ADatabase%3A%3AMigrator) 

[Mojo::Loader](https://metacpan.org/pod/Mojo%3A%3ALoader) 

[v5.42](https://metacpan.org/pod/v5.42) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## register

    register();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
