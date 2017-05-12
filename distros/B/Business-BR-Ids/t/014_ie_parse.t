
use Test::More tests => 14;
BEGIN { use_ok('Business::BR::IE', 'parse_ie') };

my ($base, $dv);
my $info;

($base, $dv) = parse_ie('ac', "01.004.823/001-12");
is($base, '01004823001', 'parsing IE/AC works (list context)...');
is($dv, '12', 'parsing IE/AC works (indeed)');

$info = parse_ie('ac', "01.004.823/001-12");
is_deeply($info, { base => '01004823001', dv => '12' }, 
          'parsing IE/AC works (scalar context)');

$info = parse_ie('al', "11.122.333-9");
is_deeply($info, 
          { base => '11122333', dv => '9', 
            type => 1, t_name => 'normal' }, 
          'parsing IE/AL works (scalar context)');

$info = parse_ie('am', "11.111.111-0");
is_deeply($info, { base => '11111111', dv => '0' }, 'parsing IE/AM works');

$info = parse_ie('ba', "123456-63");
is_deeply($info, { base => '123456', dv => '63' }, 'parsing IE/BA works');

$info = parse_ie('ma', "00.111.222-9");
is_deeply($info, { base => '00111222', dv => '9' }, 'parsing IE/MA works');

is_deeply( scalar parse_ie('mg', '062.307.904/0081'), 
           { municipio => '062', inscricao => '307904', ordem => '00', dv => '81' },
           'parsing IE/MG works' 
         );

$info = parse_ie('ro', "7268466176825-6");
is_deeply($info, { base => '7268466176825', dv => '6' }, 'parsing IE/RO works');

$info = parse_ie('rr', "24004145-5");
is_deeply($info, { base => '24004145', dv => '5' }, 'parsing IE/RR works');

($base, $dv) = parse_ie('pr', "123.45678-50");
is($base, '12345678', 'parsing IE/PR works (list context)...');
is($dv, '50', 'parsing IE/PR works (indeed)');

$info = parse_ie('pr', "123.45678-50");
is_deeply($info, { base => '12345678', dv => '50' }, 
          'parsing IE/PR works (scalar context)');

# SP ?
