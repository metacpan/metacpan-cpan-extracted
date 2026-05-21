#!/usr/bin/env perl
# jq-lite: a tiny jq replacement for the simple-path subset.
#
# Usage:
#   perl eg/jq-lite.pl /path/to/key       file.json
#   cat file.json | perl eg/jq-lite.pl /path/to/key
#   perl eg/jq-lite.pl /users/0/name      data.json
#   perl eg/jq-lite.pl exists /users/5    data.json
#   perl eg/jq-lite.pl set   /users/0/age 31  data.json   # prints modified JSON
#   perl eg/jq-lite.pl del   /users/0/tmp     data.json
#
# This isn't a jq replacement — there are no filters, projections, or
# pipelines — but it covers the 80% case of "give me the value at this
# path" without the dependency footprint.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use JSON::PP;
use Data::Path::XS qw(path_get path_set path_delete path_exists);

sub usage {
    print STDERR <<'USE';
Usage:
  jq-lite.pl PATH                 [FILE]    # default: get
  jq-lite.pl get    PATH          [FILE]
  jq-lite.pl exists PATH          [FILE]
  jq-lite.pl set    PATH VALUE    [FILE]
  jq-lite.pl del    PATH          [FILE]

If FILE is omitted, JSON is read from stdin.
VALUE is parsed as JSON if possible, otherwise as a literal string.
USE
    exit 64;
}

my $action = 'get';
my @args   = @ARGV;
usage() unless @args;

if ($args[0] =~ /^(get|set|del|exists)$/) {
    $action = shift @args;
}

my $path = shift @args // usage();
my $value;
$value = shift @args if $action eq 'set';
my $file = shift @args;

my $json = $file ? do { local $/; open my $fh, '<', $file or die "$file: $!"; <$fh> }
                 : do { local $/; <STDIN> };

my $data = decode_json($json);

if ($action eq 'get') {
    my $got = path_get($data, $path);
    print encode_json([$got]) =~ s/^\[|\]$//gr, "\n";
}
elsif ($action eq 'exists') {
    print path_exists($data, $path) ? "true\n" : "false\n";
}
elsif ($action eq 'set') {
    my $parsed = eval { decode_json($value) };
    $parsed = $value if $@;
    path_set($data, $path, $parsed);
    print encode_json($data), "\n";
}
elsif ($action eq 'del') {
    path_delete($data, $path);
    print encode_json($data), "\n";
}
