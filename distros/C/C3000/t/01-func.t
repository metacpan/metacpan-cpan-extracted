#!perl -T
use C3000;
use Test::More;
use DateTime;
my $hl = C3000->new();

my $meter = '%';
my $meter_var  = '+A';
my $return_fields = ['ADAS_DEVICE', 'ADAS_VARIABLE', 'ADAS_DEVICE_NAME','ADAS_VARIABLE_NAME'];
my $criteria = [['ADAS_DEVICE_NAME',  $meter], ['ADAS_VARIABLE_NAME', $meter_var]];
my $rs_device;
my $rs_LP;
ok($rs_device = $hl->search_device($return_fields, $criteria), "search_device test");

my $dt = DateTime->now();
is(ref($hl->convert_VT_DATE($dt)), 'Win32::OLE::Variant', 'convert VT_DATE');
is(ref($hl->convert_VT_DATE('today')), 'Win32::OLE::Variant', 'convert VT_DATE');

$return_fields = [ 'ADAS_TIME_GMT', 'ADAS_VAL_RAW', 'ADAS_USER_STATUS'];
my $device_id = $rs_device->Fields('ADAS_DEVICE')->{Value};
my $variable_id = $rs_device->Fields('ADAS_VARIABLE')->{Value};
my $date_from  = $hl->convert_VT_DATE('yesterday');
my $date_to    = $hl->convert_VT_DATE('today');
$criteria = [['ADAS_DEVICE', $device_id], ['ADAS_VARIABLE', $variable_id], ['ADAS_TIME_GMT', $date_from, '>'], ['ADAS_TIME_GMT', $date_to, '<=']];

ok($rs_LP = $hl->get_LP($return_fields, $criteria), "get load profile");

ok(defined($hl->accu_LP('ADAS_VAL_RAW', 'º£%', '+A', 'yesterday', 'today')), "get accumulation");
ok(defined($hl->get_single_LP('ADAS_VAL_RAW', 'º£%', '+A', 'yesterday')), "get single value");

my $
ok(defined($hl->create_meter()), "create meter");
ok(defined($hl->create_virtual_meter()), "create meter");
ok(defined($hl->del_meter()), "del meter");
ok(defined($hl->del_virtual_meter()), "del virtual meter");

my $init_value = [["accountnumber", $master], ['enabled', '1']];  # you can add more initial values, please check concerned template.
ok(defined($hl->create_master_account($parent_node, $template_id, $segment_id, $init_value)), "create master account");





done_testing;
