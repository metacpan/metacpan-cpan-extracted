use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 7;
use CLDR::Number;

my $cldr = CLDR::Number->new;
my $decf = $cldr->decimal_formatter(locale => 'en');

$decf->pattern("'foo'");  is $decf->format(123), 'foo';
$decf->pattern("'#'");    is $decf->format(123), '#';
$decf->pattern("'#");     is $decf->format(123), '#';
$decf->pattern("#'#'");   is $decf->format(123), '123#';
$decf->pattern("#'#");    is $decf->format(123), '123#';
$decf->pattern("''#''");  is $decf->format(123), "'123'";
$decf->pattern("'#''#'"); is $decf->format(123), "#'#";
