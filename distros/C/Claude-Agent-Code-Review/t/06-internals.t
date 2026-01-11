#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Test internal functions that don't require Claude API calls

use_ok('Claude::Agent::Code::Review');

# Access internal functions for testing
# Note: These are implementation details but important to test for robustness

# Test _is_diff_content
subtest '_is_diff_content - git diff format' => sub {
    my $git_diff = <<'END';
diff --git a/lib/Foo.pm b/lib/Foo.pm
index abc1234..def5678 100644
--- a/lib/Foo.pm
+++ b/lib/Foo.pm
@@ -10,6 +10,7 @@
 use strict;
 use warnings;
+use Path::Tiny;
END

    ok(Claude::Agent::Code::Review::_is_diff_content($git_diff),
       'detects git diff format');
};

subtest '_is_diff_content - unified diff format' => sub {
    my $unified_diff = <<'END';
--- a/old_file.pm	2024-01-01 12:00:00.000000000 +0000
+++ b/new_file.pm	2024-01-02 12:00:00.000000000 +0000
@@ -1,3 +1,4 @@
 package Foo;
 use strict;
+use warnings;
END

    ok(Claude::Agent::Code::Review::_is_diff_content($unified_diff),
       'detects unified diff format');
};

subtest '_is_diff_content - svn diff format' => sub {
    my $svn_diff = <<'END';
Index: lib/Foo.pm
===================================================================
--- lib/Foo.pm	(revision 100)
+++ lib/Foo.pm	(working copy)
@@ -1,3 +1,4 @@
 package Foo;
+use strict;
END

    ok(Claude::Agent::Code::Review::_is_diff_content($svn_diff),
       'detects svn diff format');
};

subtest '_is_diff_content - standard diff command' => sub {
    my $standard_diff = <<'END';
diff -u old.pm new.pm
--- old.pm
+++ new.pm
@@ -1 +1,2 @@
 foo
+bar
END

    ok(Claude::Agent::Code::Review::_is_diff_content($standard_diff),
       'detects standard diff -u format');
};

subtest '_is_diff_content - not a diff' => sub {
    ok(!Claude::Agent::Code::Review::_is_diff_content(''),
       'empty string is not diff');

    ok(!Claude::Agent::Code::Review::_is_diff_content('short'),
       'short string is not diff');

    ok(!Claude::Agent::Code::Review::_is_diff_content("package Foo;\nuse strict;\n1;\n"),
       'perl code is not diff');

    ok(!Claude::Agent::Code::Review::_is_diff_content("lib/Foo.pm"),
       'file path is not diff');

    # Text containing diff-like markers but not actual diff
    ok(!Claude::Agent::Code::Review::_is_diff_content(<<'END'),
This is a document about diffs.
--- is used for headers
+++ is also used
But this is not a real diff format.
END
       'text with diff-like markers but no hunk headers');

    ok(!Claude::Agent::Code::Review::_is_diff_content(undef),
       'undef is not diff');
};

# Test _meets_severity
subtest '_meets_severity - severity filtering' => sub {
    # All severities meet 'info' minimum
    ok(Claude::Agent::Code::Review::_meets_severity('critical', 'info'), 'critical meets info');
    ok(Claude::Agent::Code::Review::_meets_severity('high', 'info'), 'high meets info');
    ok(Claude::Agent::Code::Review::_meets_severity('medium', 'info'), 'medium meets info');
    ok(Claude::Agent::Code::Review::_meets_severity('low', 'info'), 'low meets info');
    ok(Claude::Agent::Code::Review::_meets_severity('info', 'info'), 'info meets info');

    # Only high and critical meet 'high' minimum
    ok(Claude::Agent::Code::Review::_meets_severity('critical', 'high'), 'critical meets high');
    ok(Claude::Agent::Code::Review::_meets_severity('high', 'high'), 'high meets high');
    ok(!Claude::Agent::Code::Review::_meets_severity('medium', 'high'), 'medium does not meet high');
    ok(!Claude::Agent::Code::Review::_meets_severity('low', 'high'), 'low does not meet high');
    ok(!Claude::Agent::Code::Review::_meets_severity('info', 'high'), 'info does not meet high');

    # Only critical meets 'critical' minimum
    ok(Claude::Agent::Code::Review::_meets_severity('critical', 'critical'), 'critical meets critical');
    ok(!Claude::Agent::Code::Review::_meets_severity('high', 'critical'), 'high does not meet critical');

    # Medium threshold
    ok(Claude::Agent::Code::Review::_meets_severity('critical', 'medium'), 'critical meets medium');
    ok(Claude::Agent::Code::Review::_meets_severity('high', 'medium'), 'high meets medium');
    ok(Claude::Agent::Code::Review::_meets_severity('medium', 'medium'), 'medium meets medium');
    ok(!Claude::Agent::Code::Review::_meets_severity('low', 'medium'), 'low does not meet medium');

    # Unknown severity handling
    ok(!Claude::Agent::Code::Review::_meets_severity('unknown', 'low'), 'unknown severity is skipped');
    ok(Claude::Agent::Code::Review::_meets_severity('high', 'unknown'), 'unknown minimum defaults to info');
};

