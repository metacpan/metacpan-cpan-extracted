# Alien::DuckDB

This module provides a way to download, build and install DuckDB for use by other Perl modules.

## Installation

To install this module, run the following commands:

```bash
perl Makefile.PL
make
make test
make install
```

## Local Development and Testing

90% of this module is just making sure that the upstream module installs
correctly. We leverage a GitHub workflow for this, to test the GitHub workflows
locally we use `act`.

### Setting up Docker with Colima (macOS)

For testing GitHub Actions workflows locally on macOS, you can use Colima as a lightweight Docker alternative:

1. Install prerequisites:
   ```bash
   # Install Docker CLI (without Docker Desktop)
   brew install docker

   # Install Colima
   brew install colima

   # Install Act for running GitHub Actions
   brew install act
   ```

2. Start Colima:
   ```bash
   # Start with default settings
   colima start

   # Or with custom resources
   colima start --cpu 4 --memory 8 --disk 50
   ```

3. Verify Docker is working:
   ```bash
   docker run --rm hello-world
   ```

### Testing GitHub Workflows Locally

To test the GitHub Actions workflows locally using Act:

```bash
# On Apple Silicon (M1/M2/M3) Macs
act -W .github/workflows/install.yml \
  --container-architecture linux/amd64 \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest

# On Intel Macs
act -W .github/workflows/install.yml \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

Notes:
- This will only run the Ubuntu jobs; Windows and macOS jobs will be skipped
- For more verbose output, add `-v` or `-vv` flags
- For longer-running tasks, add `--timeout 30m`
- To test a specific job: `-j "Perl 5.40.2 on ubuntu-latest"`

### Stopping Colima

When you're done testing:

```bash
colima stop
```

## Support and Documentation

After installing, you can find documentation for this module with the
perldoc command.

```bash
perldoc Alien::DuckDB
```

You can also look for information at:

* [GitHub repository](https://github.com/perigrin/Alien-DuckDB)
* [MetaCPAN](https://metacpan.org/pod/Alien::DuckDB)
* [RT, CPAN's request tracker](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-DuckDB)
* [CPAN Ratings](https://cpanratings.perl.org/d/Alien-DuckDB)

## License and Copyright

Copyright (C) 2024 Chris Prather

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
