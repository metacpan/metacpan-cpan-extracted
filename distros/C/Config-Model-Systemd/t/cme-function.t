# -*- cperl -*-
use strict;
use warnings;
use English;
use Path::Tiny;

use Test::More;
use Test::File::Contents;
use Config::Model qw/cme/;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

if ($OSNAME eq 'solaris' ) {
    plan skip_all => "Test irrelevant on $OSNAME";
    exit;
}

my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir;

my $systemd_file = $wr_root->child('test.service');

subtest 'create file from scratch' => sub {

    my $instance = cme(
        application => 'systemd-service-file',
        config_file => $systemd_file->basename,
        root_dir => $wr_root->stringify
    );

    ok($instance, "systemd-service instance created");

    $instance->modify('Unit Description="test single unit"');
    # test minimal modif (re-order)
    $instance->save(force => 1);
    ok(1,"data saved");

    file_contents_like($systemd_file->stringify, qr/test single unit/,"saved file ok");
};

subtest 'read file with basename' => sub {
    my $instance = cme(
        application => 'systemd-service-file',
        config_file => $systemd_file->basename,
        root_dir => $wr_root->stringify
    );

    is($instance->grab_value('Unit Description'),"test single unit","read file ok");
};

subtest 'read file with service suffix' => sub {
    my $instance = cme(
        application => 'systemd-service-file',
        config_file => $systemd_file,
        root_dir => $wr_root->stringify
    );

    is($instance->grab_value('Unit Description'),"test single unit","read file ok");
};

done_testing();

