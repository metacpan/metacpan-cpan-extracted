# -*- cperl -*-
use strict;
use warnings;
use English;
use Path::Tiny;

use Test::More;
use Test::File::Contents;
use Test::Log::Log4perl;
use Config::Model qw/cme/;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;


my ($model, $trace) = init_test();

# pseudo root where config files are written by config-model
my $wr_root = setup_test_dir;

my $lib_systemd = $wr_root->child('lib/systemd/system/');
$lib_systemd->mkpath({mode => oct(755)});
$lib_systemd->child('transmission-daemon.service')->spew(<DATA>);

my $inst = $model->instance (
    application       => 'systemd',
    instance_name     => 'instance',
    root_dir          => $wr_root,
    backend_arg       => 'transmission-daemon',
);

ok($inst,"Created instance") ;

my $root = $inst -> config_root ;

my $dump;
{
    my $xp = Test::Log::Log4perl->expect(
        ignore_priority => "info",
        [
            'User',
            warn => qr/Loading/,
            warn => qr/Reading/,
            warn =>  qr/Unexpected systemd parameter/
        ]
    );
    $dump = $root->dump_tree (mode => 'full');
}
ok($dump,"Created dump") ;

print "First dump:\n",$dump if $trace ;

$root -> load("service:transmission-daemon Unit After:<you") ;
ok(1,"loaded data") ;

$inst->write_back;
ok(1,"wrote data back") ;

my $service_dot_d = $wr_root->child('etc/systemd/system/transmission-daemon.service.d');

file_contents_like(
    $service_dot_d->child('override.conf')->stringify,
    qr/you/,
    "override file was written",
);

$root -> load("service:transmission-daemon Unit After:-=you") ;

$inst->write_back;

ok(! $service_dot_d->child('override.conf')->exists, "unneeded file was removed");
ok(! $service_dot_d->exists, "unneeded dir was removed");

done_testing;

__END__
__DATA__

[Unit]
Description=Transmission BitTorrent Daemon
After=network.target

[Service]
User=debian-transmission
Type=notify
ExecStart=/usr/bin/transmission-daemon -f --log-error
ExecStop=/bin/kill -s STOP $MAINPID
ExecReload=/bin/kill -s HUP $MAINPID
# test conversion of on to no
NoNewPrivileges=on
# test accepted parameters
DummyParam=dummy

[Install]
WantedBy=multi-user.target
