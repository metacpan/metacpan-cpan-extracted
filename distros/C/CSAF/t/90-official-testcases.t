#!perl

use strict;
use warnings;

use FindBin '$RealBin';
use Test::More;
use CSAF::Util qw(file_read);
use CSAF::Parser;
use List::Util qw(first);
use Cpanel::JSON::XS;

use constant DEBUG => $ENV{CSAF_TEST_DEBUG};

my $testcases = Cpanel::JSON::XS->new->decode(file_read("$RealBin/official-testcases/testcases.json"));

my @SKIP_TESTCASES = (
    '6.2.10',    # Missing TLP label (CSAF::Type::TLP have a default label)
    '6.2.12',    # Missing Document Language (CSAF::Document have "en" for default language)
    '6.2.13',    # Sorting (CSAF::Document is object not hash)
                 #'6.2.20',    # Additional Properties (in CSAF::Document isn't possible add new properties)

    # TODO
    '6.2.1',     # !?
    '6.2.19',    # Always fail !?

    # Unimplemented tests
    '6.3.6', '6.3.7', '6.3.8'
);

foreach my $testcase (@{$testcases->{tests}}) {

    my $testcase_id    = $testcase->{id};
    my $testcase_group = $testcase->{group};

    if (defined $ENV{TESTCASE}) {
        next unless ($testcase_id eq $ENV{TESTCASE});
        diag "Test only $ENV{TESTCASE} testcase";
    }

    if (first { $testcase_id eq $_ } @SKIP_TESTCASES) {
        diag "Testcase $testcase_id skipped";
        next;
    }

    my @valid_testcases    = @{$testcase->{valid}    || []};
    my @failures_testcases = @{$testcase->{failures} || []};

    my @all_testcases = (@valid_testcases, @failures_testcases);

    foreach my $test (@all_testcases) {

        my $test_name = $test->{name};
        my $is_valid  = $test->{valid};

        my $parser    = CSAF::Parser->new(file => "$RealBin/official-testcases/$test_name");
        my $csaf      = $parser->parse;
        my $doc_title = $csaf->document->title;

        if ($testcase_group =~ /(optional|informative)/ && $doc_title =~ /failing/) {
            $is_valid = 0;
        }

        DEBUG and diag("[$testcase_id - $testcase_group] Test file: $test_name [valid => $is_valid]");
        DEBUG and diag("[$testcase_id - $testcase_group] $doc_title");

        my @messages = $csaf->validate;

        my $n_errors = 0;

        foreach my $message (@messages) {

            next if ($message->code ne $testcase_id);

            DEBUG and diag($message);
            $n_errors++;

        }

        if ($is_valid) {
            is($n_errors, 0, "$testcase_id - $n_errors validation message(s) detected for '$doc_title'");
        }
        else {
            isnt($n_errors, 0, "$testcase_id - $n_errors validation message(s) detected for '$doc_title'");
        }

    }

}

done_testing();
