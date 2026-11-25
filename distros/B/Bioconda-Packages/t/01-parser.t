use strict;
use warnings;
use Test::More;
use Bioconda::Packages::RecipeParser qw(parse_string);

# --- A typical C package recipe -------------------------------------------
my $samtools = <<'YAML';
{% set version = "1.25" %}

package:
  name: samtools
  version: {{ version }}

build:
  number: 0
  run_exports:
    - {{ pin_subpackage("samtools", max_pin="x") }}

requirements:
  build:
    - make
    - {{ compiler('c') }}
  host:
    - htslib
    - zlib
  run:
    - perl

about:
  home: https://github.com/samtools/samtools
  license: MIT
  summary: Tools for dealing with SAM, BAM and CRAM files

extra:
  identifiers:
    - biotools:samtools
    - usegalaxy-eu:samtools_flagstat
YAML

my $i = parse_string($samtools);
is($i->{name},    'samtools', 'name parsed');
is($i->{version}, '1.25',     'version from {% set %}');
is($i->{license}, 'MIT',      'license parsed');
is($i->{home}, 'https://github.com/samtools/samtools', 'home URL keeps its colon');
is_deeply([ map { $_->{name} } @{ $i->{depends}{host} } ],
          [qw(htslib zlib)], 'host deps');
is_deeply([ map { $_->{name} } @{ $i->{depends}{run} } ],
          [qw(perl)], 'run deps');
is_deeply([ map { $_->{name} } @{ $i->{depends}{build} } ],
          [qw(make)], 'jinja compiler() dropped from build deps');
is_deeply($i->{identifiers},
          [qw(biotools:samtools usegalaxy-eu:samtools_flagstat)],
          'identifiers are scalars, not mis-parsed as mappings');
is_deeply($i->{warnings}, [], 'no warnings on a clean recipe');

# --- Jinja filters and name concatenation ---------------------------------
my $arb = <<'YAML';
{% set name = "ARB" %}
{% set version = "6.0.6" %}
package:
  name: {{ name|lower }}-bio
  version: {{ version }}
YAML
my $a = parse_string($arb);
is($a->{name}, 'arb-bio', '|lower filter and literal concatenation');

my $rpkg = <<'YAML';
{% set version = '0.4.2' %}
package:
  name: r-corncob
  version: {{ version|replace("-", "_") }}
YAML
is(parse_string($rpkg)->{version}, '0.4.2', 'replace() filter handled');

# --- version constraints --------------------------------------------------
my $con = <<'YAML';
package:
  name: foo
  version: 1.0
requirements:
  run:
    - python >=3.9,!=3.14.1
    - numpy
YAML
my $c = parse_string($con);
my ($py) = grep { $_->{name} eq 'python' } @{ $c->{depends}{run} };
is($py->{constraint}, '>=3.9,!=3.14.1', 'version constraint captured');

# --- multi-line scalar before requirements must not swallow deps ----------
my $ml = <<'YAML';
about:
  home: http://example.org
  summary: 'This is a long summary that
    wraps across several
    physical lines.'
  license: GPL-3.0

requirements:
  run:
    - blast

package:
  name: genblasta
  version: '1.0.4'
YAML
my $m = parse_string($ml);
is($m->{name}, 'genblasta', 'package after multi-line scalar still parsed');
is($m->{version}, '1.0.4', 'version after multi-line scalar still parsed');
is_deeply([ map { $_->{name} } @{ $m->{depends}{run} } ],
          [qw(blast)], 'deps after multi-line scalar not lost');

# --- block scalar ( | ) ---------------------------------------------------
my $bs = <<'YAML';
about:
  summary: short
  description: |
    line one
    line two
  license: MIT
requirements:
  run:
    - zlib
package:
  name: bar
  version: 2.0
YAML
my $b = parse_string($bs);
is($b->{name}, 'bar', 'package after block scalar parsed');
is_deeply([ map { $_->{name} } @{ $b->{depends}{run} } ],
          [qw(zlib)], 'deps after block scalar not lost');

# --- "name :" with space before the colon ---------------------------------
my $sp = <<'YAML';
{% set version = "0.33" %}
package:
  name : perl-config-any
  version: {{ version }}
YAML
is(parse_string($sp)->{name}, 'perl-config-any', 'space before colon in key');

# --- warnings on an unresolvable version ----------------------------------
my $bad = <<'YAML';
{% set version = github_version_str.replace("-",".") %}
package:
  name: contammix
  version: {{ version }}
YAML
my $w = parse_string($bad);
is($w->{name}, 'contammix', 'name still parsed when version unresolvable');
ok(grep({ /version/ } @{ $w->{warnings} }), 'warning flagged for bad version');

done_testing;
