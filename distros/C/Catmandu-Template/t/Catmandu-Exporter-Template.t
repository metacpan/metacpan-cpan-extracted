#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::Template';
    use_ok $pkg;
}
require_ok $pkg;

my $file     = "";
my $template = <<EOF;
Author: [% author %]
Title: "[% title %]"
EOF

dies_ok {my $exp = $pkg->new(file => \$file, xml => 1)};

dies_ok {my $exp = $pkg->new(template_before => $template)};

lives_ok {$pkg->new(template => $template)};

my $exporter = $pkg->new(file => \$file, template => \$template);
my $data = {author => "brian d foy", title => "Mastering Perl",};

can_ok $exporter, "add";
can_ok $exporter, "commit";

$exporter->add($data);
$exporter->commit;
my $result = <<EOF;
Author: brian d foy
Title: "Mastering Perl"
EOF

is($file, $result, "Exported Format");

is($exporter->count, 1, "Count");

my $template_before = <<EOF;
Book

EOF
$file = "";
$exporter = $pkg->new(file => \$file, template => \$template, template_before => \$template_before);
$exporter->add($data);
$exporter->commit;
$result = <<EOF;
Book

Author: brian d foy
Title: "Mastering Perl"
EOF

is($file, $result, "Preamble added once");

done_testing;
