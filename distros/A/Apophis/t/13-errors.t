use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Apophis;

my $dir   = tempdir(CLEANUP => 1);
my $other = tempdir(CLEANUP => 1);
my $ca    = Apophis->new(namespace => 'test-errors', store_dir => $dir);
my $text  = 'some content';
my $id    = $ca->store(\$text);

for my $method (qw(namespace identify identify_file path_for store fetch exists remove verify store_many find_missing meta
                   op_identify op_store op_exists op_fetch op_verify op_remove)) {
    my @arg = $method eq 'namespace' ? () : $method =~ /identify$|store$/ ? \$text : $method =~ /many|missing/ ? [] : $id;
    ok(!eval { Apophis->can($method)->('Apophis', @arg); 1 }, "$method on the class name is refused");
    like($@, qr/^Apophis::$method: not an object/, 'with the method named');
}

for my $hollow (bless({}, 'Apophis'), bless({ _ns_bytes => undef, _ns_str => undef }, 'Apophis')) {
    ok(!eval { $hollow->identify(\$text); 1 }, 'an object without namespace bytes cannot identify');
    like($@, qr/object has no namespace \(not properly constructed\)/, 'and says it was not built by new');
    ok(!eval { $hollow->namespace; 1 }, 'nor name its namespace');
    like($@, qr/^Apophis: object has no namespace/, 'with the same complaint');
}

my $dirless = Apophis->new(namespace => 'test-errors');
ok(!eval { $dirless->exists($id); 1 }, 'a store without a directory cannot look anything up');
like($@, qr/^Apophis: no store_dir specified/, 'and names the missing option');
ok(!eval { $dirless->exists($id, store_dir => undef); 1 }, 'an undefined store_dir option is no option');
like($@, qr/^Apophis: no store_dir specified/, 'and is reported as missing');
my $undef_dir = Apophis->new(namespace => 'test-errors');
$undef_dir->{store_dir} = undef;
ok(!eval { $undef_dir->exists($id); 1 }, 'as is an undefined store_dir in the object');
like($@, qr/^Apophis: no store_dir specified/, 'with the same complaint');
is($dirless->path_for($id, store_dir => $other), join('/', $other, substr($id, 0, 2), substr($id, 2, 2), $id), 'but a store_dir passed to the call stands in');
ok(!$dirless->exists($id, store_dir => $other), 'and is used for the lookup');
is(($dirless->find_missing([$id], store_dir => $other))[0], $id, 'and for the bulk lookup');
is($dirless->store(\$text, store_dir => $other), $id, 'and for a store');
ok($dirless->exists($id, store_dir => $other), 'which then exists there');
is(${ $dirless->fetch($id, store_dir => $other) }, $text, 'and reads back');
ok($dirless->verify($id, store_dir => $other), 'and verifies');
ok(!defined $dirless->meta($id, store_dir => $other), 'with no metadata');
is_deeply([$dirless->store_many([\$text], store_dir => $other)], [$id], 'store_many takes the directory too');
ok($dirless->remove($id, store_dir => $other), 'and remove');

ok(!eval { Apophis->new('namespace'); 1 }, 'new with an odd argument list is refused');
like($@, qr/^Apophis->new: odd number of arguments/, 'and says so');
ok(!eval { Apophis->new(store_dir => $dir); 1 }, 'new without a namespace is refused');
like($@, qr/^Apophis->new: 'namespace' is required/, 'and says which option');
is(Apophis->new(namespace => 'n', unknown => 1)->namespace, Apophis->new(namespace => 'n')->namespace, 'an option new does not know is passed over');

for my $method (qw(path_for store fetch exists remove verify store_many find_missing meta)) {
    my $arg = $method eq 'store' ? \$text : $method =~ /many|missing/ ? [] : $id;
    ok(!eval { $ca->$method($arg, 'store_dir'); 1 }, "$method with an odd option list is refused");
    like($@, qr/^Apophis::$method: odd number of optional arguments/, 'and says so');
}

ok(!eval { $ca->path_for('abc'); 1 }, 'a path for an id too short to shard is refused');
like($@, qr/^Apophis: invalid UUID id/, 'and the id is called invalid');

my $long = Apophis->new(namespace => 'test-errors', store_dir => $dir . '/' . ('x' x 4100));
ok(!eval { $long->store(\$text); 1 }, 'a store directory that cannot fit the path is refused before anything is written');
like($@, qr/^Apophis: path too long/, 'and says the path is too long');
ok(!-e "$dir/" . ('x' x 20), 'and nothing of it was created');

for my $method (qw(store op_store identify op_identify)) {
    ok(!eval { $ca->$method('plain string'); 1 }, "$method wants a reference");
    like($@, qr/^Apophis::$method: argument must be a scalar reference/, 'and says so');
}

ok(!eval { $ca->identify_file(File::Spec->catfile($dir, 'no-such-file')); 1 }, 'identifying a file that is not there fails');
like($@, qr/^Apophis::identify_file: cannot open '.*no-such-file': /, 'naming the file');

for my $meta ('not a hash', [], \$text) {
    is($ca->store(\$text, meta => $meta), $id, 'a meta option that is not a hash reference is passed over');
    ok(!defined $ca->meta($id), 'and writes no sidecar');
}

my @sparse;
$#sparse = 1;
$sparse[1] = \$text;
for my $refs ({}, 'plain string', \$text) {
    ok(!eval { $ca->store_many($refs); 1 }, 'store_many wants an array reference');
    like($@, qr/^Apophis::store_many: first argument must be an array ref/, 'and says so');
}
ok(!eval { $ca->store_many([\$text, 'not a ref']); 1 }, 'and every element a scalar reference');
like($@, qr/^Apophis::store_many: element 1 must be a scalar ref/, 'naming the element');
ok(!eval { $ca->store_many(\@sparse); 1 }, 'a hole in the array is no scalar reference either');
like($@, qr/^Apophis::store_many: element 0 must be a scalar ref/, 'and is named');
is_deeply([$ca->store_many([\$text, \$text])], [$id, $id], 'the same content twice is stored once and listed twice');
for my $ids ({}, 'plain string', \$text) {
    ok(!eval { $ca->find_missing($ids); 1 }, 'find_missing wants an array reference');
    like($@, qr/^Apophis::find_missing: first argument must be an array ref/, 'and says so');
}
my $absent = '00000000-0000-5000-8000-000000000000';
is_deeply([$ca->find_missing([undef, $id, $absent])], [$absent], 'an undefined id is passed over, a stored one found, a missing one listed');
my @holes;
$#holes = 1;
$holes[1] = $absent;
is_deeply([$ca->find_missing(\@holes)], [$absent], 'a hole in the array is passed over like an undefined id');

done_testing;
