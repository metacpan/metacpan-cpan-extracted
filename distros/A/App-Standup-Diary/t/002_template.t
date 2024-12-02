use Test2::V0;
use App::Standup::Diary;
use Path::Tiny qw(path);
use v5.28.0;

my $d = App::Standup::Diary->new( data_dir => 'foo', project_name => 'baz' );
$d->write;

# Load and parse the markdown
my $d_path = path( $d->build_full_file_path );

my @lines = $d_path->lines({ chomp => 1 });

is $lines[0], join ' ', '#', $d->project_name, $d->date->ymd;
is $lines[1], "";
is $lines[5], "- done";
is $lines[6], "- todo";
is $lines[7], "- blocking";

done_testing();
