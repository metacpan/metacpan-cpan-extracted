use strict;
use warnings;

use Test::More tests => 80;

use CPE;

my @attributes = qw(
    cpe_version  part  vendor  product  version  update  edition
    language  sw_edition  target_sw  target_hw  other
);

test_empty_object();
test_from_uri();
exit;

sub test_empty_object {
    ok my $cpe = CPE->new, 'empty object';
    isa_ok $cpe, 'CPE';
    can_ok $cpe, @attributes, qw(
        is_equal is_subset is_superset is_disjoint
        as_string  as_wfn
    );

    foreach my $method (@attributes) {
        is(
            $cpe->$method,
            $method eq 'cpe_version' ? '2.3' : 'ANY',
            "$method from empty"
        );
    }
}

sub test_from_uri {
    # NISTIR 7695 URI examples:
    my %tests_from_uri = (
        '6.1.2.4.1 (Example 1)' => {
            uri => 'cpe:/a:microsoft:internet_explorer:8.0.6001:beta',
            cpe_version => '2.3',
            part => 'a',
            vendor => 'microsoft',
            product => 'internet_explorer',
            version => '8.0.6001',
            update => 'beta',
            edition => 'ANY',
            language => 'ANY',
            sw_edition => 'ANY',
            target_sw => 'ANY',
            target_hw => 'ANY',
            other => 'ANY',
        },
        '6.1.2.4.2 (Example 2)' => {
            uri => 'cpe:/a:microsoft:internet_explorer:8.%02:sp%01',
            cpe_version => '2.3',
            part => 'a',
            vendor => 'microsoft',
            product => 'internet_explorer',
            version => '8.*',
            update => 'sp?',
            edition => 'ANY',
            language => 'ANY',
            sw_edition => 'ANY',
            target_sw => 'ANY',
            target_hw => 'ANY',
            other => 'ANY',
        },
        '6.1.2.4.3 (Example 3)' => {
            uri => 'cpe:/a:hp:insight_diagnostics:7.4.0.1570:-:~~online~win2003~x64~',
            cpe_version => '2.3',
            part => 'a',
            vendor => 'hp',
            product => 'insight_diagnostics',
            version => '7.4.0.1570',
            update => 'NA',
            edition => 'ANY',
            language => 'ANY',
            sw_edition => 'online',
            target_sw => 'win2003',
            target_hw => 'x64',
            other => 'ANY',
        },
        '6.1.2.4.4 (Example 4)' => {
            uri => 'cpe:/a:hp:openview_network_manager:7.51::~~~linux~~',
            cpe_version => '2.3',
            part => 'a',
            vendor => 'hp',
            product => 'openview_network_manager',
            version => '7.51',
            update => 'ANY',
            edition => 'ANY',
            language => 'ANY',
            sw_edition => 'ANY',
            target_sw => 'linux',
            target_hw => 'ANY',
            other => 'ANY',
        },
        '6.1.2.4.5 (Example 5)' => {
            uri => 'cpe:/a:foo%5cbar:big%24money_manager_2010:::~~special~ipod_touch~80gb~',
            cpe_version => '2.3',
            part => 'a',
            vendor => 'foo\\\\bar',
            product => 'big\\$money_manager_2010',
            version => 'ANY',
            update => 'ANY',
            edition => 'ANY',
            language => 'ANY',
            sw_edition => 'special',
            target_sw => 'ipod_touch',
            target_hw => '80gb',
            other => 'ANY',
        },
    );
    foreach my $label (keys %tests_from_uri) {
        my $data = $tests_from_uri{$label};
        ok my $cpe = CPE->new( delete $data->{uri} )
            => "able to create object from URI ($label)";

        foreach my $method (keys %$data) {
            is(
                $cpe->$method,
                $data->{$method},
                "$method from uri ($label)"
            );
        }
    }
}
