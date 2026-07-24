#!/usr/bin/perl
# Regression: the constructors must not hand gv_stashpv() a class-name pointer
# captured before later argument magic ran.
#
# The invocant of new/new_memfd/new_from_fd is declared as a typemap
# `const char *class`, so xsubpp captures its PV in the INPUT section, before
# the UV/int conversion of a later typed argument or the SvGETMAGICs in CODE.
# That magic is arbitrary Perl and can realloc or free the class PV, leaving
# the pointer handed to gv_stashpv() dangling.
#
# The test invokes each constructor with a plain class-name scalar as the
# invocant and a tied scalar as a later argument. The tied FETCH payload:
#   (a) grows the class scalar so its old PV buffer is freed (a blocker
#       allocation right after it prevents in-place realloc extension),
#   (b) floods the allocator with same-size strings naming a DIFFERENT
#       package, so the freed chunk is recycled with that content, and
#   (c) restores the class scalar's current value.
# With the fix the constructor re-reads ST(0) after all magic and blesses into
# the restored (correct) class. Without it gv_stashpv() reads the recycled
# buffer and the object comes out blessed into Data::CuckooFilter::Hijack --
# the specific symptom this test asserts against (a mere croak would not
# prove the stale read).
use strict;
use warnings;
use Test::More;
use Fcntl qw(O_RDWR);
use File::Temp qw(tempdir);
use Data::CuckooFilter::Shared;

my $REAL  = 'Data::CuckooFilter::Shared';
my $FORGE = 'Data::CuckooFilter::Hijack';
die 'test invariant: names must be equal length'
    unless length($REAL) == length($FORGE);

{ package ScrambleTie;
  sub TIESCALAR { my ($pkg, $ret, $payload) = @_; bless [$ret, $payload], $pkg }
  sub FETCH     { my $s = shift; $s->[1]->(); return $s->[0] }
  sub STORE     { $_[0][0] = $_[1] } }

our @FLOOD;   # keep the recycled chunks alive past the constructor call
my $scrambles = 0;
sub scramble_class_pv {
    my $ref = shift;
    $scrambles++;
    # Grow the class scalar: the old buffer cannot extend in place past the
    # blocker, so realloc moves it and frees the chunk the constructor
    # (unfixed) still points at.
    $$ref = 'X' x 4096;
    # Recycle the freed chunk: same byte length as $REAL, so the same malloc
    # size class; sprintf builds a fresh non-COW PV for each element.
    @FLOOD = map { sprintf '%s%s', 'Data::CuckooFilter::', 'Hijack' } 1 .. 300;
    # Restore the invocant's current value: a correct re-read sees $REAL.
    $$ref = $REAL;
    return;
}

# A fresh class scalar with a PRIVATE (non-COW, runtime-built) buffer, plus a
# blocker allocation right after it. A literal would be COW-shared with the
# constant and would never dangle.
sub fresh_setup {
    my $class   = sprintf '%s', $REAL;
    my $blocker = 'B' x 64;
    return (\$class, \$blocker);
}

# Control: without magic, every constructor blesses into $REAL.
{
    my $obj = $REAL->new(undef, 1000);
    is(ref $obj, $REAL, 'control: new blesses into the real class');
    my $m = $REAL->new_memfd('ctl', 1000);
    is(ref $m, $REAL, 'control: new_memfd blesses into the real class');
}

# new(): magic runs on the file-mode argument ST(3) inside CODE.
{
    my ($cref, $bref) = fresh_setup();
    tie my $mode, 'ScrambleTie', 0600, sub { scramble_class_pv($cref) };
    my $obj = $$cref->new(undef, 1000, $mode);
    is(ref $obj, $REAL,
       'new: class PV re-read after mode magic (broken code blesses into '
       . "$FORGE)");
}

# new_memfd(): magic runs on the name argument ST(1) inside CODE.
{
    my ($cref, $bref) = fresh_setup();
    tie my $name, 'ScrambleTie', 'lbl', sub { scramble_class_pv($cref) };
    my $obj = $$cref->new_memfd($name, 1000);
    is(ref $obj, $REAL,
       'new_memfd: class PV re-read after name magic (broken code blesses into '
       . "$FORGE)");
}

# new_from_fd(): magic runs on the fd argument, converted by SvIV in the
# INPUT section after the class PV was captured.
{
    my $dir  = tempdir(CLEANUP => 1);
    my $seed = $REAL->new("$dir/f.cuckoo", 1000);
    undef $seed;
    sysopen(my $fh, "$dir/f.cuckoo", O_RDWR) or die "sysopen: $!";
    my ($cref, $bref) = fresh_setup();
    tie my $fd, 'ScrambleTie', fileno($fh), sub { scramble_class_pv($cref) };
    my $obj = $$cref->new_from_fd($fd);
    is(ref $obj, $REAL,
       'new_from_fd: class PV re-read after fd magic (broken code blesses into '
       . "$FORGE)");
}

# Vacuity guard: the tied payloads must actually have run.
cmp_ok($scrambles, '>=', 3, 'magic payloads executed');

done_testing();
