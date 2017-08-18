#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::Template;

my $file     = "";
my $template = <<EOF;
Author: <% author !>
Title: "<% title !>"
EOF

my $exporter = Catmandu::Exporter::Template->new(
    file      => \$file,
    template  => \$template,
    start_tag => "<%",
    end_tag   => "!>"
);
my $data = {author => "brian d foy", title => "Mastering Perl",};

$exporter->add($data);

my $result = <<EOF;
Author: brian d foy
Title: "Mastering Perl"
EOF

is($file, $result, "Exported Format");

my $template2 = <<EOF;
Author: <? author ?>
Title: "<? title ?>"
EOF

my $exporter2 = Catmandu::Exporter::Template->new(
    file      => \$file,
    template  => \$template2,
    tag_style => "php"
);
$exporter2->add($data);

is($file, $result, "Tag style ok");

# TT caching
$exporter = Catmandu::Exporter::Template->new(
    template  => \$template,
    start_tag => "<%",
    end_tag   => "!>"
);
$exporter2 = Catmandu::Exporter::Template->new(
    template  => \$template,
    start_tag => "<%",
    end_tag   => "!>"
);

ok $exporter->_tt == $exporter2->_tt,
    'tt engines wirth equal arguments get reused';

$exporter2 = Catmandu::Exporter::Template->new(
    template  => \$template,
    start_tag => "<%",
    end_tag   => "%>"
);

ok $exporter->_tt != $exporter2->_tt,
    'tt engines wirth equal arguments get reused';

done_testing;
