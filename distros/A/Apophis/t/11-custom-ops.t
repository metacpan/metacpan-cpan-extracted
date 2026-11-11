use strict;
use warnings;
use Test::More;
use B::Concise ();
use B::Deparse ();
use File::Temp qw(tempdir);
use Apophis;

# Under `use Apophis` a call to one of the six methods compiles to a custom
# op instead of an entersub. The op still looks the method up, and only takes
# the call when the method is this module's own XSUB, so everything a method
# call promises, a subclass's override, a wrapped sub, options, still holds.

plan skip_all => 'a perl before 5.14 cannot describe a custom op to B, so there the calls stay calls' if $] < 5.014;

sub xop { my ($name) = @_; qr/\bapophis_\Q$name\E\b/ }

sub ops_of {
    my ($code) = @_;
    my $out = '';
    B::Concise::walk_output(\$out);
    B::Concise::compile('-exec', $code)->();
    return $out;
}

my $dir     = tempdir(CLEANUP => 1);
my $ca      = Apophis->new(namespace => 'test-ops', store_dir => $dir);
my $text    = 'custom op test content';
my $other   = 'another piece of content';
my $missing = '00000000-0000-5000-8000-000000000000';

my %op = (
    identify    => sub { $ca->identify($_[0]) },
    store       => sub { $ca->store($_[0]) },
    exists      => sub { $ca->exists($_[0]) },
    fetch       => sub { $ca->fetch($_[0]) },
    verify      => sub { $ca->verify($_[0]) },
    remove      => sub { $ca->remove($_[0]) },
    op_identify => sub { $ca->op_identify($_[0]) },
    op_store    => sub { $ca->op_store($_[0]) },
    op_exists   => sub { $ca->op_exists($_[0]) },
    op_fetch    => sub { $ca->op_fetch($_[0]) },
    op_verify   => sub { $ca->op_verify($_[0]) },
    op_remove   => sub { $ca->op_remove($_[0]) },
);

# ------------------------------------------------------------ the optree

for my $name (sort keys %op) {
    (my $base = $name) =~ s/^op_//;
    like(ops_of($op{$name}), xop($base), "a call to $name compiles to the $base op");
    unlike(ops_of($op{$name}), qr/\bentersub\b/, '...and is no longer an entersub');
}

my %plain = (
    'a call with options'            => sub { $ca->store($_[0], meta => { k => 'v' }) },
    'a call through a code ref'      => sub { &{ $ca->can('store') }($ca, $_[0]) },
    'a call by a method name in a variable' => sub { my $m = 'store'; $ca->$m($_[0]) },
    'a function call'                => sub { Apophis::store($ca, $_[0]) },
    'a method that has no op'        => sub { $ca->path_for($_[0]) },
    'a call under no Apophis'        => sub { no Apophis; $ca->store($_[0]) },
);
for my $what (sort keys %plain) {
    like(ops_of($plain{$what}), qr/\bentersub\b/, "$what stays an entersub");
    unlike(ops_of($plain{$what}), qr/\bapophis_\w+\b/, '...with no op');
}

my $after = do { no Apophis; eval q{ sub { $ca->exists($_[0]) } } or die $@ };
like(ops_of($after), qr/\bentersub\b/, 'a scope compiled under no Apophis has no ops');
my $again = do { no Apophis; eval q{ use Apophis; sub { $ca->exists($_[0]) } } or die $@ };
like(ops_of($again), xop('exists'), 'and use Apophis inside it turns them on again');
my $false = eval q{ BEGIN { $^H{'Apophis/ops'} = 0 } sub { $ca->exists($_[0]) } } or die $@;
like(ops_of($false), qr/\bentersub\b/, 'a false value in the hint turns them off as no Apophis does');

