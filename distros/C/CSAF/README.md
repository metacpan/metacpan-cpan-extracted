[![Release](https://img.shields.io/github/release/giterlizzi/perl-CSAF.svg)](https://github.com/giterlizzi/perl-CSAF/releases) [![Actions Status](https://github.com/giterlizzi/perl-CSAF/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-CSAF/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-CSAF.svg)](https://github.com/giterlizzi/perl-CSAF) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-CSAF.svg)](https://github.com/giterlizzi/perl-CSAF) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-CSAF.svg)](https://github.com/giterlizzi/perl-CSAF) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-CSAF.svg)](https://github.com/giterlizzi/perl-CSAF/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-CSAF/badge.svg)](https://coveralls.io/github/giterlizzi/perl-CSAF)

# CSAF Perl Toolkit

## Synopsis

```.pl
use CSAF;

my $csaf = CSAF->new;

$csaf->document->title('Base CSAF Document');
$csaf->document->category('csaf_security_advisory');
$csaf->document->publisher(
    category  => 'vendor',
    name      => 'CSAF',
    namespace => 'https://csaf.io'
);

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2024-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

$tracking->revision_history->add(
    date    => 'now',
    summary => 'First release',
    number  => '1'
);

my @errors = $csaf->validate;

if (@errors) {
    say $_ for (@errors);
    Carp::croak "Validation errors";
}

# Save CSAF documents using the 
$csaf->writer(directory => '/var/www/html/csaf')->write;
```

## Command-Line Utility

- `csaf-downloader`, Download CSAF documents
- `csaf-rolie`, Create ROLIE feed
- `csaf-validator`, Validate a CSAF document
- `csaf2html`, Convert CSAF documents in HTML

## Install

Using Makefile.PL:

To install `CSAF` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using App::cpanminus:

    cpanm CSAF


## Documentation

 - `perldoc CSAF`
 - https://metacpan.org/release/CSAF
 - https://docs.oasis-open.org/csaf/csaf/v2.0/os/csaf-v2.0-os.html


## Copyright

 - Copyright 2023-2024 © Giuseppe Di Terlizzi
