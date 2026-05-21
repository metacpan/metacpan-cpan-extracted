# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [CONSTRUCTOR](#constructor)
  * [new](#new)
    * [Attributes](#attributes)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
  * [parse\_distribution\_path](#parse\distribution\path)
  * [find\_module](#find\module)
  * [extract\_file](#extract\file)
  * [extract\_module](#extract\module)
  * [fetch\_darkpan\_index](#fetch\darkpan\index)
  * [fetch\_package](#fetch\package)
  * [init\_logger](#init\logger)
  * [fetch\_options](#fetch\options)
* [AUTHOR](#author)
* [SEE ALSO](#see-also)
* [LICENSE](#license)
# NAME

DarkPAN::Utils - utilities for working with a DarkPAN repository

# SYNOPSIS

    use DarkPAN::Utils qw(parse_distribution_path);
    use DarkPAN::Utils::Docs;

    # Fetch and search the remote index
    my $dpu = DarkPAN::Utils->new(
      base_url  => 'https://cpan.openbedrock.net/orepan2',
      log_level => 'debug',
    );

    $dpu->init_logger;
    $dpu->fetch_darkpan_index;

    my $packages = $dpu->find_module('Amazon::Lambda::Runtime');

    if ($packages) {
      $dpu->fetch_package( $packages->[0] );

      my $source = $dpu->extract_module(
        $packages->[0],
        'Amazon::Lambda::Runtime',
      );

      my $docs = DarkPAN::Utils::Docs->new( text => $source );
      print $docs->get_html;
    }

    # Work with a local tarball directly (no base_url required)
    use Archive::Tar;

    my $tar = Archive::Tar->new;
    $tar->read('Amazon-Lambda-Runtime-2.1.0.tar.gz');

    my $dpu = DarkPAN::Utils->new( package => $tar );

    my $source = $dpu->extract_module(
      'Amazon-Lambda-Runtime-2.1.0.tar.gz',
      'Amazon::Lambda::Runtime',
    );

    # Parse a distribution path directly
    my ($name, $version) = parse_distribution_path(
      'D/DU/DUMMY/Amazon-Lambda-Runtime-2.1.0.tar.gz'
    );
    # $name    => 'Amazon-Lambda-Runtime'
    # $version => '2.1.0'

# DESCRIPTION

`DarkPAN::Utils` provides utilities for interacting with a private CPAN
mirror (DarkPAN) hosted on Amazon S3 and served via CloudFront. It can
download and parse the standard CPAN package index
(`02packages.details.txt.gz`), fetch and unpack distribution tarballs,
and extract individual module source files for documentation generation.

The module may also be used with a local [Archive::Tar](https://metacpan.org/pod/Archive%3A%3ATar) object to avoid
any network access, which is the preferred approach when the tarball has
just been uploaded and the CDN cache may not yet reflect the new content.

When invoked directly as a script (`perl -MDarkPAN::Utils -e 1` or
`darkpan-utils`), it parses command-line options and fetches and
displays documentation for a named module.

# CONSTRUCTOR

## new

    my $dpu = DarkPAN::Utils->new( base_url => $url );

    my $dpu = DarkPAN::Utils->new( base_url => $url, log_level => 'debug' );

    my $dpu = DarkPAN::Utils->new( package => $archive_tar_object );

Creates a new `DarkPAN::Utils` instance. Arguments may be passed as a
flat list of key/value pairs or as a hashref.

### Attributes

- base\_url (required unless `package` is provided)

    The root URL of the DarkPAN repository, e.g.
    `https://cpan.openbedrock.net/orepan2`. Required when fetching the
    package index or tarballs from the network. Not required when a local
    [Archive::Tar](https://metacpan.org/pod/Archive%3A%3ATar) object is supplied via `package`.

- package

    An [Archive::Tar](https://metacpan.org/pod/Archive%3A%3ATar) object representing a pre-loaded distribution
    tarball. When provided, `base_url` is not required and no network
    access is performed by `extract_file` or `extract_module`.

- log\_level

    Logging verbosity. One of `trace`, `debug`, `info`, `warn`,
    or `error`. Defaults to `info`. Has no effect until `init_logger`
    is called.

- module

    The name of a Perl module (e.g. `Amazon::Lambda::Runtime`). Used by
    the command-line interface to identify the target module.

- logger

    A [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) logger instance. Populated by `init_logger`; not
    normally set directly.

# METHODS AND SUBROUTINES

## parse\_distribution\_path

    use DarkPAN::Utils qw(parse_distribution_path);

    my ($name, $version) = parse_distribution_path($path);

Exported function (not a method). Parses a distribution path in any of
the following formats and returns the distribution name and version as a
two-element list:

- Bare filename: `Amazon-Lambda-Runtime-2.1.0.tar.gz`
- CPAN author path: `D/DU/DUMMY/Amazon-Lambda-Runtime-2.1.0.tar.gz`
- Absolute local path: `/home/user/Amazon-Lambda-Runtime-2.1.0.tar.gz`

Returns an empty list if the path does not match the expected
`Name-Version.tar.gz` pattern.

## find\_module

    my $packages = $dpu->find_module('Amazon::Lambda::Runtime');

    if ($packages) {
      for my $path ( @{$packages} ) {
        print "$path\n";
      }
    }

Searches the in-memory module index (populated by `fetch_darkpan_index`)
for distributions that contain the named module. The search matches both
by distribution name (the hyphenated form) and by the module names listed
in the package index.

Returns an arrayref of matching distribution paths in
`D/DU/DUMMY/Name-Version.tar.gz` form, or `undef` if no match is found.

`fetch_darkpan_index` must be called before `find_module`.

## extract\_file

    my $content = $dpu->extract_file('Amazon-Lambda-Runtime-2.1.0/README.md');

Retrieves the raw content of a named file from the loaded distribution
tarball. The `package` attribute must be set, either by calling
`fetch_package` or by passing an [Archive::Tar](https://metacpan.org/pod/Archive%3A%3ATar) object to `new`.

The file name must exactly match an entry in the tarball (including the
leading `Distribution-Version/` directory prefix).

Returns the file content as a string, or `undef` if the file is not
found in the tarball.

## extract\_module

    my $source = $dpu->extract_module(
      'D/DU/DUMMY/Amazon-Lambda-Runtime-2.1.0.tar.gz',
      'Amazon::Lambda::Runtime',
    );

Extracts the source of a Perl module from the loaded distribution
tarball. The first argument is the distribution path in any format
accepted by `parse_distribution_path`; the version and path prefix are
stripped automatically. The second argument is the module name in
`::`-separated form.

The module is expected to reside at `lib/Module/Name.pm` within the
distribution directory.

Returns the module source as a string, or `undef` if the file is not
found.

## fetch\_darkpan\_index

    $dpu->fetch_darkpan_index;

Downloads `02packages.details.txt.gz` from the DarkPAN repository and
parses it into an internal module index. If the index has already been
fetched, this method returns immediately without making another request.

`base_url` must be set. Dies on HTTP failure or decompression error.
Returns `$self`.

## fetch\_package

    $dpu->fetch_package('D/DU/DUMMY/Amazon-Lambda-Runtime-2.1.0.tar.gz');

Downloads a distribution tarball from the DarkPAN repository, decompresses
it, and stores the resulting [Archive::Tar](https://metacpan.org/pod/Archive%3A%3ATar) object in the `package`
attribute, making its contents available to `extract_file` and
`extract_module`.

`base_url` must be set. Dies on HTTP failure. Returns `$self`.

## init\_logger

    $dpu->init_logger;

Initialises a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) logger at the level specified by the
`log_level` attribute (default `info`). Must be called before any
logging output is expected from `fetch_package` or related methods.

Returns `$self`.

## fetch\_options

    my $options = DarkPAN::Utils::fetch_options();

Parses command-line arguments for use when the module is run as a
script. Returns a hashref of options with hyphenated keys converted to
underscores.

Recognised options:

- --base-url, -u

    URL of the DarkPAN repository.

- --module, -m

    Name of the Perl module to retrieve and display.

- --log-level, -l

    Logging level (`trace`, `debug`, `info`, `warn`, `error`).
    Default: `info`.

- --package, -p

    Name of a specific distribution tarball.

- --help, -h

    Display usage information and exit.

# AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

# SEE ALSO

[DarkPAN::Utils::Docs](https://metacpan.org/pod/DarkPAN%3A%3AUtils%3A%3ADocs), [OrePAN2](https://metacpan.org/pod/OrePAN2), [OrePAN2::S3](https://metacpan.org/pod/OrePAN2%3A%3AS3), [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny),
[Archive::Tar](https://metacpan.org/pod/Archive%3A%3ATar), [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)

# LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
