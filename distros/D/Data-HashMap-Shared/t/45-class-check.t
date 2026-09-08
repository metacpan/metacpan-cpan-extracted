use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::I16;
use Data::HashMap::Shared::I32;
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::I16S;
use Data::HashMap::Shared::I32S;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SI16;
use Data::HashMap::Shared::SI32;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::SS;

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, "$_[0].shm") }

my @variants = qw(I16 I32 II I16S I32S IS SI16 SI32 SI SS);
my %map = map { $_ => "Data::HashMap::Shared::$_"->new(path($_), 100) } @variants;
$map{$_}->put($_ =~ /^S/ ? 'k' : 1, $_ =~ /S$/ ? 'v' : 1) for @variants;

# Every XSUB checks that its invocant is its own class.  Called with another
# variant's object it must croak, not reinterpret that map's nodes.
for my $callee (@variants) {
    my $k = $callee =~ /^S/ ? 'k' : 1;
    my $v = $callee =~ /S$/ ? 'v' : 1;
    for my $owner (@variants) {
        next if $owner eq $callee;
        my $obj = $map{$owner};
        for my $call (["put",  sub { $_[0]->($obj, $k, $v) }],
                      ["get",  sub { $_[0]->($obj, $k) }],
                      ["size", sub { $_[0]->($obj) }]) {
            my ($name, $run) = @$call;
            my $code = do { no strict 'refs'; \&{"Data::HashMap::Shared::${callee}::$name"} };
            my $err = eval { $run->($code); 1 } ? '' : $@;
            like $err, qr/^Expected a Data::HashMap::Shared::\Q$callee\E object/,
                "${callee}::$name on a $owner map croaks";
        }
    }
    my $cur_owner = $variants[0] eq $callee ? $variants[1] : $variants[0];
    my $cursor = $map{$cur_owner}->cursor;
    my $next = do { no strict 'refs'; \&{"Data::HashMap::Shared::${callee}::Cursor::next"} };
    my $err = eval { $next->($cursor); 1 } ? '' : $@;
    like $err, qr/^Expected a Data::HashMap::Shared::\Q$callee\E::Cursor object/,
        "${callee}::Cursor::next on a $cur_owner cursor croaks";
}

# keyword form: same XSUB, same check
{
    my $err = eval { shm_ss_put $map{II}, 'k', 'v'; 1 } ? '' : $@;
    like $err, qr/^Expected a Data::HashMap::Shared::SS object/, 'shm_ss_put on an II map croaks';
    is $map{II}->get(1), 1, 'the II map is untouched';
    $err = eval { my $x = shm_ii_get $map{SS}, 1; 1 } ? '' : $@;
    like $err, qr/^Expected a Data::HashMap::Shared::II object/, 'shm_ii_get on an SS map croaks';
}
for my $v (@variants) {
    is $map{$v}->size, 1, "$v map still holds exactly its own entry";
}

# The other half of the guard: an invocant that is not an object at all.  A
# class-method typo reaches the same macro, and without sv_isobject it
# dereferences the class name as a handle.
for my $v (@variants) {
    my $class = "Data::HashMap::Shared::$v";
    my $err = eval { $class->size; 1 } ? '' : $@;
    like $err, qr/^Expected a \Q$class\E object/, "$v: a class-method call croaks";
    my $cerr = eval { "${class}::Cursor"->next; 1 } ? '' : $@;
    like $cerr, qr/^Expected a \Q$class\E::Cursor object/, "$v: a cursor class-method call croaks";
}

done_testing;
