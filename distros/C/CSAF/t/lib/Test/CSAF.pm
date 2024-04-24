package Test::CSAF;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

use CSAF;
use CSAF::Validator::MandatoryTests;
use CSAF::Validator::OptionalTests;
use Test::More;

our @EXPORT_OK = qw(base_csaf_security_advisory exec_validator_mandatory_test exec_validator_optional_test);

sub base_csaf_security_advisory {

    my $csaf = CSAF->new;

    $csaf->document->title('Base CSAF Document');
    $csaf->document->category('csaf_security_advisory');
    $csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

    my $tracking = $csaf->document->tracking(
        id                   => 'CSAF:2023-001',
        status               => 'final',
        version              => '1.0.0',
        initial_release_date => 'now',
        current_release_date => 'now'
    );

    $tracking->revision_history->add(date => 'now', summary => 'First release', number => '1');

    return $csaf;

}

sub exec_validator_optional_test {

    my ($csaf, $test_id) = @_;

    my $v = CSAF::Validator::OptionalTests->new($csaf);
    $v->exec_test($test_id);

    foreach my $message (@{$v->messages}) {

        is($message->code, $test_id, "Message code: $test_id");
        isa_ok($message, 'CSAF::Validator::Message');

        diag($message);

    }

}

sub exec_validator_mandatory_test {

    my ($csaf, $test_id) = @_;

    my $v = CSAF::Validator::MandatoryTests->new($csaf);
    $v->exec_test($test_id);

    foreach my $message (@{$v->messages}) {

        is($message->code, $test_id, "Message code: $test_id");
        isa_ok($message, 'CSAF::Validator::Message');

        diag($message);

    }

}

1;
