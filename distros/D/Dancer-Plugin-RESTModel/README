Dancer-Plugin-RESTModel
========================

This plugin lets you talk to a REST server as a separate model from within
your Dancer (http://perldancer.org) app. It is useful for keeping your API
decoupled from your app while still being able to manage it through the
configuration file.


BASIC USAGE
-----------

set the REST endpoint in your Dancer configuration file:

```yaml
    plugins:
      RESTModel:
        MyData:
          server: http://localhost:5000
          type: application/json
          clientattrs:
            timeout: 5
```

then use it from any of your routes/controllers:

```perl
    use Dancer ':syntax';
    use Dancer::Plugin::RESTModel;

    get '/' => sub {
        my $res = model('MyData')->post( 'foo/bar/baz', { meep => 'moop' } );

        my $code = $res->code; # e.g. 200 
        my $data = $res->data;

        ...
    };
```

INSTALLATION
------------

    # from CPAN
    $ cpan Dancer::Plugin::RESTModel

    # from cpanm
    $ cpanm Dancer::Plugin::RESTModel

    # cloning the repository
    $ git clone git://github.com/EstanteVirtual/Dancer-Plugin-RESTModel.git

    # manual installation, after downloading
    perl Makefile.PL
    make
    make test
    make install


COPYRIGHT AND LICENCE
---------------------

Copyright (C) 2013, Breno G. de Oliveira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
