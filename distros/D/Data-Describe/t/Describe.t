# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More qw(no_plan);

use Data::Describe;
my $dsp = Data::Describe->new; 
ok( defined $dsp,                'new() returned something' );
ok( $dsp->isa('Data::Describe'), "  and it's the right class" );

# test debug and echoMSG methods
ok($dsp->can('debug'),      'debug: can' );        # method exist?
is($dsp->debug,   undef,    '  debug()'      );    # check default
$dsp->debug(2);                                    # assign new value
is($dsp->debug,       2,    '  debug(2)'     );    # check new value

ok($dsp->can('echoMSG'),    'echoMSG: can' );      # method exist?
like($dsp->echoMSG('A test',"",1), qr/test/, '  echoMSG($msg)' );

# test get_ifn and input_file_name methods
ok($dsp->get_ifn==undef,    'get_ifn()'    );      # check default
ok($dsp->can('get_ifn'),    '  get_ifn: can');     # test the method
$dsp->set_ifn('xxx');                              # assign new value
is($dsp->get_ifn, 'xxx',  "  get_ifn('xxx')");     # check new value
$dsp->input_file_name(undef);                      # set to default
ok($dsp->can('input_file_name'), '  input_file_name: can');
is($dsp->input_file_name, undef,   "  input_file_name()"); 

# test get_ofn and output_file_name methods
ok($dsp->get_ofn==undef,    'get_ofn()'    );      # check default
ok($dsp->can('get_ofn'),    '  get_ofn: can');     # test the method
$dsp->set_ofn('xxx');                              # assign new value
is($dsp->get_ofn, 'xxx',  "  get_ofn('xxx')");     # check new value
$dsp->output_file_name(undef);                     # set to default
ok($dsp->can('output_file_name'), '  output_file_name: can');
is($dsp->output_file_name, undef,   "  output_file_name()"); 

# test get_ifs and input_field_separator methods
ok($dsp->get_ifs=='|',      'get_ifs()'    );      # check default
ok($dsp->can('get_ifs'),    '  get_ifs: can');     # test the method
$dsp->set_ifs('\t');                               # assign new value
is($dsp->get_ifs,  '\t',    "  get_ifs(tab)");     # check new value
$dsp->input_field_separator('|');                  # set to default
ok($dsp->can('input_field_separator'), '  input_field_separator: can');
is($dsp->input_field_separator, '|',   "  input_field_separator()"); 

# test get_ofs and output_field_separator methods
ok($dsp->get_ofs=='|',      'get_ofs()'    );      # check default
ok($dsp->can('get_ofs'),    '  get_ofs: can');     # test the method
$dsp->set_ofs(',');                                # assign new value
is($dsp->get_ofs,  ',',     "  get_ofs(',')");     # check new value
$dsp->output_field_separator('|');                 # set to default
ok($dsp->can('output_field_separator'),'  output_field_separator: can');
is($dsp->output_field_separator, '|',   "  output_field_separator()"); 

# test get_sfr and skip_first_row methods
is($dsp->get_sfr, 1,     'get_sfr()'    );         # check default
ok($dsp->can('get_sfr'),    '  get_sfr: can');     # test the method
$dsp->set_sfr(0);                                  # assign new value
is($dsp->get_sfr,  0,       "  get_sfr(0)");       # check new value
$dsp->skip_first_row(1);                           # set to default
ok($dsp->can('skip_first_row'),'  skip_first_row: can');
is($dsp->skip_first_row, 1, "  skip_first_row()"); 

# test _def_arrayref and _dat_arrayref methods
my @a = <DATA>;
# my $arf = \[[1,3,5],[2,4,6],[3,5,7],[4,6,8]];
my $arf = \@a;
ok($dsp->get_def_arrayref==undef, 
   'get_def_arrayref()');                          # check default
ok($dsp->can('get_def_arrayref'), 
   '  get_def_arrayref: can');                     # test the method
$dsp->{_def_arrayref} = $arf;                      # assign new value
is($dsp->get_def_arrayref,  $arf, 
   '  get_def_arrayref($arf)');                    # check new value

ok($dsp->get_dat_arrayref==undef, 
   'get_dat_arrayref()');                          # check default
ok($dsp->can('get_dat_arrayref'), 
   '  get_dat_arrayref: can');                     # test the method
$dsp->{_dat_arrayref} = $arf;                      # assign new value
is($dsp->get_dat_arrayref,  $arf, 
   '  get_dat_arrayref($arf)');                    # check new value

# $dsp->get_date_format('1:12','1:31','1:2000');
ok($dsp->can('get_date_format'), 'get_date_format()'); 

# test describe method
ok($dsp->can('describe'), 'describe: can');        # test the method
is($#a, $#{$arf},  '  data array length');     
my %attr = (debug=>0, sfr=>1, ifs=>','); 
$dsc = Data::Describe->new(%attr); 
$dsc->describe($arf);
my $crf = $dsc->get_def_arrayref;
my $drf = $dsc->get_dat_arrayref;
$dsc->output($crf, "", 'def'); 
print "#\n# Data records\n";
$dsc->output($drf, "", 'dat'); 

1;

__DATA__
Name,      Age,        DOB, Weight, Height 
Joe Smith,  34,  1966/1/25,  245.2,   5.11
Jon Harley, 30,  1970/12/3,  189.1,   5.11
Monica Lee, 18,  1982/3/24,  105.8,   4.09
Neo Party,  23, 1977/11/28,  215.5,   6.01
Bill Hans,  45, 1955/12/26,  175.5,   6.10

