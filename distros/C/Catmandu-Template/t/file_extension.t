#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::Template;

my $file = "";

my $exporter = Catmandu::Exporter::Template->new(
    file      => \$file,
    template  => 'out.html',
    start_tag => "<%",
    end_tag   => "!>"
);

my $data = {author => "brian d foy", title => "Mastering Perl",};

$exporter->add($data);

my $result = <<EOF;
Author: brian d foy
Title: "Mastering Perl"
EOF

is($file, $result, "html extension");

my $exporter2 = Catmandu::Exporter::Template->new(
    file      => \$file,
    template  => 'out.tt',
    start_tag => "<%",
    end_tag   => "!>"
);

$exporter2->add($data);

is($file, $result, "tt extension");

done_testing;
