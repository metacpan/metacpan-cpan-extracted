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

#only template_before, no records
{
    my $file     = "";
    my $template = <<EOF;
Author: [% author %]
EOF
    my $template_before = <<EOF;
---
EOF

    my $exporter = $pkg->new(
        file            => \$file,
        template        => \$template,
        template_before => \$template_before
    );
    $exporter->commit;

    is($file, $template_before,
        "no records added, only template_before rendered");
}

#only template_before, one record added
{
    my $file     = "";
    my $template = <<EOF;
Author: "[% author %]"
EOF
    my $template_before = <<EOF;
---
EOF

    my $exporter = $pkg->new(
        file            => \$file,
        template        => \$template,
        template_before => \$template_before
    );
    $exporter->add({author => "Nicolas Franck"});
    $exporter->commit;

    my $expected_result = <<EOF;
---
Author: "Nicolas Franck"
EOF

    is($file, $expected_result,
        "one record added, template_before prepended");
}

#only template_after, no records
{
    my $file     = "";
    my $template = <<EOF;
Author: [% author %]
EOF
    my $template_after = <<EOF;
...
EOF

    my $exporter = $pkg->new(
        file           => \$file,
        template       => \$template,
        template_after => \$template_after
    );
    $exporter->commit;

    is($file, $template_after,
        "no records added, only template_after rendered");
}

#only template_after, one record added
{
    my $file     = "";
    my $template = <<EOF;
Author: "[% author %]"
EOF
    my $template_after = <<EOF;
...
EOF

    my $exporter = $pkg->new(
        file           => \$file,
        template       => \$template,
        template_after => \$template_after
    );
    $exporter->add({author => "Nicolas Franck"});
    $exporter->commit;

    my $expected_result = <<EOF;
Author: "Nicolas Franck"
...
EOF

    is($file, $expected_result, "one record added, template_after appended");
}

#both template_before and template_after, one record added
{
    my $file     = "";
    my $template = <<EOF;
Author: "[% author %]"
EOF

    my $template_before = <<EOF;
---
EOF

    my $template_after = <<EOF;
...
EOF

    my $exporter = $pkg->new(
        file            => \$file,
        template        => \$template,
        template_before => \$template_before,
        template_after  => \$template_after
    );
    $exporter->add({author => "Nicolas Franck"});
    $exporter->commit;

    my $expected_result = <<EOF;
---
Author: "Nicolas Franck"
...
EOF

    is($file, $expected_result, "one record added, template_after appended");
}

done_testing;
