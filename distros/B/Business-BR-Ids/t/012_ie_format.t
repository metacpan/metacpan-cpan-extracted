
use Test::More tests => 14;
BEGIN { use_ok('Business::BR::IE', 'format_ie') };

is(format_ie('ac', '00 000 000 000 99'), '00.000.000/000-99', 'IE/AC formatting works');

is(format_ie('al', '00:000:000:9'), '00.000.000-9', 'formatting IE/AL ok');

is(format_ie('ap', '030123459'), '03.012.345-9', 'formatting IE/AP ok');

is(format_ie('am', '111111110'), '11.111.111-0', 'formatting IE/AM ok');

is(format_ie('ba', '12345663'), '123456-63', 'formatting IE/BA ok');

is(format_ie('ma', '0 0 1 1 1 2 2 2 3'), '00.111.222-3', 'formatting IE/MA ok');

is( format_ie('mg', '0623079040081'), '062.307.904/0081', 'formatting IE/MG ok' );

is(format_ie('ro', '72684661768256'), '7268466176825-6', 'formatting IE/RO ok');

is(format_ie('rr', '24008266-8'), '24.008.266-8', 'formatting IE/RR ok');

is(format_ie('sp','000000000000'), '000.000.000.000', 'works ok');
is(format_ie('sp', 6688822200), '006.688.822.200', 'works even for short ints');

is(format_ie('sp', '000#000@000~000'), '000.000.000.000', 'argument is flattened before formatting');

is(format_ie('sp', '1234567890123'), '123.456.789.012', 'only 1st 12 digits matter for long inputs');


