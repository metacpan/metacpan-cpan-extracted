# -*- perl -*-

# t/004_basic.t - check basic stuff

use strict;
use warnings;
no warnings qw(once);

use Test::More tests => 19;
use Test::NoWarnings;

use_ok( 'DateTime::Format::CLDR' );

my $cldr = DateTime::Format::CLDR->new(
    locale  => 'de_AT',
);

is($cldr->incomplete,1,'incomplete accessor');
is($cldr->on_error,'undef','on_error accessor');
isa_ok($cldr,'DateTime::Format::CLDR');
like($cldr->locale->id,qr/de[_\-]AT/,'DateTime::Locale id is de-AT');
isa_ok($cldr->time_zone,'DateTime::TimeZone::Floating');

$cldr->time_zone(DateTime::TimeZone::UTC->new);

isa_ok($cldr->time_zone,'DateTime::TimeZone::UTC','Timezone has been set');

$cldr->locale(DateTime::Locale->load( 'de_DE' ));

like($cldr->locale->id,qr/de[_\-]DE/,'Locale has been set');

like($cldr->pattern,qr/dd.MM.y(?:yyy){0,1}/,'Pattern set ok');

my $datetime = $cldr->parse_datetime('22.11.2011');

isa_ok($datetime,'DateTime');
is($datetime->dmy,'22-11-2011','String has been parsed');
isa_ok($datetime->time_zone,'DateTime::TimeZone::UTC','String has correct timezone');
like($datetime->locale->id,qr/de[_\-]DE/,'Locale has been set');

$cldr->pattern('dd.MMMM.yyyy');

is($cldr->pattern,'dd.MMMM.yyyy','Pattern has been set');

my $datetime2 = $cldr->parse_datetime('22.November.2011');

is($datetime2->dmy('.'),'22.11.2011','Parsing works');

is($cldr->format_datetime(DateTime->new( year => 2011, day => 22, month => 11)),'22.November.2011','Formating works');

my $cldr2 = DateTime::Format::CLDR->new(
    locale      => 'de_AT',
    time_zone   => 'Europe/Vienna',
    pattern     => 'dd/MM (yyyy)'
);

my $datetime3 = $cldr2->parse_datetime('22/11 (2011)');

is($datetime3->dmy('.'),'22.11.2011','Parsing works');
is($cldr2->format_datetime(DateTime->new( year => 2011, day => 22, month => 11)),'22/11 (2011)','Formating works');