like(B::Deparse->new->coderef2text($op{identify}), qr/->identify\(/, 'B::Deparse shows the op as the method call it was');

# ----------------------------------------------- the op and the XSUB agree

my $id = $op{store}->(\$text);
like($id, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/, 'store through the op gives a UUID v5');
is($id, $ca->${\'identify'}(\$text), 'and it is the id the XSUB computes');
is($op{identify}->(\$text), $id, 'identify through the op agrees');
is($op{op_identify}->(\$text), $id, 'as does the op_ alias');
is(${ $op{fetch}->($id) }, $text, 'fetch through the op reads the blob back');
is($op{fetch}->($missing), undef, 'and gives undef for a blob that is not there');
ok($op{exists}->($id), 'exists through the op sees it');
ok(!$op{exists}->($missing), 'and not what is missing');
ok($op{verify}->($id), 'verify through the op passes the blob');
ok(!$op{verify}->($missing), 'and fails what is missing');
is($op{store}->(\$text), $id, 'storing the same content again gives the same id');
ok($op{remove}->($id), 'remove through the op removes it');
ok(!$op{remove}->($id), 'and reports nothing to remove the second time');
ok(!$op{exists}->($id), 'after which it is gone');

for my $name (qw(op_store op_exists op_fetch op_verify)) {
    (my $base = $name) =~ s/^op_//;
    my $arg = $base eq 'store' ? \$other : $ca->identify(\$other);
    is_deeply([ $op{$name}->($arg) ], [ $ca->$base($arg) ], "$name gives what $base gives");
}
ok($op{op_remove}->($ca->identify(\$other)), 'op_remove removes what op_store stored');
ok(!$ca->exists($ca->identify(\$other)), '...and it is gone');

# --------------------------------------------------- the op steps aside

{
    package My::Store;
    our @ISA = ('Apophis');
    sub store { 'overridden' }
}
{
    package My::Plain;
    our @ISA = ('Apophis');
}
my $mine  = My::Store->new(namespace => 'test-ops', store_dir => $dir);
my $plain = My::Plain->new(namespace => 'test-ops', store_dir => $dir);
my $sub_store    = sub { $_[0]->store($_[1]) };
my $sub_identify = sub { $_[0]->identify($_[1]) };
like(ops_of($sub_store), xop('store'), 'a call on an unknown invocant compiles to the op');
is($sub_store->($mine, \$text), 'overridden', 'and runs the override a subclass gives the method');
is($sub_store->($plain, \$text), $id, 'while a subclass that inherits the method gets the op');
is($sub_identify->($mine, \$text), $id, 'and a method the subclass left alone runs through the op');
ok($plain->remove($id), 'tidy');

{
    no warnings 'redefine';
    local *Apophis::exists = sub { 'wrapped' };
    is($op{exists}->($id), 'wrapped', 'a sub installed over the method is what runs');
}
ok(!$op{exists}->($id), 'and the op is back once it is gone');

my $dirless = Apophis->new(namespace => 'test-ops');
my $spread  = sub { $dirless->exists(@_) };
like(ops_of($spread), xop('exists'), 'a call whose argument is a list compiles to the op');
ok(!eval { $spread->($id); 1 }, 'with one argument the op runs the body');
like($@, qr/^Apophis: no store_dir specified/, '...which wants a store directory');
ok(!$spread->($id, store_dir => $dir), 'with options the call goes to the XSUB, which honours them');
ok(!eval { $spread->($id, 'store_dir'); 1 }, 'and an odd option list is refused there');
like($@, qr/^Apophis::exists: odd number of optional arguments/, 'with the XSUB complaining');

# -------------------------------------------------------------- context

$id = $op{store}->(\$text);
my @one = $op{fetch}->($id);
is(scalar @one, 1, 'in list context the op gives one value');
is(${ $one[0] }, $text, '...the blob');
my @none = $op{fetch}->($missing);
is_deeply(\@none, [undef], 'and one undef for a missing blob');
my @ids = map { $ca->identify(\$_) } ($text, $other);
is_deeply(\@ids, [ $ca->identify(\$text), $ca->identify(\$other) ], 'two results from one op in a map are two values');
my ($a1, $a2) = ($op{identify}->(\$text), $op{identify}->(\$other));
isnt($a1, $a2, 'and two calls to one op in a list are two values');
is(do { $ca->remove($id); 'void' }, 'void', 'in void context the op leaves nothing behind');
ok(!$ca->exists($id), 'and still did its work');

# --------------------------------------------------------------- croaks

ok(!eval { Apophis->identify(\$text); 1 }, 'the class name is not an object to the op');
like($@, qr/^Apophis::identify: not an object/, 'and the croak names the method');
ok(!eval { $ca->op_identify('plain'); 1 }, 'the alias wants a reference');
like($@, qr/^Apophis::op_identify: argument must be a scalar reference/, 'and the croak names the alias');
ok(!eval { $ca->store(\$text, 'odd'); 1 }, 'an odd option list falls back to the XSUB');
like($@, qr/^Apophis::store: odd number of optional arguments/, 'which refuses it');
is($op{identify}->(\$text), $ca->${\'identify'}(\$text), 'and after a croak the op still works');

done_testing;
