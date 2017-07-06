# -*- cperl -*-
use strict;
use warnings;
use Path::Tiny;

use Test::More;
use Test::File::Contents;
use Config::Model qw/cme/;
use Log::Log4perl qw(:easy :levels);

my $arg = shift || '';
my ( $log, $show ) = (0) x 2;

my $trace = $arg =~ /t/ ? 1 : 0;
$log  = 1 if $arg =~ /l/;
$show = 1 if $arg =~ /s/;

my $home = $ENV{HOME} || "";
my $log4perl_user_conf_file = "$home/.log4config-model";

if ( $log and -e $log4perl_user_conf_file ) {
    Log::Log4perl::init($log4perl_user_conf_file);
}
else {
    Log::Log4perl->easy_init( $log ? $WARN : $ERROR );
}

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

# pseudo root where config files are written by config-model
my $wr_root = path('wr_root');

# cleanup before tests
$wr_root->remove_tree;
$wr_root->mkpath;

my $from_scratch_dir = $wr_root->child('from-scratch');
$from_scratch_dir->mkpath;

my $systemd_file = $from_scratch_dir->child('test.service');

subtest 'create file from scratch' => sub {

    my $instance = cme(
        application => 'systemd-service',
        config_file => $systemd_file->basename,
        root_dir => $from_scratch_dir->stringify
    );

    ok($instance, "systemd-service instance created");

    $instance->modify('Unit Description="test single unit"');
    # test minimal modif (re-order)
    $instance->save(force => 1);
    ok(1,"data saved");

    file_contents_like($systemd_file->stringify, qr/test single unit/,"saved file ok");
};

subtest 'read file' => sub {
    my $instance = cme(
        application => 'systemd-service',
        config_file => $systemd_file->basename,
        root_dir => $from_scratch_dir->stringify
    );

    is($instance->grab_value('Unit Description'),"test single unit","read file ok");
};

done_testing();

