use strict;
use warnings;

use Test::More;

use_ok('Captive::Portal');

my ( $capo );

ok( $capo = Captive::Portal->new( cfg_file => 't/etc/ok.pl' ),
    'successfull parse t/etc/ok.pl' );

my ($cmds, $template, $tmpl_vars) ;
$tmpl_vars = {
    IDLE_TIME => $capo->cfg->{IDLE_TIME},
    %{ $capo->cfg->{IPTABLES} },
    ipv4_aton => $capo->can('ipv4_aton'),
};

foreach my $template (
    qw( firewall/flush.tt
    firewall/flush_capo_sessions.tt
    firewall/filter.tt
    firewall/init.tt
    firewall/mangle.tt
    firewall/nat.tt )
  )
{
    ok( $capo->{template}->process( $template, $tmpl_vars, \$cmds ),
        "rendering $template" );
}

# check error if some config values are missing
$tmpl_vars = {
    IDLE_TIME => $capo->cfg->{IDLE_TIME},
    %{ $capo->cfg->{IPTABLES} },
    ipv4_aton => $capo->can('ipv4_aton'),
};
delete $tmpl_vars->{IDLE_TIME};

$template = 'firewall/init.tt';
is( $capo->{template}->process( $template, $tmpl_vars, \$cmds ), undef,
    "rendering $template without IDLE_TIME throws error" );

$tmpl_vars = {
    IDLE_TIME => $capo->cfg->{IDLE_TIME},
    %{ $capo->cfg->{IPTABLES} },
    ipv4_aton => $capo->can('ipv4_aton'),
};

delete $tmpl_vars->{open_services};
$template = 'firewall/init.tt';
is( $capo->{template}->process( $template, $tmpl_vars, \$cmds ), undef,
    "rendering $template without open_services throws error" );

$tmpl_vars = {
    IDLE_TIME => $capo->cfg->{IDLE_TIME},
    %{ $capo->cfg->{IPTABLES} },
    ipv4_aton => $capo->can('ipv4_aton'),
};

delete $tmpl_vars->{open_clients};
$template = 'firewall/init.tt';
is( $capo->{template}->process( $template, $tmpl_vars, \$cmds ), undef,
    "rendering $template without open_clients throws error" );

$tmpl_vars = {
    IDLE_TIME => $capo->cfg->{IDLE_TIME},
    %{ $capo->cfg->{IPTABLES} },
    ipv4_aton => $capo->can('ipv4_aton'),
};

delete $tmpl_vars->{open_servers};
$template = 'firewall/init.tt';
is( $capo->{template}->process( $template, $tmpl_vars, \$cmds ), undef,
    "rendering $template without open_servers throws error" );

$tmpl_vars = {
    IDLE_TIME => $capo->cfg->{IDLE_TIME},
    %{ $capo->cfg->{IPTABLES} },
    ipv4_aton => $capo->can('ipv4_aton'),
};
delete $tmpl_vars->{open_networks};
$template = 'firewall/init.tt';
is( $capo->{template}->process( $template, $tmpl_vars, \$cmds ), undef,
    "rendering $template without open_networks throws error" );


done_testing();

