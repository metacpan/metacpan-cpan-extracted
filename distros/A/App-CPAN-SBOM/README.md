[![Release](https://img.shields.io/github/release/giterlizzi/perl-App-CPAN-SBOM.svg)](https://github.com/giterlizzi/perl-App-CPAN-SBOM/releases) [![Actions Status](https://github.com/giterlizzi/perl-App-CPAN-SBOM/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-App-CPAN-SBOM/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-App-CPAN-SBOM.svg)](https://github.com/giterlizzi/perl-App-CPAN-SBOM) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-App-CPAN-SBOM.svg)](https://github.com/giterlizzi/perl-App-CPAN-SBOM) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-App-CPAN-SBOM.svg)](https://github.com/giterlizzi/perl-App-CPAN-SBOM) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-App-CPAN-SBOM.svg)](https://github.com/giterlizzi/perl-App-CPAN-SBOM/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-App-CPAN-SBOM/badge.svg)](https://coveralls.io/github/giterlizzi/perl-App-CPAN-SBOM)

# App-CPAN-SBOM - CPAN SBOM (Software Bill of Materials) generator

## Synopsis

```.bash
cpan-sbom --distribution NAME@VERSION
cpan-sbom --meta (META|MYMETA).(json|yml)

cpan-sbom --project-directory DIRECTORY [ --project-name NAME --project-version VERSION --project-description TEXT
                                          --project-license SPDX-LICENSE --project-type BOM-TYPE
                                          --project-author STRING [--project-author STRING] ]

cpan-sbom [--help|--man|-v]

Options:
  -o, --output                          Output file. Default bom.json 

      --distribution NAME@VERSION       Distribution name and version
      --meta                            META or MYMETA file

      --project-directory NAME          Project directory
      --project-meta                    Project META or MYMETA file (alias of --meta)
      --project-type BOM-TYPE           Project type (default: library)
      --project-name NAME               Project name (default: project directory name)
      --project-version VERSION         Project version
      --project-author STRING           Project author(s)
      --project-license SPDX-LICENSE    Project SPDX license
      --project-description TEXT        Project description                  

      --maxdepth=NUM                    Max depth (default: 1)
      --vulnerabilities                 Include Module/Distribution vulnerabilities
      --no-vulnerabilities

      --validate                        Validate the generated SBOM using JSON Schema (default: true)
      --no-validate

      --list-spdx-licenses              List SPDX licenses

      --debug                           Enable debug messages

      --help                            Brief help message
      --man                             Full documentation
  -v, --version                         Print version

OWASP Dependency Track options:
      --server-url URL                  Dependency Track URL (Env: $DTRACK_URL)
      --api-key STRING                  API-Key (Env: $DTRACK_API_KEY)
      --skip-tls-check                  Disable SSL/TLS check (Env: $DTRACK_SKIP_TLS_CHECK)
      --project-id STRING               Project ID (Env: $DTRACK_PROJECT_ID)
      --project-name NAME               Project name (Env: DTRACK_PROJECT_NAME)
      --project-version VERSION         Project version (Env: $DTRACK_PROJECT_VERSION)
      --parent-project-id STRING        Parent project ID (Env: $DTRACK_PARENT_PROJECT_ID)
```

## Examples

```.bash
Create SBOM of specific distribution:

$ cpan-sbom --distribution libwww-perl@6.78

Create SBOM from META file:

$ cpan-sbom --meta META.json

Create SBOM from your project directory:

$ cpan-sbom \
    --project-directory . \
    --project-name "My Cool Application" \
    --project-type application \
    --project-version 1.337 \
    --project-license Artistic-2.0
    --project-author "Larry Wall <larry@wall.org>"

Create SBOM file and upload to OWASP Dependency Track:

$ cpan-sbom \
  --meta META.json \
  --server-url https://dtrack.example.com \
  --api-key DTRAC-API-KEY \
  --project-id DTRACK-PROJECT-ID
```

## Install

Using Makefile.PL:

To install `App-CPAN-SBOM` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using `App::cpanminus`:

    cpanm App::CPAN::SBOM


## Documentation

- `perldoc App::CPAN::SBOM`
- https://metacpan.org/release/App-CPAN-SBOM

## Copyright

- Copyright 2025 © Giuseppe Di Terlizzi
