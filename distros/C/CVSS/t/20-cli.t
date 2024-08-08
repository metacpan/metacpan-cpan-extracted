#!perl -T

use strict;
use warnings;

use Test::More;
use JSON::PP qw(decode_json);

use App::CVSS;

sub cmd {

    my ($class, @arguments) = @_;

    my $output;

    open(my $output_handle, '>', \$output) or die "Can't open handle file: $!";
    my $original_handle = select $output_handle;

    $class->run(@arguments);
    chomp $output;

    select $original_handle;

    return $output;

}

my $vector_string = 'CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H';

subtest "App::CVSS - '$vector_string' (JSON output)" => sub {

    my $test_1 = cmd('App::CVSS', $vector_string, '--json');
    ok($test_1, 'Parse CVSS vector string and encode in JSON');

    my $test_2 = eval { decode_json($test_1) };

    ok($test_2, 'Valid JSON output');
    is($test_2->{vectorString}, $vector_string, 'Vector String');
    is($test_2->{baseSeverity}, 'HIGH',         'Base Severity');
    is($test_2->{baseScore},    '7.4',          'Base Score');

};

subtest "App::CVSS - '$vector_string' (XML output)" => sub {

    my $test_1 = cmd('App::CVSS', $vector_string, '--xml');
    ok($test_1, 'Parse CVSS vector and encode in XML');

    like($test_1, qr{<base-score>7.4</base-score>},        'Base Score');
    like($test_1, qr{<base-severity>HIGH</base-severity>}, 'Base Severity');

};

done_testing();
