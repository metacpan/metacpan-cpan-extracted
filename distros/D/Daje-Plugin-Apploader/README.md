[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Apploader/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Plugin-Apploader/actions)
# NAME

Daje::Plugin::Apploader - It's new $module

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

Daje::Plugin::Apploader is ...

# REQUIRES

[Mojo::Loader](https://metacpan.org/pod/Mojo%3A%3ALoader) 

[v5.40](https://metacpan.org/pod/v5.40) 

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
