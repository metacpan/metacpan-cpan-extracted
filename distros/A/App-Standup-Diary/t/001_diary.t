use Test2::V0;
use App::Standup::Diary;

my $d = App::Standup::Diary->new( data_dir => 'foo', project_name => 'bar' );
isa_ok $d, 'Object::Pad::UNIVERSAL';
isa_ok $d, 'App::Standup::Diary';

my @attributes = qw/
  config
  daily_data_path
  data_dir
  date
  project_name
  template
/;

my @methods    = qw/
  init_daily_data_path
  write
  build_full_file_path
  build_path
  should_create_dir
  create_directories_tree
/;

can_ok $d, $_ for @attributes;
can_ok $d, $_ for @methods;

# ok $d->DOES('Diary::Role::Date');
# ok $d->DOES('Diary::Role::Project');

is $d->data_dir, 'foo', 'We have a correct project directory for data';
is $d->project_name, 'bar', 'We have a correct project name';

isa_ok $d->date, 'Time::Piece';

is $d->daily_data_path, undef, '$daily_data_path is not initialised yet';
# Without it, daily_data_path wouldn't be initiallised properly
$d->write;

ok -e $d->daily_data_path, 'The file have been created on disk';

use Time::Piece;
my $today = localtime;

my ($year_month) = $today->ymd('/') =~ m/ \d{4} \/ \d{2} /gx;

is $d->daily_data_path, $d->data_dir . '/' . $year_month, 'Daily data path match today\'s date';

# Revert data_dir foo and all data after tests

done_testing();
