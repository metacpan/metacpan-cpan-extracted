#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny;

use_ok('Claude::Agent::Code::Review::Perlcritic');
use_ok('Claude::Agent::Code::Review::Options');

# Test is_available
subtest 'is_available' => sub {
    my $available = Claude::Agent::Code::Review::Perlcritic->is_available;
    ok(defined $available, 'is_available returns defined value');
    # Result depends on whether Perl::Critic is installed
    diag("Perl::Critic available: " . ($available ? 'yes' : 'no'));
};

# Skip remaining tests if Perl::Critic is not available
SKIP: {
    skip "Perl::Critic not installed", 1
        unless Claude::Agent::Code::Review::Perlcritic->is_available;

    my $tempdir = tempdir(CLEANUP => 1);
    my $orig_dir = path('.')->realpath;

    subtest 'analyze clean file' => sub {
        chdir($tempdir);

        my $clean_file = path($tempdir, 'clean.pm');
        $clean_file->spew_utf8(<<'END');
package Clean;

use strict;
use warnings;

sub greet {
    my ($name) = @_;
    return "Hello, $name!";
}

1;
END

        my $options = Claude::Agent::Code::Review::Options->new(
            perlcritic          => 1,
            perlcritic_severity => 5,  # Gentle - should find few/no issues
        );

        my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
            paths   => ['clean.pm'],
            options => $options,
        );

        # With gentle severity, a clean file should have few issues
        diag("Found " . scalar(@issues) . " issues in clean file at severity 5");
        ok(1, 'analyze completed without error');

        chdir($orig_dir);
    };

    subtest 'analyze file with issues' => sub {
        chdir($tempdir);

        my $messy_file = path($tempdir, 'messy.pm');
        $messy_file->spew_utf8(<<'END');
package messy;
# Missing strict and warnings
$x = 1;  # Undeclared variable
sub foo{return 1}  # Style issues
END

        my $options = Claude::Agent::Code::Review::Options->new(
            perlcritic          => 1,
            perlcritic_severity => 1,  # Brutal - find everything
        );

        my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
            paths   => ['messy.pm'],
            options => $options,
        );

        ok(scalar(@issues) > 0, 'found issues in messy file');
        diag("Found " . scalar(@issues) . " issues in messy file at severity 1");

        # Check issue structure
        if (@issues) {
            my $issue = $issues[0];
            isa_ok($issue, 'Claude::Agent::Code::Review::Issue');
            ok($issue->file, 'issue has file');
            ok($issue->line, 'issue has line');
            ok($issue->description, 'issue has description');
            like($issue->explanation, qr/Perl::Critic policy/, 'explanation mentions policy');
        }

        chdir($orig_dir);
    };

    subtest 'analyze directory' => sub {
        chdir($tempdir);

        my $subdir = path($tempdir, 'lib');
        $subdir->mkpath;

        my $file1 = path($subdir, 'One.pm');
        $file1->spew_utf8(<<'END');
package One;
use strict;
use warnings;
1;
END

        my $file2 = path($subdir, 'Two.pm');
        $file2->spew_utf8(<<'END');
package Two;
use strict;
use warnings;
1;
END

        my $options = Claude::Agent::Code::Review::Options->new(
            perlcritic          => 1,
            perlcritic_severity => 5,
        );

        my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
            paths   => ['lib'],
            options => $options,
        );

        ok(defined \@issues, 'analyze directory completed');
        diag("Found " . scalar(@issues) . " issues in lib/ directory");

        chdir($orig_dir);
    };

    subtest 'severity mapping' => sub {
        chdir($tempdir);

        # Create files that will trigger issues at different severities
        my $test_file = path($tempdir, 'severity_test.pm');
        $test_file->spew_utf8(<<'END');
package SeverityTest;
# No strict/warnings (severity 5 = critical in our mapping)
$foo = 1;
1;
END

        my $options = Claude::Agent::Code::Review::Options->new(
            perlcritic          => 1,
            perlcritic_severity => 1,
        );

        my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
            paths   => ['severity_test.pm'],
            options => $options,
        );

        if (@issues) {
            # Check that severities are mapped to valid values
            my %valid_severities = map { $_ => 1 } qw(critical high medium low info);
            for my $issue (@issues) {
                ok($valid_severities{$issue->severity},
                   "severity '" . $issue->severity . "' is valid");
            }
        }

        chdir($orig_dir);
    };

    subtest 'category mapping' => sub {
        chdir($tempdir);

        my $test_file = path($tempdir, 'category_test.pm');
        $test_file->spew_utf8(<<'END');
package CategoryTest;
use strict;
use warnings;

# This might trigger various categories
sub complex_function {
    my $data = shift;
    if ($data) {
        if ($data->{foo}) {
            if ($data->{bar}) {
                return $data->{baz} && $data->{qux} ? 1 : 0;
            }
        }
    }
    return 0;
}

1;
END

        my $options = Claude::Agent::Code::Review::Options->new(
            perlcritic          => 1,
            perlcritic_severity => 1,
        );

        my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
            paths   => ['category_test.pm'],
            options => $options,
        );

        if (@issues) {
            my %valid_categories = map { $_ => 1 }
                qw(bugs security style performance maintainability);
            for my $issue (@issues) {
                ok($valid_categories{$issue->category},
                   "category '" . $issue->category . "' is valid");
            }
        }

        chdir($orig_dir);
    };

    subtest 'path traversal protection' => sub {
        chdir($tempdir);

        my $options = Claude::Agent::Code::Review::Options->new(
            perlcritic => 1,
        );

        # Try to analyze files outside project directory
        my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
            paths   => ['../../../etc/passwd'],
            options => $options,
        );

        is(scalar @issues, 0, 'path traversal blocked');

        chdir($orig_dir);
    };

    subtest 'handles parse errors gracefully' => sub {
        chdir($tempdir);

        my $broken_file = path($tempdir, 'broken.pm');
        $broken_file->spew_utf8(<<'END');
package Broken;
sub foo {
    # Unclosed brace
1;
END

        my $options = Claude::Agent::Code::Review::Options->new(
            perlcritic => 1,
        );

        # Should not die, may report error as an issue
        my @issues = eval {
            Claude::Agent::Code::Review::Perlcritic->analyze(
                paths   => ['broken.pm'],
                options => $options,
            );
        };

        ok(!$@, 'did not die on parse error');
        # May have an issue about the parse error
        diag("Parse error handling: " . scalar(@issues) . " issues returned");

        chdir($orig_dir);
    };

    subtest 'multiple file types' => sub {
        chdir($tempdir);

        # Create various Perl file types
        path($tempdir, 'script.pl')->spew_utf8("#!/usr/bin/perl\nuse strict;\nprint 1;\n");
        path($tempdir, 'module.pm')->spew_utf8("package Module;\nuse strict;\n1;\n");
        path($tempdir, 'test.t')->spew_utf8("use Test::More;\nok(1);\ndone_testing;\n");

        my $options = Claude::Agent::Code::Review::Options->new(
            perlcritic          => 1,
            perlcritic_severity => 5,
        );

        my @issues = Claude::Agent::Code::Review::Perlcritic->analyze(
            paths   => ['.'],
            options => $options,
        );

        ok(defined \@issues, 'analyzed multiple file types');
        diag("Found " . scalar(@issues) . " issues across .pl, .pm, .t files");

        chdir($orig_dir);
    };
}

done_testing();
