use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More 0.98;

use App::CpanfileSlipstop::Resolver;

subtest simple => sub {
    my $resolver = App::CpanfileSlipstop::Resolver->new(
        cpanfile => test_cpanfile('simple'),
        snapshot => test_snapshot('simple'),
    );

    $resolver->read_cpanfile_requirements;
    $resolver->merge_snapshot_versions('exact_version', 0);

    is $resolver->get_version_range('DateTime'), '== 1.50';
    is $resolver->get_version_range('JSON::XS'), '== 3.04';
    is $resolver->get_version_range('Data::Printer'), '== 0.40';
    is $resolver->get_version_range('Test::More'), undef;

    # The version of core module is depends on interpreter version. So it's not fiexed.
    $resolver->merge_snapshot_versions('exact_version', 1);
    like $resolver->get_version_range('Test::More'), qr/\A== /;
};

subtest indent => sub {
    my $resolver = App::CpanfileSlipstop::Resolver->new(
        cpanfile => test_cpanfile('indent'),
        snapshot => test_snapshot('indent'),
    );

    $resolver->read_cpanfile_requirements;
    $resolver->merge_snapshot_versions('add_minimum', 0);

    is $resolver->get_version_range('DateTime'), '1.50';
    is $resolver->get_version_range('JSON::XS'), '3.04';
    is $resolver->get_version_range('Data::Printer'), '0.40';
    is $resolver->get_version_range('Test::More'), undef;
};

subtest phases => sub {
    my $resolver = App::CpanfileSlipstop::Resolver->new(
        cpanfile => test_cpanfile('phases'),
        snapshot => test_snapshot('phases'),
    );

    $resolver->read_cpanfile_requirements;
    $resolver->merge_snapshot_versions('add_maximum', 0);

    is $resolver->get_version_range('DateTime'), '<= 1.50';
    is $resolver->get_version_range('JSON::XS'), '<= 3.04';
    is $resolver->get_version_range('Data::Printer'), '<= 0.40';
    is $resolver->get_version_range('Test::More'), undef;
};

subtest types => sub {
    my $resolver = App::CpanfileSlipstop::Resolver->new(
        cpanfile => test_cpanfile('types'),
        snapshot => test_snapshot('types'),
    );

    $resolver->read_cpanfile_requirements;
    $resolver->merge_snapshot_versions('add_minimum', 0);

    is $resolver->get_version_range('DateTime'), '1.50';
    is $resolver->get_version_range('JSON::XS'), undef;
    is $resolver->get_version_range('Data::Printer'), undef;
    is $resolver->get_version_range('Test::More'), '0.99';
};

subtest versioned => sub {
    my $resolver = App::CpanfileSlipstop::Resolver->new(
        cpanfile => test_cpanfile('versioned'),
        snapshot => test_snapshot('versioned'),
    );

    $resolver->read_cpanfile_requirements;
    is $resolver->get_version_range('DateTime'), undef;
    is $resolver->get_version_range('JSON::XS'), 3.00;
    is $resolver->get_version_range('Data::Printer'), '== 0.38';
    is $resolver->get_version_range('Test::More'), '> 0.9, < 1.0, != 0.98';

    $resolver->merge_snapshot_versions('add_minimum', 0);
    is $resolver->get_version_range('DateTime'), '1.50';             # inserted installed version as minimum
    is $resolver->get_version_range('JSON::XS'), '3.04';             # updated installed version as minimum
    is $resolver->get_version_range('Data::Printer'), '== 0.38';     # not changed
    is $resolver->get_version_range('Test::More'), '>= 0.99, < 1.0'; # udpate and merged minimum version
};

done_testing;
