use strict;
use warnings;
use Test::More;
use Config;
use Data::IntervalTree::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Every constructor declares the invocant as `const char *class`, so xsubpp
# captures its PV in the INPUT section, before the CODE block (and before the
# default-argument conversions that follow PREINIT).  Resolving a later
# argument (mode / capacity / fd) can run arbitrary Perl via overload or tie
# magic, and that Perl can reallocate the buffer the captured class PV points
# into; MAKE_OBJ then passes the stale (freed) pointer to gv_stashpv.
#
# Probe: the class is a plain scalar holding the name of a real subclass, and
# the overloaded mode/capacity/fd argument holds a hard reference to that
# scalar and writes a LONGER package name through it.  The write forces
# sv_grow to reallocate the scalar's PV buffer, so the pointer captured at
# INPUT time is left pointing at the freed buffer with the pre-magic content.
# (An overloaded class cannot demonstrate this: the '""' result is copied on
# sub return, so later magic can never reach the captured buffer.  A tied
# class does not either: the FETCH cache is a COW share whose refcount is
# held by the FETCH temp until end of statement, so the buffer is never
# freed mid-call.)
#
# With the fix the constructor re-reads ST(0) at the point of use and blesses
# into the post-magic package; without it the object is blessed into the
# pre-magic package (or, under an ASan build, gv_stashpv's strlen of the
# freed buffer is caught as a heap-use-after-free).

{
    package ITSClassA;
    our @ISA = ('Data::IntervalTree::Shared');
}
{
    package ITS::Class::ButLonger;
    our @ISA = ('Data::IntervalTree::Shared');
}
{
    package EvilNum;
    our $RET = 0600;
    our $REF;   # reference to the class scalar, set by the caller
    use overload '0+' => sub { $$REF = 'ITS::Class::ButLonger'; $RET }, fallback => 1;
}

for my $ctor (qw(new new_memfd new_from_fd)) {
    my $pid = fork();
    unless ($pid) {
        # built at runtime, not a literal: after the statement ends the
        # scalar is the sole owner of its (COW) buffer, so the longer write
        # through the reference below really frees/reallocates it
        my $class = join '', 'ITS', 'ClassA';
        $EvilNum::REF = \$class;
        my $evil = bless [], 'EvilNum';
        my $real = Data::IntervalTree::Shared->new_memfd(undef, 16);
        my $obj  = eval {
            if    ($ctor eq 'new')       { $EvilNum::RET = 0600; $class->new(undef, 16, $evil) }
            elsif ($ctor eq 'new_memfd') { $EvilNum::RET = 16;   $class->new_memfd(undef, $evil) }
            else                         { $EvilNum::RET = $real->memfd; $class->new_from_fd($evil) }
        };
        if (!$obj) {
            print STDERR "CTOR-CROAK: $@";
            exit 3;
        }
        my $ref = ref $obj;
        if ($ref ne 'ITS::Class::ButLonger') {
            print STDERR "STALE-CLASS: $ctor blessed into pre-magic package [$ref]\n";
            exit 2;
        }
        exit 0;
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$ctor: no crash when argument magic reallocates the class PV"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$ctor: blesses into the post-magic class name";
}

done_testing;