# Test prompt building (basic structure checks)
subtest '_build_files_prompt structure' => sub {
    my $options = Claude::Agent::Code::Review::Options->new(
        categories  => ['bugs', 'security'],
        severity    => 'medium',
        focus_areas => ['error handling'],
    );

    my $prompt = Claude::Agent::Code::Review::_build_files_prompt(['lib/'], $options);

    like($prompt, qr/lib\//, 'prompt contains path');
    like($prompt, qr/bugs.*security|security.*bugs/, 'prompt contains categories');
    like($prompt, qr/medium/, 'prompt contains severity');
    like($prompt, qr/error handling/, 'prompt contains focus area');
    like($prompt, qr/JSON/, 'prompt mentions JSON response');
};

subtest '_build_diff_prompt structure' => sub {
    my $options = Claude::Agent::Code::Review::Options->new(
        categories => ['performance'],
        severity   => 'high',
    );

    my $diff = "diff --git a/foo.pm b/foo.pm\n+new line\n";
    my $prompt = Claude::Agent::Code::Review::_build_diff_prompt($diff, $options);

    like($prompt, qr/diff/, 'prompt contains diff');
    like($prompt, qr/performance/, 'prompt contains category');
    like($prompt, qr/high/, 'prompt contains severity');
    like($prompt, qr/```diff/, 'prompt wraps diff in code block');
};

subtest '_build_files_prompt multiple paths' => sub {
    my $options = Claude::Agent::Code::Review::Options->new();
    my $prompt = Claude::Agent::Code::Review::_build_files_prompt(
        ['lib/', 'bin/app.pl', 't/'],
        $options
    );

    like($prompt, qr/lib\//, 'contains first path');
    like($prompt, qr/bin\/app\.pl/, 'contains second path');
    like($prompt, qr/t\//, 'contains third path');
};

subtest '_build_files_prompt no focus areas' => sub {
    my $options = Claude::Agent::Code::Review::Options->new(
        focus_areas => [],
    );

    my $prompt = Claude::Agent::Code::Review::_build_files_prompt(['lib/'], $options);

    unlike($prompt, qr/Pay special attention/, 'no focus areas section when empty');
};

# Test system prompt generation
subtest '_get_system_prompt structure' => sub {
    my $options = Claude::Agent::Code::Review::Options->new(
        categories  => ['security', 'bugs'],
        focus_areas => ['input validation'],
    );

    my $prompt = Claude::Agent::Code::Review::_get_system_prompt($options);

    like($prompt, qr/expert code reviewer/, 'mentions expert reviewer');
    like($prompt, qr/security.*bugs|bugs.*security/, 'contains categories');
    like($prompt, qr/input validation/, 'contains focus area');
    like($prompt, qr/critical.*high.*medium.*low.*info/s, 'contains severity definitions');
    like($prompt, qr/SYSTEMATIC/, 'mentions systematic approach');
};

# Test review schema structure
subtest '_get_review_schema structure' => sub {
    my $schema = Claude::Agent::Code::Review::_get_review_schema();

    is(ref($schema), 'HASH', 'schema is hashref');
    is($schema->{type}, 'object', 'schema type is object');

    ok(exists $schema->{properties}{summary}, 'has summary property');
    ok(exists $schema->{properties}{issues}, 'has issues property');
    ok(exists $schema->{properties}{metrics}, 'has metrics property');

    is($schema->{properties}{issues}{type}, 'array', 'issues is array');

    my $issue_props = $schema->{properties}{issues}{items}{properties};
    ok(exists $issue_props->{severity}, 'issue has severity');
    ok(exists $issue_props->{category}, 'issue has category');
    ok(exists $issue_props->{file}, 'issue has file');
    ok(exists $issue_props->{line}, 'issue has line');
    ok(exists $issue_props->{description}, 'issue has description');

    # Check enums
    is_deeply($issue_props->{severity}{enum},
              ['critical', 'high', 'medium', 'low', 'info'],
              'severity enum values');
    is_deeply($issue_props->{category}{enum},
              ['bugs', 'security', 'style', 'performance', 'maintainability'],
              'category enum values');

    # Check required fields
    my $required = $schema->{properties}{issues}{items}{required};
    is_deeply([sort @$required],
              [sort qw(severity category file line description)],
              'issue required fields');
};

done_testing();
