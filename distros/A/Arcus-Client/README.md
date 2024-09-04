# Arcus Perl Client (Arcus::Client)
This module is the Perl client library for Arcus cache cluster. It uses [Arcus zookeeper](https://github.com/naver/arcus-zookeeper) and [Arcus C Client](https://github.com/naver/arcus-c-client) to support cross-shard operations on the elastic Arcus clusters. Also, It supports most of the methods provided by [Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast), but `incr_multi`, `decr_multi`, and `delete_multi` are not yet supported.

The module has been tested on the following OS platforms.
- MacOS
- CentOS 7.x 64bit

If you are interested in supporting other OS platforms, please try building and running this module with Arcus on them. And let us know of any issues.

## INSTALLATION

Before installation, dependent Perl modules are required. If these modules are not already installed, type the command below to install the dependencies:
```
cpan ExtUtils::MakeMaker YAML XSLoader parent POSIX::AtFork Digest::SHA IO::Socket::PortState Test::Deep
```

To install this module, type the following:
```
perl Makefile.PL [INSTALL_BASE=<module_install_path>]
make
make test
make install
```
If *module_install_path* was given with INSTALL_BASE, the module will be installed in there.
In this case, you need to add *module_install_path* to the `PERL5LIB` environment variable.

To learn more about Makefile.PL, see the [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)

## TEST

To run tests, the Arcus cluster has to be prepared in advance.
There should be a service code named "test" and a zookeeper with a port number 2181.

## DEPENDENCIES

This module requires these other modules and libraries:

- [Arcus zookeeper](https://github.com/naver/arcus-zookeeper)
- [Arcus C Client](https://github.com/naver/arcus-c-client)

They are installed with the build process. So there's no need to install them separately.

## COPYRIGHT AND LICENCE

Copyright (C) 2024 by JaM2in. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.


