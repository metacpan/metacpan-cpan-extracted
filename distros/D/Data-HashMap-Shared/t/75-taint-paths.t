use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Under taint mode a call that opens a file for writing, creates or removes one
# must not be given tainted data -- a path, a size, a file mode, a descriptor,
# or a handle opened from tainted input -- as core open and sysopen do, while a
# file may be read by a tainted name.  A child runs under -T or -t with its inputs
# taken from the environment, which taint mode marks tainted.

open my $probe, '-|', $^X, '-T', '-e', 'print ${^TAINT}' or die $!;
my $taint_on = <$probe> // '';
close $probe;
plan skip_all => 'perl cannot run under -T here' unless $taint_on eq '1';

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/child.pl" or die $!;
print $fh <<'PERL';
use strict; use warnings;
use Data::HashMap::Shared::II;
open STDERR, '>&', \*STDOUT or die;
$| = 1;
my $warned = 0;
$SIG{__WARN__} = sub { $warned++ if $_[0] =~ /^Insecure dependency in Data::HashMap::Shared::II->new /; warn @_ };
my $C = 'Data::HashMap::Shared::II';
my $dir = $ENV{MAP_DIR};
my ($clean) = $dir =~ /\A(.*)\z/s;
sub try { my ($name, $code) = @_; print eval { $code->(); 1 } ? "$name=ok\n" : "$name=died: $@" }
sub exists_ { print "$_[0]=", (-e "$clean/$_[1]" ? 1 : 0), "\n" }
try(new         => sub { $C->new("$dir/a.shm", 64) });
exists_(created => 'a.shm');
print "warned=$warned\n";
try(size        => sub { $C->new("$clean/z.shm", $ENV{MAP_ENTRIES}) });
exists_(size_created => 'z.shm');
try(mode        => sub { $C->new("$clean/m.shm", 64, 0, 0, 0, 0, oct $ENV{MAP_MODE}) });
exists_(mode_created => 'm.shm');
try(modifier    => sub { $C->new("$clean/q.shm", 64) if $ENV{MAP_DIR} });
exists_(modifier_created => 'q.shm');
try(new_sharded => sub { $C->new_sharded("$dir/s", 2, 64) });
exists_(shards => 's.0');
try(anon        => sub { $C->new(undef, $ENV{MAP_ENTRIES})->put(1, 1) or die "no put\n" });
try(memfd       => sub { $C->new_memfd($ENV{MAP_DIR}, 64)->put(1, 1) or die "no put\n" });
my $mm = eval { $C->new_memfd('x', 64) } or print "memfd_setup=died: $@";
try(from_fd     => sub { my $fd = $mm->memfd . substr($dir, 0, 0); $C->new_from_fd($fd) });
try(clean_from_fd => sub { $C->new_from_fd($mm->memfd) });
for my $f (qw(b.shm c.shm d.shm)) { my $m = $C->new("$clean/$f", 64); $m->put(1, 7); $m->freeze }
try(undef_handle => sub {
    my $ro = $C->new_readonly("$dir/d.shm");
    local $SIG{__WARN__} = sub { undef $ro };
    $ro->unlink;
});
exists_(undef_kept => 'd.shm');
try(unlink      => sub { $C->unlink("$dir/b.shm") });
exists_(kept => 'b.shm');
try(readonly    => sub { $C->new_readonly("$dir/b.shm")->get(1) == 7 or die "wrong value\n" });
try(obj_unlink  => sub { my $ro = $C->new_readonly("$dir/b.shm"); $ro->unlink });
exists_(obj_kept => 'b.shm');
try(clean_obj_unlink => sub { $C->new_readonly("$clean/b.shm")->unlink or die "not removed\n" });
try(clean_unlink => sub { $C->unlink("$clean/c.shm") or die "not removed\n" });
my $rewrote = 0;
try(rewrite     => sub {
    my $p = "$dir/h.shm";
    substr($p, 0, 1, substr($p, 0, 1));   # own the buffer, so the rewrite is in place
    local $SIG{__WARN__} = sub { substr($p, -5, 1, 'X'); $rewrote++ };
    $C->new($p, 64);
});
print "rewrote=$rewrote\n";
exists_(rewrite_named => 'h.shm');
exists_(rewrite_moved => 'X.shm');
PERL
close $fh;

