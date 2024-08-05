[![Release](https://img.shields.io/github/release/giterlizzi/perl-CVSS.svg)](https://github.com/giterlizzi/perl-CVSS/releases) [![Actions Status](https://github.com/giterlizzi/perl-CVSS/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-CVSS/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-CVSS.svg)](https://github.com/giterlizzi/perl-CVSS) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-CVSS.svg)](https://github.com/giterlizzi/perl-CVSS) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-CVSS.svg)](https://github.com/giterlizzi/perl-CVSS) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-CVSS.svg)](https://github.com/giterlizzi/perl-CVSS/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-CVSS/badge.svg)](https://coveralls.io/github/giterlizzi/perl-CVSS)

# CVSS - Perl extension for CVSS (Common Vulnerability Scoring System) 2.0/3.x/4.0

## Synopsis

```.pl
use CVSS;

# OO-interface

# Method 1 - Use params

$cvss = CVSS->new(
  version => '3.1',
  metrics => {
      AV => 'A',
      AC => 'L',
      PR => 'L',
      UI => 'R',
      S => 'U',
      C => 'H',
      I => 'H',
      A => 'H',
  }
);


# Method 2 - Decode and parse the vector string

use CVSS;

$cvss = CVSS->from_vector_string('CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H');

say $cvss->base_score; # 7.4


# Method 3 - Builder

use CVSS;

$cvss = CVSS->new(version => '3.1');
$cvss->attackVector('ADJACENT_NETWORK');
$cvss->attackComplexity('LOW');
$cvss->privilegesRequired('LOW');
$cvss->userInteraction('REQUIRED');
$cvss->scope('UNCHANGED');
$cvss->confidentialityImpact('HIGH');
$cvss->integrityImpact('HIGH');
$cvss->availabilityImpact('HIGH');

$cvss->calculate_score;

# Common methods

# Convert the CVSS object in "vector string"
say $cvss; # CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H

# Get metric value
say $cvss->AV; # A
say $cvss->attackVector; # ADJACENT_NETWORK

# Get the base score
say $cvss->base_score; # 7.4

# Get all scores
say Dumper($cvss->scores);

# { "base"           => "7.4",
#   "exploitability" => "1.6",
#   "impact"         => "5.9" }

# Get the base severity
say $cvss->base_severity # HIGH

# Convert CVSS in XML in according of CVSS XML Schema Definition
$xml = $cvss->to_xml;

# Convert CVSS in JSON in according of CVSS JSON Schema
$json = encode_json($cvss);


# exported functions

use CVSS qw(decode_cvss encode_cvss)

$cvss = decode_cvss('CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H');
say $cvss->base_score;  # 7.4

$vector_string = encode_cvss(version => '3.1', metrics => {...});
say $cvss_string; # CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H
```


## cvss command-line-interface

Get the base score:

```console
$ cvss CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H --base-score
7.4
```

Get the base severity:

```console
$ cvss CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H --base-severity
HIGH
```

Parses the provided vector string and returns the JSON representation:

```console
$ cvss CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H --json | jq
{
  "attackComplexity": "LOW",
  "attackVector": "ADJACENT_NETWORK",
  "availabilityImpact": "HIGH",
  "baseScore": 7.4,
  "baseSeverity": "HIGH",
  "confidentialityImpact": "HIGH",
  "integrityImpact": "HIGH",
  "privilegesRequired": "LOW",
  "scope": "UNCHANGED",
  "userInteraction": "REQUIRED",
  "vectorString": "CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H",
  "version": "3.1"
}
```

Parses the provided vector string and returns the XML representation:

```console
$ cvss CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H --xml
<?xml version="1.0" encoding="UTF-8"?>
<cvssv3.1 xmlns="https://www.first.org/cvss/cvss-v3.1.xsd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="https://www.first.org/cvss/cvss-v3.1.xsd https://www.first.org/cvss/cvss-v3.1.xsd"
  >

  <base_metrics>
    <attack-vector>ADJACENT_NETWORK</attack-vector>
    <attack-complexity>LOW</attack-complexity>
    <privileges-required>LOW</privileges-required>
    <user-interaction>REQUIRED</user-interaction>
    <scope>UNCHANGED</scope>
    <confidentiality-impact>HIGH</confidentiality-impact>
    <integrity-impact>HIGH</integrity-impact>
    <availability-impact>HIGH</availability-impact>
    <base-score>7.4</base-score>
    <base-severity>HIGH</base-severity>
  </base_metrics>

</cvssv3.1>
```


## Install

Using Makefile.PL:

To install `CVSS` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using `App::cpanminus`:

    cpanm CVSS


## Documentation

- `perldoc CVSS`
- https://metacpan.org/release/CVSS
- [FIRST] CVSS Data Representations (https://www.first.org/cvss/data-representations)
- [FIRST] CVSS v4.0 Specification (https://www.first.org/cvss/v4.0/specification-document)
- [FIRST] CVSS v3.1 Specification (https://www.first.org/cvss/v3.1/specification-document)
- [FIRST] CVSS v3.0 Specification (https://www.first.org/cvss/v3.0/specification-document)
- [FIRST] CVSS v2.0 Complete Guide (https://www.first.org/cvss/v2/guide)

## Copyright

- Copyright 2007-2024 © FIRST.org - Forum of Incident Response and Security Teams, Inc.
- Copyright 2023-2024 © Giuseppe Di Terlizzi
