use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::PerfectHash::Shared;

{
    package Local::ArrayRef;
    sub TIESCALAR { bless [$_[1]], $_[0] }
    sub FETCH { $_[0][0] }
}
{
    package Local::Path;
    use overload '""' => sub { $_[0][0] }, fallback => 1;
}

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/input.phs";
for my $type (qw(int str)) {
    my @keys = $type eq 'int' ? (1, 2, 3) : ('', 'a', "b\0c");
    tie my $keys, 'Local::ArrayRef', \@keys;
    my $method = "build_$type";
    ok(Data::PerfectHash::Shared->$method($path, $keys), "$type: tied arrayref builds");
    my $set = Data::PerfectHash::Shared->load($path);
    is $set->count, 3, "$type: tied arrayref count";
    ok $set->has($_), "$type: tied arrayref member" for @keys;
}

Data::PerfectHash::Shared->build_int($path, [7]);
my $builder = Data::PerfectHash::Shared->new_builder;
$builder->add(11);
for my $call (
    sub { Data::PerfectHash::Shared->build_int("$path\0suffix", [11]) },
    sub { Data::PerfectHash::Shared->build_str("$path\0suffix", ['x']) },
    sub { $builder->build("$path\0suffix") },
    sub { Data::PerfectHash::Shared->load("$path\0suffix") },
) {
    my $ok = eval { $call->(); 1 };
    ok !$ok, 'NUL path is rejected';
    like $@, qr/path contains NUL/, 'NUL path error';
    my $set = Data::PerfectHash::Shared->load($path);
    ok $set->has(7), 'NUL path leaves the prefix file intact';
    ok !$set->has(11), 'NUL path does not publish a replacement';
}

for my $name ("snow-\x{96ea}", "byte-\xe9") {
    my $p = "$dir/$name.phs";
    SKIP: {
    if (!utf8::is_utf8($p)) {
        open my $probe, '>', $p
            or skip 'filesystem rejects non-UTF-8 filenames', 8;
        close $probe or die $!;
    }
    for my $arg ($p, bless([$p], 'Local::Path')) {
        Data::PerfectHash::Shared->build_int($arg, [9]);
        my $set = Data::PerfectHash::Shared->load($arg);
        is $set->path, $p, 'filename bytes and characters round-trip';
        is !!utf8::is_utf8($set->path), !!utf8::is_utf8($p), 'filename UTF8 flag is preserved';
        ok $set->has(9), 'non-ASCII filename loads';
        $set->unlink;
        ok !-e $p, 'non-ASCII filename unlinks';
    }
    }
}

done_testing;
