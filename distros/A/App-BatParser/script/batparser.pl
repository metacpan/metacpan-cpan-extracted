#!/usr/bin/perl 

use strict;
use warnings;
use utf8;

use App::BatParser;
use Path::Tiny;
use Data::Dumper;
use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options(
    '%c %o <file>',
    [],
    ['help', 'print usage message and exit'],
);

print($usage->text), exit if $opt->help;

my $filename = shift;
if (!defined $filename) {
    print($usage->text);
    exit(1);
}

$filename = Path::Tiny::path($filename);

my $parser = App::BatParser->new;

print Dumper($parser->parse($filename->slurp));