my @inc = map { "-I$_" } grep { !ref } @INC;
sub child {
    my ($switch, $sub) = @_;
    mkdir "$dir/$sub" or die $!;
    local $ENV{MAP_DIR}     = "$dir/$sub";
    local $ENV{MAP_MODE}    = '0666';
    local $ENV{MAP_ENTRIES} = '64';
    open my $out, '-|', $^X, $switch, @inc, "$dir/child.pl" or die $!;
    my %r = map { chomp; split /=/, $_, 2 } grep { /^\w+=/ } <$out>;
    close $out;
    return \%r;
}
sub insecure { qr/^died: Insecure dependency in Data::HashMap::Shared::II->\Q$_[0]\E while running with -T switch/ }

my $t = child('-T', 'T');
like $t->{new}, insecure('new'), 'under -T, new refuses a tainted path';
is $t->{created}, 0, '  ... before creating the file';
like $t->{size}, insecure('new'), 'under -T, new refuses a tainted size';
is $t->{size_created}, 0, '  ... before creating the file';
like $t->{mode}, insecure('new'), 'under -T, new refuses a tainted file mode, as sysopen does';
is $t->{mode_created}, 0, '  ... before creating the file';
like $t->{modifier}, insecure('new'), 'under -T, tainted data anywhere in the statement is refused, as for open';
is $t->{modifier_created}, 0, '  ... before creating the file';
like $t->{new_sharded}, insecure('new_sharded'), 'under -T, new_sharded refuses a tainted prefix';
is $t->{shards}, 0, '  ... before creating a shard';
is $t->{anon}, 'ok', 'an anonymous map, naming no file, takes a tainted size';
is $t->{memfd}, 'ok', 'a memfd map takes a tainted name';
like $t->{from_fd}, insecure('new_from_fd'), 'under -T, new_from_fd refuses a tainted descriptor';
is $t->{clean_from_fd}, 'ok', '  ... and takes an untainted one';
like $t->{unlink}, insecure('unlink'), 'under -T, unlink refuses a tainted path';
is $t->{kept}, 1, '  ... and removes nothing';
is $t->{readonly}, 'ok', 'new_readonly reads a frozen map by a tainted path, as open does';
like $t->{obj_unlink}, insecure('unlink'), '  ... but that handle cannot unlink it';
is $t->{obj_kept}, 1, '  ... so the file stays';
is $t->{clean_obj_unlink}, 'ok', 'a handle opened by an untainted path still unlinks under -T';
is $t->{clean_unlink}, 'ok', 'an untainted path still unlinks under -T';

my $w = child('-t', 'w');
for my $r ([$t, 'T'], [$w, 'w']) {
    diag "new_memfd unavailable ($r->[1]): $r->[0]{memfd_setup}" if defined $r->[0]{memfd_setup};
}
is $w->{new}, 'ok', 'under -t, new with a tainted path goes ahead';
is $w->{warned}, 1, '  ... with the taint warning';
is $w->{created}, 1, '  ... and creates the file';
is_deeply [@$w{qw(rewrote rewrite_named rewrite_moved)}], [1, 1, 0],
    '  ... under the name it was given, though the warning handler rewrote the variable';
is $w->{from_fd}, 'ok', 'under -t, new_from_fd with a tainted descriptor goes ahead';
is $w->{unlink}, 'ok', 'under -t, unlink with a tainted path goes ahead';
like $w->{undef_handle}, qr/^died: .*object was replaced during the call/,
    'a warning handler that drops the handle mid-unlink gets an error, not freed memory';
is $w->{undef_kept}, 1, '  ... and the file stays';

done_testing;
