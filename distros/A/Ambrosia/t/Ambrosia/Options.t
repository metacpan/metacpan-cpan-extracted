#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

use lib qw(lib t ..);
use Carp;

use Data::Dumper;

BEGIN {
    use_ok( 'Ambrosia::CommonGatewayInterface::Options' ); #test #1
}

sub opt_check
{
    my $options_spec = shift;
    my $opt = shift;
    my $param = shift;
    my $val = shift;
    local @ARGV = @$opt;
    my $o = new Ambrosia::CommonGatewayInterface::Options(options_spec=>$options_spec);
    $o->open();
    ok($o->input_data($param) eq $val, "input_data: $param == $val");
}

my $options_spec = [
    'test.pl %o',
    [ 'data|d=s',   'the path to xml' ],
    [ 'config_path|c=s',   'the path to config' ],
    [ 'install_path|p=s',  'the path where project building' ],
    [ 'action|a=s', "what to do:\n\t\tdb2xml - make xml from data base structure;\n\t\txml2app - make schema of application" ],
    [ 'help',       'print usage message and exit' ],
];

my $o = new Ambrosia::CommonGatewayInterface::Options( options_spec => $options_spec );

ok($o->open(), 'opened');
ok($o->output_data() eq '', 'empty output data');

opt_check($options_spec, ['-d', '/lib/Ambrosia/data'], 'data', '/lib/Ambrosia/data');
opt_check($options_spec, ['--data', '/lib/Ambrosia/data'], 'data', '/lib/Ambrosia/data');

opt_check($options_spec, ['-c', '/lib/Ambrosia/config_path'], 'config_path', '/lib/Ambrosia/config_path');
opt_check($options_spec, ['--config_path', '/lib/Ambrosia/config_path'], 'config_path', '/lib/Ambrosia/config_path');

opt_check($options_spec, ['--help'], 'help', '1');

