use strict;
use warnings;
use Test::More;
use DateTime;
use DateTime::Format::Natural;
use DateTime::Format::Oracle;
use Data::Dumper;
use C600;

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI';
my $dt_from = DateTime::Format::Oracle->parse_datetime('2021-01-15 16:52');
my $dt_to = DateTime::Format::Oracle->parse_datetime('2021-01-16 16:52');
my $c600 = C600->new();

ok($c600->__list_vars == 79, "vars numbers test!");
ok($c600->get_single_value('GNPS-Huiz-M','+A',$dt_from) ne 'undef', "get single value!");
warn $c600->get_accu_value('GNPS-Huiz-M','+A',$dt_from, $dt_to);
$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
my $dt1_from = DateTime::Format::Oracle->parse_datetime('2021-06-28 14:31:23');
my $dt1_to = DateTime::Format::Oracle->parse_datetime('2021-06-29 14:31:23');
$c600->get_audit_record($dt1_from, $dt1_to);
#diag $c600->__list_meters();
#diag $c600->__list_devices();
#$c600->__store_vmmid();
done_testing();

