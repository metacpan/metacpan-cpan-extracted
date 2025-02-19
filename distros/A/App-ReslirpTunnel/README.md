# App::ReslirpTunnel

## Description

App::ReslirpTunnel is a wrapper for the `reslirp-tunnel` application, which enables the establishment of a network tunnel through an SSH connection, ending in reSLIRP.

This application takes care of all necessary initialization, configuration, and the underlying communication processes needed to maintain the tunnel.

Please note that this module is not designed for direct use; it solely acts as a wrapper for the underlying functionality of the reslirp-tunnel application.

## Installation

To install App::ReslirpTunnel, you can use either the standard Perl module installation method with MakeMaker or the CPAN client.

### Using MakeMaker

If you prefer to install manually, run the following commands in your terminal:

```bash
perl Makefile.PL
make
make test
make install
```

Ensure you have the necessary permissions to install modules on your system.

### Using CPAN

Alternatively, you can easily install the module using the CPAN command-line client with a single command:

```bash
cpan App::ReslirpTunnel
```

## Bugs and Support

To report bugs or request features, please visit the GitHub repository at [https://github.com/salva/p5-App-ReslirpTunnel](https://github.com/salva/p5-App-ReslirpTunnel).

## Copyright and License

Copyright (C) 2025 by Salvador Fandiño (sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.38.2 or any later version of Perl 5 you may have available.
