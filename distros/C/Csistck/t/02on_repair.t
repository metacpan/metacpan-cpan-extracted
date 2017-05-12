use Test::More;
use Test::Exception;
use Csistck;

plan tests => 4;

my $t;

$t = script('dummy', [], on_repair => sub { });
ok((ref $t->on_repair eq 'CODE'), 'Script on_repair');
$t = file('dummy', on_repair => sub { });
ok((ref $t->on_repair eq 'CODE'), 'File on_repair');
$t = template('dummy', on_repair => sub { });
ok((ref $t->on_repair eq 'CODE'), 'Template on_repair');
$t = pkg('dummy', 'dpkg', on_repair => sub { });
ok((ref $t->on_repair eq 'CODE'), 'Pkg on_repair');

1;
