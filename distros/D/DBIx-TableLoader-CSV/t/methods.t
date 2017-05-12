# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Test::MockObject 1.09 ();
use Symbol; # core
use lib 't/lib';
use CSVTester;

my $mod = $CSVTester::mod;

# get_raw_row()
test_with_all_csv_classes get_raw_row => sub {
  my $csv_class = shift;
  my $loader = new_ok($mod, [io => new_io(), default_column_type => 'foo', csv_class => $csv_class]);
  # columns determined from first row
  is_deeply($loader->columns, [[qw(fld1 foo)], [qw(fld2 foo)]], 'columns');
  is_deeply($loader->column_names, [qw(fld1 fld2)], 'column names');
  # get_row calls get_raw_row
  is_deeply($loader->get_raw_row, [qw(row1 col2)],     'raw row 1');
  is_deeply($loader->get_row,     [qw(row2 col2)],     'row 2');
  is_deeply($loader->get_raw_row, [qw(row3), "col 2"], 'raw row 3');
};

# default_name()
test_with_all_csv_classes default_name => sub {
  my $csv_class = shift;
  # we're basically testing File::Basename isn't necessary
  foreach my $test (
    ['/tmp/goober.csv' => 'goober'],
    ['har de har har.fudge.csv' => 'har de har har.fudge'],
    ['ahoy.tab' => 'ahoy'],
    ['' => 'csv'],
  ){
    my ($file, $exp) = @$test;
    is(new_ok($mod, [io => new_io(), file => $file, csv_class => $csv_class])->default_name, $exp, 'default_name');
  }
};

# prepare_data() options
test_with_all_csv_classes 'prepare_data() options' => sub {
  my $csv_class = shift;
  my $loader;
  my $mock = Test::MockObject->new();
  $mock->fake_module('Fake_CSV',
    new => sub { bless( ($_[1]||{}), $_[0] ) },
    getline => sub { [1] }
  );

  # csv
  $loader = new_ok($mod, [io => new_io(), csv_class => $csv_class]);
  isa_ok($loader->{csv}, $csv_class);
  my $csv = Fake_CSV->new({goo => 'ber'});
  $loader = new_ok($mod, [io => new_io(), csv => $csv]);
  is($loader->{csv}, $csv, 'csv option');
  is($loader->{csv}->{goo}, 'ber', 'csv option');

  # csv_class
  $loader = new_ok($mod, [io => new_io(), csv_class => $csv_class]);
  isa_ok($loader->{csv}, $csv_class);
  $loader = new_ok($mod, [io => new_io(), csv_class => 'Fake_CSV']);
  isa_ok($loader->{csv}, 'Fake_CSV');

  # csv_opts, csv_defaults
  $loader = new_ok($mod, [io => new_io(), csv_class => 'Fake_CSV']);
  is($loader->{csv}->{binary}, 1, 'csv_defaults');
  $loader = new_ok($mod, [io => new_io(), csv_class => 'Fake_CSV', csv_opts => {binary => 12}]);
  is($loader->{csv}->{binary}, 12, 'csv_defaults overridden with csv_opts');
  $loader = new_ok($mod, [io => new_io(), csv_class => 'Fake_CSV', csv_defaults => {}]);
  ok(!exists($loader->{csv}->{binary}), 'csv_defaults emptied');

  # file (no io)
  is(eval { $mod->new(file => '') }, undef, 'die w/o file');
  like($@, qr/Cannot proceed without/, 'no file error');
  is(eval { $mod->new(file => catfile('t', 'file that does', 'not.exist')) }, undef, 'die w/o file');
  like($@, qr/Failed to open/, 'cannot find file');

  $loader = eval { $mod->new(file => catfile(qw( t data example.csv ))) };
  is($@, '', 'no error');
  isa_ok($loader, $mod, 'file exists');

  # no_header
  $loader = new_ok($mod, [io => new_io()]);
  is_deeply($loader->column_names, [qw(fld1 fld2)], 'csv 1st row column names');
  is_deeply($loader->get_raw_row, [qw(row1 col2)],  'csv 2nd row is 1st row of data');

  $loader = new_ok($mod, [io => new_io(), columns => [qw(goo ber)]]);
  is_deeply($loader->column_names, [qw(goo ber)],   'provided column names');
  is_deeply($loader->get_raw_row, [qw(row1 col2)],  'csv 2nd row is 1st row of data');

  $loader = new_ok($mod, [io => new_io(), columns => [qw(goo ber)], no_header => 1]);
  is_deeply($loader->column_names, [qw(goo ber)],   'provided column names');
  is_deeply($loader->get_raw_row, [qw(fld1 fld2)],  'no_header option returns 1st row of csv in 2st row of data');
};

done_testing;

sub new_io {
  # use fake io to avoid opening files
  my $data = ["fld1,fld2\n", "row1,col2\n", "row2,col2\n", qq[row3,"col 2"\n]];
  return Test::MockObject->new(
    # Text::CSV_PP calls eof() which requires a Glob reference
    Symbol::gensym()
  )->mock(getline => sub { shift @$data });
}
