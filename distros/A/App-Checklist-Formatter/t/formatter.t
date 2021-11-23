use Test::More;
BEGIN { plan tests => 2 };
use App::Checklist::Formatter;
ok(1);

my $clf = App::Checklist::Formatter->new();

is($clf->read_vim_outliner('t/checklist.otl'),3, 'read 3 top items');
